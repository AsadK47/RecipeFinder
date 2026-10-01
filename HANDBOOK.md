# RecipeFinder Handbook

Start here. This is an index, not a book — nothing lives on this page. Each doc
keeps its own lifecycle (stable rules, slow-moving roadmap, throwaway plans) so it
stays fresh. Follow the links.

RecipeFinder is a privacy-first, offline-first iOS recipe manager
(SwiftUI · iOS 17.5+ · Swift 6), owned by RecipeFinder Limited.

---

## How the app works
- [ROADMAP.md#feature-map](ROADMAP.md) — **the feature map**: every capability the app ships + how well-tested it is, at a glance. Start here to know what the app does without reading source.
- [readme.md](readme.md) — public overview: features, screenshots, tech stack, build/run instructions.
- [CLAUDE.md](CLAUDE.md) — landing page for the AI agent harness: architecture overview, verification commands, session state. Module conventions live next to their code (`RecipeFinder/CLAUDE.md`, `RecipeFinderTests/CLAUDE.md`).

## How we work
- [WORK.md](WORK.md) — the live "are we there yet" tracker: current pre-launch punch list, each item checked against the ROADMAP north star. Start here to see where we are vs. where we're going.
- [AGENT_LESSONS.md](AGENT_LESSONS.md) — hard-won lessons for AI-assisted sessions (verify premises, proportionate fixes, test cadence). The `improve-loop` workflow encodes the audit→verify step.
- [CORE_LOOP_AUDIT.md](CORE_LOOP_AUDIT.md) — ranked audit of the import→find→cook→track loop; live fix tracker.

## Where we're going
- [ROADMAP.md](ROADMAP.md) — product direction and priorities. Part I: Hardening (done), Part II: Improvements, Part III: New Features. Strategy: *"ReciMe, but private, unlimited, and better at the actual cooking."*

## Legal & licensing
- [LICENSE](LICENSE) — proprietary licence.
- Privacy Policy & Terms: the canonical copies are the in-app views
  (`RecipeFinder/Views/Settings/Legal/PrivacyPolicyView.swift`,
  `TermsOfServiceView.swift`) and the website (recipefinder.uk/privacy.html, /terms.html).
  ⚠️ Pre-launch: the in-app text still says "no accounts / no data collected" — stale vs.
  Apple/email sign-in + planned iCloud sync; needs a lawyer-reviewed rewrite.

---

### Conventions for these docs
- **`readme.md` / `CLAUDE.md` / `ROADMAP.md`** are long-lived — edit in place, don't append dated changelog entries (history lives in git).
- **`WORK.md`** is the live scratch tracker for the current push — tick items as they land, clear it when the work ships. One at a time (WIP=1), not a pile of stale plans.
- New durable doc? Add a one-line pointer here so this stays the single front door.
