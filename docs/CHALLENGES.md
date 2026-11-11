# Challenges — the weekly devil's advocate

Written by the **weekly challenger** scheduled task (owner OK 2026-11-11). Its job is to argue *against* how this
project works, not to review code line by line: CLAUDE.md rules, BACKLOG priorities and guardrails, WORK.md
Decisions, architecture, CI, test quality ("would this test fail if the feature broke?"), UX assumptions and
anything that looks outdated. Every week it asks, of what changed and of the wider app:
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

Format, newest week first:

```
## Week of YYYY-MM-DD
- ⚔️ [Break|Attack|Simplify|Delete|Tests|…] <what we assume> — <why it may be wrong, with evidence> — <alternative> — cost if we're wrong: <…>
  → Owner: Accept / Reject (<why>) / Later
```

<!-- challenger appends below this line -->
