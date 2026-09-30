#!/usr/bin/env python3
"""
Harvest REAL recipe HTML from Common Crawl — at scale, without ever hitting the origin site
(so Cloudflare 403s don't apply). Feeds the same corpus dir the accuracy harness scores.

Pipeline per URL/pattern:
  1. Query the CC index → {filename, offset, length} for the archived capture(s).
  2. Range-fetch that WARC record from data.commoncrawl.org (CC's CDN — public, no 403).
  3. Split WARC → HTTP → HTML body.
  4. Self-label from the page's own JSON-LD Recipe; write <id>.html / <id>.nojsonld.html / <id>.truth.json.

SCALE: for millions, don't loop the HTTP index API (it 504s on big wildcards). Instead query the
columnar index (Parquet on S3) with Athena/DuckDB to get filename/offset/length for every recipe
capture, then run step 2–4 in parallel. That path does millions; this script is the reference
per-record implementation + a modest driver for CI. Run it where CC is reachable and time isn't capped.

Usage:
  python3 harvest_commoncrawl.py urls.txt /tmp/rf_import_corpus            # exact URLs (light on the index)
  python3 harvest_commoncrawl.py --pattern "www.allrecipes.com/recipe/*" --limit 500 /tmp/rf_import_corpus
"""
import sys, os, re, json, gzip, io, time, hashlib, urllib.request, urllib.parse, urllib.error

INDEX = "https://index.commoncrawl.org"
DATA = "https://data.commoncrawl.org"
JSONLD_RE = re.compile(r'<script[^>]*type=["\']application/ld\+json["\'][^>]*>(.*?)</script>',
                       re.IGNORECASE | re.DOTALL)

def latest_crawl():
    with urllib.request.urlopen(INDEX + "/collinfo.json", timeout=30) as r:
        return json.load(r)[0]["id"]

def index_query(crawl, url, limit, retries=4):
    q = urllib.parse.urlencode({"url": url, "output": "json", "limit": limit})
    for attempt in range(retries):
        try:
            req = urllib.request.Request(f"{INDEX}/{crawl}-index?{q}", headers={"User-Agent": "RecipeFinder-corpus/1.0"})
            with urllib.request.urlopen(req, timeout=60) as r:
                body = r.read().decode("utf-8", "replace")
            if body.lstrip().startswith("<"):  # gateway error page
                raise urllib.error.HTTPError(req.full_url, 504, "gateway", {}, None)
            return [json.loads(l) for l in body.splitlines() if l.strip() and not l.startswith("{\"message")]
        except Exception as e:
            wait = 2 ** attempt
            print(f"  index retry {attempt+1}/{retries} in {wait}s ({type(e).__name__})")
            time.sleep(wait)
    return []

def fetch_record(rec):
    off, length = int(rec["offset"]), int(rec["length"])
    req = urllib.request.Request(f"{DATA}/{rec['filename']}",
                                 headers={"Range": f"bytes={off}-{off+length-1}", "User-Agent": "RecipeFinder-corpus/1.0"})
    with urllib.request.urlopen(req, timeout=90) as r:
        gz = r.read()
    raw = gzip.GzipFile(fileobj=io.BytesIO(gz)).read().decode("utf-8", "replace")
    # WARC headers \r\n\r\n HTTP headers \r\n\r\n body
    parts = raw.split("\r\n\r\n", 2)
    return parts[2] if len(parts) == 3 else ""

# --- ground-truth from JSON-LD (shared shape with fetch_and_label.py) ---
def find_recipe(node):
    if isinstance(node, dict):
        t = node.get("@type", ""); types = t if isinstance(t, list) else [t]
        if any(str(x).lower() == "recipe" for x in types): return node
        for v in node.values():
            r = find_recipe(v)
            if r: return r
    elif isinstance(node, list):
        for v in node:
            r = find_recipe(v)
            if r: return r
    return None

def norm_instructions(ri, out=None):
    out = [] if out is None else out
    if isinstance(ri, str):
        s = ri.strip()
        if s: out.append(s)
    elif isinstance(ri, dict):
        if ri.get("@type") == "HowToSection": norm_instructions(ri.get("itemListElement", []), out)
        else:
            t = ri.get("text") or ri.get("name")
            if isinstance(t, str) and t.strip(): out.append(t.strip())
    elif isinstance(ri, list):
        for i in ri: norm_instructions(i, out)
    return out

def truth_from_html(html, url):
    for block in JSONLD_RE.findall(html):
        try:
            data = json.loads(block.strip())
        except Exception:
            try: data = json.loads("[" + block.strip() + "]")
            except Exception: continue
        rec = find_recipe(data)
        if not rec: continue
        ingredients = [s.strip() for s in (rec.get("recipeIngredient") or rec.get("ingredients") or [])
                       if isinstance(s, str) and s.strip()]
        name = rec.get("name"); name = name[0] if isinstance(name, list) and name else name
        if not name or not ingredients: continue
        instr = norm_instructions(rec.get("recipeInstructions", []))
        return {"url": url, "name": name.strip() if isinstance(name, str) else "",
                "ingredients": ingredients, "ingredientCount": len(ingredients),
                "instructionCount": len(instr), "hasInstructions": len(instr) > 0}
    return None

def save(out_dir, url, html):
    truth = truth_from_html(html, url)
    if not truth: return "no-label"
    rid = hashlib.sha1(url.encode()).hexdigest()[:12]
    open(os.path.join(out_dir, rid + ".html"), "w").write(html)
    open(os.path.join(out_dir, rid + ".nojsonld.html"), "w").write(JSONLD_RE.sub("", html))
    json.dump(truth, open(os.path.join(out_dir, rid + ".truth.json"), "w"))
    return "ok"

def main():
    args = [a for a in sys.argv[1:]]
    pattern = None; limit = 1000
    if "--pattern" in args:
        i = args.index("--pattern"); pattern = args[i+1]; del args[i:i+2]
    if "--limit" in args:
        i = args.index("--limit"); limit = int(args[i+1]); del args[i:i+2]
    out_dir = args[-1]; os.makedirs(out_dir, exist_ok=True)
    crawl = latest_crawl(); print(f"crawl: {crawl}")

    records = []
    if pattern:
        records = index_query(crawl, pattern, limit)
    else:
        for url in [l.strip() for l in open(args[0]) if l.strip() and not l.startswith("#")]:
            records += index_query(crawl, url, 1)

    print(f"index captures: {len(records)}")
    ok = nolabel = err = 0
    for rec in records[:limit]:
        try:
            html = fetch_record(rec)
        except Exception as e:
            err += 1; print(f"  fetch err {type(e).__name__} {rec.get('url')}"); continue
        r = save(out_dir, rec.get("url", ""), html)
        if r == "ok": ok += 1
        else: nolabel += 1
        time.sleep(0.1)
    print(f"\nlabelled OK: {ok}   no-JSON-LD: {nolabel}   errors: {err}   -> {out_dir}")

if __name__ == "__main__":
    main()
