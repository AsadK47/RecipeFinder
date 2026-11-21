# Operations & security checklist

What keeps RecipeFinder's accounts, builds and domain safe, and who looks after each part. Public repo: no secrets, key
IDs or personal account details here.

## Where things live
| Thing | Where | Defined in code? |
|---|---|---|
| App data | On the phone + the cook's own iCloud (CloudKit private database) | Core Data model in repo; CloudKit schema deployed by hand (Xcode → CloudKit Console) |
| Builds & tests | GitHub Actions (`.github/workflows/`) | Yes |
| TestFlight uploads | `testflight.yml` with the App Store Connect API key + signing cert in GitHub secrets | Yes (secrets: GitHub only) |
| Website | GitHub Pages (RecipeFinderWebsite) behind Cloudflare | Yes |
| Domain `recipefinder.uk` | Cloudflare Registrar — transfer lock on, DNSSEC signed, paid to 2031 | No |
| Bundle ID & capabilities (iCloud) | Apple Developer portal | No — read-only check: `testflight-capabilities-check.yml` |
| Agent routines (builder, challenger, reviewer, digest) | Claude scheduled tasks | No — see Agent routines below |

## Agent routines (Claude scheduled tasks, times UK)
| Routine | When | Does | Writes to |
|---|---|---|---|
| Builder | every 2 h at :35 | Takes the next BACKLOG item, builds it on `agent/<slug>`, lands it when CI is green | code + BACKLOG Log |
| Daily reviewer | 21:10 | Two+ independent reviews of what landed since the last review | BACKLOG Inbox + Log |
| Daily challenger | 05:40 | Devil's-advocate pass (strategy, security/MASVS, simplify/delete) | docs/CHALLENGES.md, Inbox |
| Weekly CEO digest | Mon 07:50 | Shipped, health, decisions for the owner | docs/digest/ |
| TestFlight feedback | hourly (GitHub Actions) | Files tester feedback as issues labelled `testflight-feedback` | GitHub issues |
All push a short notification to the owner. Their full prompts live in the owner's Claude scheduled tasks, not here.

## If something breaks
- **CI red on `main`:** nothing new reaches TestFlight until it's green; the builder fixes `main` before new work.
- **TestFlight upload fails:** read the `TestFlight` run log; usual causes are an expired cert/API key (see checklist) or
  a build number clash (re-run the workflow).
- **Signing cert or API key expired:** owner creates a new one in Apple Developer / App Store Connect and replaces the
  GitHub secrets (`CI_DEV_CERT_P12` + password, `ASC_KEY_ID`/`ASC_ISSUER_ID`/`ASC_KEY_P8`).
- **New synced Core Data fields:** owner runs the app from Xcode with sync on, then CloudKit Console → Deploy Schema
  Changes to Production, before that build goes to testers.
- **A routine stops reporting:** check its last run in Claude's scheduled tasks; a refused push means the session lacks
  repo write access.

## Owner checklist (only the owner can do these)
- [ ] Two-factor sign-in (passkeys where offered): GitHub, Apple ID (developer account), both Gmail accounts, Cloudflare.
- [ ] App Store Connect API key used by CI has the **App Manager** role (not Admin). Rotate yearly — next: Nov 2027.
- [ ] Mac: FileVault on; the SSH key that signs commits has a passphrase.
- [x] GitHub → repo Settings → Advanced Security: secret scanning + push protection, private vulnerability reporting,
  Dependabot alerts (2026-11-21).
- [x] Domain transfer lock + DNSSEC (Cloudflare, checked 2026-11-21).
- [ ] Sept 2027: renew the CI signing certificate (expires 2027-11-10) and update the GitHub secrets.
- [ ] Before Mar 2027: CI builds with Xcode 27 / iOS 27 SDK (Apple ITMS-90725; agents — see BACKLOG).

## Agents look after
- Locked Swift package versions, CI actions pinned to commit SHAs, least-privilege workflow permissions, Dependabot
  updates, `SECURITY.md` (BACKLOG: *Supply-chain + CI hardening*).
- Daily reviewer and challenger (OWASP MASVS) findings → BACKLOG Inbox, fixed before features.
- Privacy text kept in step with what the app stores and syncs (in-app policy + recipefinder.uk/privacy.html).

## Review
Once a year (each November) re-run this checklist and update the dates.
