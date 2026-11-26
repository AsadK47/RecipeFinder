# tools/

Helper scripts that sit outside the app. Run from the repo root. None ship in the app; CI skips this folder
(`paths-ignore`), except `RecipeArt`, which `tools-build.yml` compiles; `script-tests.yml` runs every `test_*.py` and
`website-behind-the-build.py --check` (Python 3.12+).

| Tool | What it does | Needs |
|---|---|---|
| `RecipeArt/run.sh` | Draws a picture per bundled recipe with Apple Image Playground into `RecipeArt/Output/<id>.jpg`. Prompts: `descriptions.json`; bad pictures: list ids in `rejected.txt` | A Mac with Apple Intelligence (macOS 15.4+) |
| `bundle-recipe-art.py` | Shrinks `RecipeArt/Output` into the app's `RecipeFinder/RecipeSeed/RecipeArt/` (960px JPEG), skipping rejected ids | Python 3 + Pillow |
| `seed-history.py` | Rebuilds `recipes_seed_history.json` from git history so edited built-in recipes update on installs | Python 3, full git history |
| `audit-missing-amounts.py` | Lists built-in recipes with missing amounts or times (exit 1 if any; `--list` for all) | Python 3 |
| `import-corpus/` | Fetches and labels sample recipe pages to test the importer | Python 3, network |
| `recipe-review/` | Briefs for agent reviews of the built-in recipe set | — |
| `seed-images/` | Older image fetcher for built-in recipes (superseded by RecipeArt) | Python 3, network |
| `website-recipes.py` | Writes the website's "Recipe of the day" list (no method text) | Python 3 |
| `website-whats-new.py` | Fills the website's What's new page from the BACKLOG Log + `whats-new-copy.json` | Python 3 |
| `website-behind-the-build.py` | Fills the website's Behind the build page from `CHANGELOG.md` (`test_website_behind_the_build.py` tests it) | Python 3 |

`RecipeArt/Output/` holds the full-size originals (≈100 MB) on purpose: they are the source for
`bundle-recipe-art.py`, and redrawing them needs the owner's Mac.
