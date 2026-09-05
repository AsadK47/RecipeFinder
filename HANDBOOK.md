# RecipeFinder Handbook

Start here. This is an index, not a book — nothing lives on this page. Each doc
keeps its own lifecycle (stable rules, slow-moving roadmap, throwaway plans) so it
stays fresh. Follow the links.

RecipeFinder is a privacy-first, offline-first iOS recipe manager
(SwiftUI · iOS 17.5+ · Swift 6), owned by RecipeFinder Limited.

---

## How the app works
- [readme.md](readme.md) — public overview: features, screenshots, tech stack, build/run instructions.
- [CLAUDE.md](CLAUDE.md) — the working contract: Clean Architecture layers, Swift/SwiftUI conventions, performance hot-path rules, dependency injection, and the Swift Testing (TDD) workflow.

## Where we're going
- [ROADMAP.md](ROADMAP.md) — product direction and priorities. Phases 1–3 are release-defining (Capture / Sync & Trust / Cooking). Strategy: *"ReciMe, but private, unlimited, and better at the actual cooking."* Also holds the Completed log.

## Active work *(consumable — delete a plan when it lands)*
- [PLAN-import-kitchen.md](PLAN-import-kitchen.md) — import-first tab bar + Kitchen/Shopping ("Groceries") merge. Phase A done; follow-ups: cohesion pass, paste-text→AI, tab-label decision.
- [PLAN-bug-audit.md](PLAN-bug-audit.md) — prioritised correctness-defect catalogue. Recurring root cause: substring matching where whole-word is meant. Open P2s: charset decode, normalizer determinism, unit-conversion & category-classifier word boundaries.

## Legal & licensing
- [LICENSE](LICENSE) — proprietary licence.
- [legal/PRIVACY_POLICY.md](legal/PRIVACY_POLICY.md) · [legal/TERMS_OF_SERVICE.md](legal/TERMS_OF_SERVICE.md)

---

### Conventions for these docs
- **`readme.md` / `CLAUDE.md` / `ROADMAP.md`** are long-lived — edit in place, don't append dated changelog entries (history lives in git).
- **`PLAN-*.md`** are scratch plans for one push — tick items as they land, delete the file when the work ships, add a new one for the next push.
- New durable doc? Add a one-line pointer here so this stays the single front door.
