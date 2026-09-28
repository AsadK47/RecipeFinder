#!/usr/bin/env python3
"""
Fetch recipe pages and auto-label them for the import-accuracy harness.

For each URL (stdin or urls.txt) it writes into the corpus dir:
  <id>.html           raw page
  <id>.nojsonld.html  same page with all <script type=ld+json> removed (exercises our microdata/WPRM/text fallbacks)
  <id>.truth.json     ground truth extracted from the page's OWN JSON-LD Recipe block

Ground truth is self-labelling: the site's JSON-LD Recipe is treated as correct.
Pages without a JSON-LD Recipe are skipped (no ground truth) and reported as coverage gaps.

Scale: point it at a urls.txt of any size. Big runs belong in CI / a residential IP —
many large sites 403 non-browser fetches, so coverage from a datacenter/sandbox is partial.

Usage:  python3 fetch_and_label.py urls.txt /tmp/rf_import_corpus
"""
import sys, os, re, json, urllib.request, urllib.error, hashlib, time

UA = ("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 "
      "(KHTML, like Gecko) Version/17.0 Safari/605.1.15")
JSONLD_RE = re.compile(r'<script[^>]*type=["\']application/ld\+json["\'][^>]*>(.*?)</script>',
                       re.IGNORECASE | re.DOTALL)

def fetch(url):
    req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept-Language": "en"})
    with urllib.request.urlopen(req, timeout=25) as r:
        raw = r.read()
    return raw.decode("utf-8", errors="replace")

def find_recipe(node):
    """Depth-first search for a JSON-LD object whose @type includes Recipe."""
    if isinstance(node, dict):
        t = node.get("@type", "")
        types = t if isinstance(t, list) else [t]
        if any(str(x).lower() == "recipe" for x in types):
            return node
        for v in node.values():
            r = find_recipe(v)
            if r:
                return r
    elif isinstance(node, list):
        for v in node:
            r = find_recipe(v)
            if r:
                return r
    return None

def norm_instructions(ri):
    out = []
    def walk(x):
        if isinstance(x, str):
            s = x.strip()
            if s:
                out.append(s)
        elif isinstance(x, dict):
            if x.get("@type") == "HowToSection":
                walk(x.get("itemListElement", []))
            else:
                t = x.get("text") or x.get("name")
                if isinstance(t, str) and t.strip():
                    out.append(t.strip())
        elif isinstance(x, list):
            for i in x:
                walk(i)
    walk(ri)
    return out

def truth_from_html(html, url):
    for block in JSONLD_RE.findall(html):
        block = block.strip()
        try:
            data = json.loads(block)
        except Exception:
            # some sites concatenate objects; try a lenient array wrap
            try:
                data = json.loads("[" + block + "]")
            except Exception:
                continue
        rec = find_recipe(data)
        if not rec:
            continue
        ingredients = [s.strip() for s in (rec.get("recipeIngredient") or rec.get("ingredients") or [])
                       if isinstance(s, str) and s.strip()]
        instructions = norm_instructions(rec.get("recipeInstructions", []))
        name = rec.get("name")
        if isinstance(name, list):
            name = name[0] if name else None
        if not name or not ingredients:
            continue  # not a usable Recipe label
        return {
            "url": url,
            "name": name.strip() if isinstance(name, str) else "",
            "ingredients": ingredients,
            "ingredientCount": len(ingredients),
            "instructions": instructions,
            "instructionCount": len(instructions),
            "hasInstructions": len(instructions) > 0,
            "prepTime": rec.get("prepTime"),
            "cookTime": rec.get("cookTime"),
            "totalTime": rec.get("totalTime"),
        }
    return None

def main():
    urls_file = sys.argv[1] if len(sys.argv) > 1 else "urls.txt"
    out_dir = sys.argv[2] if len(sys.argv) > 2 else "/tmp/rf_import_corpus"
    os.makedirs(out_dir, exist_ok=True)
    urls = [u.strip() for u in open(urls_file) if u.strip() and not u.startswith("#")]

    ok = blocked = nolabel = 0
    for url in urls:
        rid = hashlib.sha1(url.encode()).hexdigest()[:12]
        try:
            html = fetch(url)
        except urllib.error.HTTPError as e:
            print(f"  HTTP {e.code:<4} (blocked?)  {url}")
            blocked += 1
            continue
        except Exception as e:
            print(f"  ERR  {type(e).__name__}  {url}")
            blocked += 1
            continue
        truth = truth_from_html(html, url)
        if not truth:
            print(f"  NO-LABEL (no JSON-LD Recipe)  {url}")
            nolabel += 1
            continue
        open(os.path.join(out_dir, rid + ".html"), "w").write(html)
        open(os.path.join(out_dir, rid + ".nojsonld.html"), "w").write(JSONLD_RE.sub("", html))
        json.dump(truth, open(os.path.join(out_dir, rid + ".truth.json"), "w"))
        print(f"  OK   {truth['ingredientCount']:>2} ing, {truth['instructionCount']:>2} steps  {truth['name'][:48]}")
        ok += 1
        time.sleep(0.3)

    total = len(urls)
    print(f"\nCorpus: {out_dir}")
    print(f"labelled OK: {ok}/{total}   blocked/err: {blocked}   fetched-but-no-JSON-LD: {nolabel}")

if __name__ == "__main__":
    main()
