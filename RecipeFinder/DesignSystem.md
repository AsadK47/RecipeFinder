# RecipeFinder — Design System (living doc)

The app's visual language and the shared tokens that enforce it. **Update this
whenever a styling decision is made or a "why does X look different from Y" bug
is fixed** — that's the point of it. Keep it short and current.

## The aesthetic
Frosted, translucent surfaces floating over the theme's background gradient.
Nothing should read as an opaque white/grey block on the gradient. Cards and
inputs **blend** into the glass via translucent fills, not solid fills.

## Tokens — use these, never hand-roll a surface
| Token | Use for | Definition |
|---|---|---|
| `.appCard()` | any card / tile / section container | `Theme/View+AppCard.swift` — `.ultraThinMaterial` (frosted) or the solid fill when `cardStyle == .solid`. Honours the user's setting. |
| `.appInputField()` | any text field / menu-style input on a card | `Theme/View+AppInputField.swift` — translucent `white.opacity(dividerOpacity)` fill + a 0.5pt `dividerColor` hairline border, radius 12. Pair with `.textFieldStyle(.plain)`. |
| `.shimmering(active:)` | loading skeleton sweep | `Components/Recipe/Shimmer.swift` |
| `GlassCard` | detail-screen info cards | existing component |
| `PrimaryButton` | primary CTAs (capsule) | existing component |

## Hard rules (violations are the bugs we keep re-fixing)
- **Never** `.textFieldStyle(.roundedBorder)` — it paints an opaque white box that
  clashes with frosted cards. Use `.textFieldStyle(.plain)` + `.appInputField()`.
- **Never** hand-roll a card/field background (`Color.white.opacity(...)`,
  `secondaryBackground`, bare `.ultraThinMaterial`, `Color(.systemGray6)`). Route
  through `.appCard()` / `.appInputField()` so surfaces can't drift.
- Chips/pills (suggestions, tags) are a **separate** element class — a small
  `secondaryBackground` pill is fine; don't confuse them with input fields.
- Form section content stacks are `VStack(alignment: .leading)` **and** full
  width, or narrow controls (menus, steppers) drift to centre while wide ones
  (segmented pickers) look left-aligned. See the Details section.

## Lessons (dated — newest first)
- **2026-09-24 — A translucent fill alone isn't a visible boundary on a gradient.**
  `white.opacity(0.1)` read fine on the darker blue but vanished on the light teal,
  so the notes field looked like unstyled floating text. Fix: keep the translucent
  fill but add a 0.5pt `dividerColor` hairline border — legible on any hue, and not
  the opaque box we were avoiding. When judging a surface, picture it on BOTH ends
  of the gradient, not just where the screenshot happened to land.
- **2026-09-24 — Cards need internal padding + one content stack.** The notes card
  had its `Divider()`/summary as siblings of the card (not in the content `VStack`)
  and no `.padding()`, so content sat flush to the edges. Every `.appCard()` wraps a
  single padded stack.
- **2026-09-24 — Match by reading, not guessing.** Making the wizard inputs
  "look like the title field" took 3 tries because I *approximated* the material
  (opaque grey → grey+border) instead of opening the reference view and copying
  its exact treatment. **To match an existing element: read its modifiers first,
  extract a token, reuse it.** The title field was `white.opacity(dividerOpacity)`
  translucent with no border — once read, one token fixed the whole page.
- **2026-09-24 — One editor, presented modularly.** Duplicate editors for the
  same data = drift. Single canonical editor (`RecipeWizardBuilder` save path),
  shown focused per section. See the recipe wizard.
- **2026-10-09 — Never colour content *text* with the brand accent on a frosted/
  gradient surface.** `accentColor` (teal) text on a `GlassCard`/`.appCard()`/the
  teal gradient is near-invisible (e.g. the servings "2.0x", shopping store name,
  refresh-diff value). **Rule:** content Text → `.primary` / `adaptiveForegroundColor()`
  / `adaptiveSecondaryForeground()`. Keep the colour on an *icon* beside it, or make
  the text a **filled pill** (white on an accent `Capsule`/`Circle`). Same "picture it
  on both ends of the gradient" test — now applied to text colour, not just fills.
