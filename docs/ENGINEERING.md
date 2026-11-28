# Engineering practices — index

A map, not a rulebook: each row names a practice, **where its rule lives** (the only place it's written), the outside
evidence for it, and what checks it. Edit the rule in its home, never here. Status: **Enforced** = a test, CI step or
hook fails when it's broken · **Queued** = BACKLOG Queue › Kaizen (letter) · **Prose** = written only. Kaizen moves
rows to Enforced; when a check lands, its home's prose shrinks to a pointer (CLAUDE.md hard constraints stay —
changing them asks the owner). Built 2026-11-28 from web research and the project's record, two reviewers.

| Practice | Rule's home | Evidence | Check · status |
|---|---|---|---|
| One fact, one home; copies that must exist get a parity test | CLAUDE.md Harness decay · this file | [Docs as code](https://www.writethedocs.org/guide/docs-as-code/), [contract tests](https://martinfowler.com/bliki/ContractTest.html); BACKLOG Inbox "dup sweep 2026-11-28" (copies already disagreeing) | legal app↔website parity · Queued (e) |
| Logic lives once | RecipeFinder/CLAUDE.md DRY · BACKLOG Smells | same sweep: plurals, fractions, ingredient text copied 3–7× with different output | Smells items · Prose |
| Check the premise both ways; know why a fence is there before removing it | AGENT_LESSONS 1 · BACKLOG step 6d | [Chesterton's fence](https://www.chesterton.org/taking-a-fence-down/) | Prose |
| Fix-without-asking needs evidence (deductive or inductive) | CLAUDE.md hard constraints | — | Log line names the proof · Prose |
| A finding is acted on when two reviewers agree or it's verified in code; reviewers read-only, correctness not style; count scales with risk | BACKLOG step 6c · docs/PRODUCT.md | [Google review standard](https://google.github.io/eng-practices/review/reviewer/standard.html), [Claude Code best practices](https://code.claude.com/docs/en/best-practices) | Prose |
| A bug fix's test is seen failing on the old code; later cases are *unconfirmed (added with fix)* | RecipeFinderTests/CLAUDE.md | — | Log needs `seen red: Build & Test <id>` · Queued (f) |
| Heuristic changes are diffed over the real corpus | AGENT_LESSONS 41 | — | corpus snapshot · Queued (b) |
| Tests aren't weakened quietly | AGENT_LESSONS 42 | [METR: reward hacking](https://metr.org/blog/2025-06-05-recent-reward-hacking/) | deleted/disabled test gate · Queued (g) |
| Look at screens built from this commit | BACKLOG step 6b | — | Prose |
| Small batches; main only moves to a CI-green SHA | CLAUDE.md branch policy | [DORA small batches](https://dora.dev/capabilities/working-in-small-batches/), [CD](https://dora.dev/capabilities/continuous-delivery/) | Prose (no branch protection) |
| WIP = 1; one worktree per lane; confirm a lane acted on a message | CLAUDE.md WIP=1 · AGENT_LESSONS 36 | — | Prose |
| Parallel lanes land via `agent/batch`; rerun skipped only for `.md`-only drift | BACKLOG step 7 | — | Prose |
| Refactor and behaviour change are separate commits | BACKLOG Smells rule | "Make the change easy, then make the easy change" (Kent Beck) | Prose |
| Repeated fixes in one area mean the spec is wrong | AGENT_LESSONS 43 | — | churn alarm · Queued (c) |
| Every lesson ends in a check | CLAUDE.md Harness decay | [Toyota kaizen / jidoka](https://global.toyota/en/company/vision-and-philosophy/production-system/) | docs lint · Queued (f) |
| Hard constraints are gates: model version, history tracking key | CLAUDE.md hard constraints | poka-yoke | `CoreDataMigrationTests.currentModelContainsAllRecipeKeys`, `CloudSyncStoreTests.historyAndRemoteChangesAreAlwaysTracked` · Enforced |
| New Swift files compile in the right target (an unregistered test file never runs) | CLAUDE.md Build & CI | — | pbxproj gate · Queued (a) |
| Known Swift 6 / Swift Testing traps, Combine | RecipeFinder/CLAUDE.md · RecipeFinderTests/CLAUDE.md | — | trap grep · Queued (a); Combine hook warns in sessions only |
| Data contracts: backup round trip, old-store migration, recovery never leaves an empty library | SHIP_BAR 🔴2 | [Hyrum's law](https://www.hyrumslaw.com/) | data-contract tests · Queued (d) |
| Tests don't depend on clock, weekday or order | AGENT_LESSONS 15, 27, 32 | — | trap grep (narrow) · Queued (a) |
| Always-read files are a map, not a manual | CLAUDE.md budgets | [OpenAI harness engineering](https://openai.com/index/harness-engineering/), [Claude Code memory](https://code.claude.com/docs/en/memory) (< ~200 lines) | CLAUDE.md budgets · Queued (f); BACKLOG ~1,170 lines and WORK.md ~170 are over — Parking lot |
| Decisions keep context and rejected options; superseded, not deleted | CLAUDE.md Session handoff · docs/DECISIONS.md | [ADRs](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions) | Prose |
| Challenges get a verdict | BACKLOG Weekly challenge triage | — | open `→ Owner:` count · Queued (f) |

Considered and not adopted now (solo dev, launch 14 Dec): weekly [DORA metrics](https://dora.dev/guides/dora-metrics/)
(no decision depends on them), mutation testing ([Google 2021](https://arxiv.org/abs/2103.07189); macOS minutes per
mutant — the challenge pass asks "would the tests notice?"), a lane worktree script (the built-in worktree tool covers it).
