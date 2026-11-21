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
| Agent routines (builder, challenger, reviewer, digest) | Claude scheduled tasks | No — prompts summarised in BACKLOG.md |

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
