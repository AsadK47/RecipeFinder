# RecipeFinder Handbook

Start here. This is an index, not a book — each doc keeps its own lifecycle, so follow the links.

RecipeFinder is a privacy-first, offline-first iOS recipe manager
(SwiftUI · iOS 17.5+ · Swift 6), owned by Asad Khan.

---

## What we're building
- [docs/PRODUCT.md](docs/PRODUCT.md) — **the north star**: the cooking loop, each tab's job, roadmap phases, parked ideas. Read before shaping any feature.
- [BACKLOG.md](BACKLOG.md) — the work queue in roadmap order, how an agent works it, guardrails, Needs owner, and the Log of what landed.
- [README.md](README.md) — public overview: features, screenshots, build/run instructions.

## How the app works
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — layers and DI seams, Core Data model and migrations, iCloud sync, import pipeline, share extension, Today feed, bundled art, CI/TestFlight.
- [RecipeFinder/DesignSystem.md](RecipeFinder/DesignSystem.md) — tokens, components and visual rules.
- [CLAUDE.md](CLAUDE.md) — hard constraints and the agent harness; module rules live next to their code (`RecipeFinder/CLAUDE.md`, `RecipeFinderTests/CLAUDE.md`).

## How we work
- [WORK.md](WORK.md) — live handoff between sessions: in progress, next action, decisions.
- [tools/README.md](tools/README.md) — what each helper script does and what it needs.
- [docs/DESIGN-RESEARCH.md](docs/DESIGN-RESEARCH.md) — research-backed rules for what makes a good app (speed, motion, choice, habits).
- [docs/OPERATIONS.md](docs/OPERATIONS.md) — where builds, data, domain and keys live, and the owner's security checklist.
- [docs/DECISIONS.md](docs/DECISIONS.md) — why things are the way they are: options rejected and tradeoffs, per landed item, newest first.
- [docs/CHALLENGES.md](docs/CHALLENGES.md) — the challenge-pass playbook and what each pass found.
- [AGENT_LESSONS.md](AGENT_LESSONS.md) — lessons from AI-assisted sessions (verify premises, proportionate fixes, test cadence).
- [CHANGELOG.md](CHANGELOG.md) — what changed for you, one entry per change that ships in a TestFlight build; feeds the website's "Behind the build" page.
- [docs/LOG.md](docs/LOG.md) — the team's Log lines older than 7 days.
- [SHIP_BAR.md](SHIP_BAR.md) — the bar a change clears before it ships.

## History
- [docs/archive/](docs/archive/) — retired docs kept for history: the old ROADMAP and past audits (CORE_LOOP_AUDIT, AUDIT-2026-11-10).
- [docs/PLAY.md](docs/PLAY.md) — Play series spec, parked (see `docs/PRODUCT.md` → Parked).

## Legal & licensing
- [LICENSE](LICENSE) — AGPL-3.0 (name, icon and bundled recipe text excluded; see README).
- Privacy Policy & Terms: the in-app views are canonical
  (`RecipeFinder/Views/Settings/Legal/PrivacyPolicyView.swift`, `TermsOfServiceView.swift`); the website
  (recipefinder.uk/privacy.html, /terms.html) mirrors them. Any change to what is stored, synced or sent
  updates both in the same item (BACKLOG guardrails).

---

### Conventions for these docs
- `README.md`, `CLAUDE.md`, `docs/PRODUCT.md` and `docs/ARCHITECTURE.md` are long-lived — edit in place; history lives in git.
- `WORK.md` is the handoff for the current push — keep it short; when an item ships its Decisions entry moves to `docs/DECISIONS.md`.
- Docs touched by a change are updated in the same commit.
- New durable doc? Add a one-line pointer here so this stays the single front door.
