# Challenges — the devil's advocate

Written by the **daily challenger** scheduled task (owner 2026-11-11: "challenge aggressively and frequently"),
which assumes every change and rule is wrong until the evidence says otherwise, and by the per-item challenge pass
(BACKLOG step 6d). Its job is to argue *against* how this
project works, not to review code line by line: CLAUDE.md rules, BACKLOG priorities and guardrails, WORK.md
Decisions, architecture, CI, test quality ("would this test fail if the feature broke?"), UX assumptions and
anything that looks outdated. Every run it asks, of what changed and of the wider app:
- **Break it** — what if I did this? (hostile/odd input, offline, killed mid-save, huge data, accessibility extremes)
- **Attack it** — does this guard against injection? (web pages, pasted/OCR text, shared files and zips, deep links,
  WKWebView, prompt injection into the on-device model)
- **Simplify it** — what is the simplest version? Are we making it too complex? Why can't it be simpler?
- **Delete it** — what happens if we simply remove this entirely? Who would notice?
- **Tests** — would this test fail if the feature broke?

Each challenge must carry evidence (file:line, a run, a screenshot, a measured number,
or a current Apple/Swift doc) — opinion alone isn't a challenge.

The owner answers each one: **Accept** (it becomes a BACKLOG item or a rule change), **Reject** (with one line why —
the challenger must not raise it again unless the evidence changes) or **Later**.

Format, newest first:

```
## YYYY-MM-DD
- ⚔️ [Break|Attack|Simplify|Delete|Tests|…] <what we assume> — <why it may be wrong, with evidence> — <alternative> — cost if we're wrong: <…>
  → Owner: Accept / Reject (<why>) / Later
```

## Playbook — established methods, not ad-hoc questions

Pick the methods that fit what's being challenged; every run covers at least **1, 2, one of 3–5, 6 and 7**.

1. **Key Assumptions Check** (CIA *Tradecraft Primer*; Red Team Handbook). List the assumptions the change or rule
   rests on; rate each *solid / caveated / unsupported*; challenge the unsupported ones with evidence.
2. **Premortem** (Gary Klein; Red Team Handbook). "It's three months later and this failed for a real cook — why?"
   Write the top causes and whether any test, screenshot or check would have caught them.
3. **Threat model — Shostack's four questions** (What are we working on? What can go wrong? What are we going to do
   about it? Did we do a good job?) with **STRIDE** at each trust boundary: Spoofing, Tampering, Repudiation,
   Information disclosure, Denial of service, Elevation of privilege. Boundaries here: web pages/JSON-LD, pasted and
   OCR text, shared files and zips, deep links, share extension + App Group, WKWebView, backups, on-device model.
4. **OWASP MASVS v2.1** (with the MASTG test guide) — the mobile app checklist, by category: STORAGE, CRYPTO, AUTH,
   NETWORK, PLATFORM, CODE, RESILIENCE, PRIVACY. Ask which controls a change touches and whether they still hold.
5. **OWASP Top 10 for LLM Applications** (2026 edition; prompt injection is #1) for anything using the on-device
   model. Assume instructions can be bypassed: model output is untrusted data, never an action; check what a
   hostile recipe page or caption could make it produce.
6. **Break it — Heuristic Test Strategy Model, SFDIPOT** (James Bach): vary **S**tructure, **F**unction, **D**ata
   (empty, huge, odd units, emoji/RTL, duplicates), **I**nterfaces (share sheet, files, clipboard, deep links),
   **P**latform (iOS versions, Apple Intelligence on/off, low storage), **O**perations (how cooks really use it —
   offline, interrupted, VoiceOver, largest text) and **T**ime (timezones, midnight, killed mid-save, two at once).
7. **Simplify it / Delete it** — YAGNI and KISS, checked against **Chesterton's fence**: before recommending removal,
   say why the thing exists (git log/blame); then ask what problem it solves, for whom, how often, what the smallest
   design is, and what is lost if it's deleted outright.
8. **Would the tests notice?** — a mutation-testing mindset: name a one-line bug in the code under test and say
   whether any test would fail. If none would, that's a finding.

<!-- challenger appends below this line -->
