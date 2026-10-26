---
name: vue-ui-design
description: >
  Design and build clean, minimal Vue or Nuxt interfaces with the @fernandojvideira/vue-ui-kit
  (shadcn-vue style: reka-ui, Tailwind v4, CSS tokens) that don't read as AI-generated. Reads
  a style brief from the prompt (accent, neutral, radius, density, font, mode, motion, depth)
  and maps it onto the kit's tokens. Use for any new page, screen, component or restyle in a
  Vue/Nuxt app, for "make it look less generic", and for frontend slices the coordinator hands
  out.
---

# Vue UI design

Build interfaces with the user's Vue UI kit (`@fernandojvideira/vue-ui-kit`) that look calm,
specific and made on purpose. The kit is built the shadcn-vue way, so its components already
have good defaults; most generic-looking UI comes from what gets put around them: a card around
everything, a gradient behind everything, an animation on everything.

The taste here is restraint: one accent, a lot of neutral, hierarchy from type and space, and
motion only where it explains a change. Spend boldness in one place per screen, and only if the
brief asks for it.

**The user's words always win.** A style brief in the prompt overrides every default in this
skill, including the anti-patterns below: if they ask for a dark hero with a gradient, build a
good one.

## References

- `references/kit.md`: setup (Vue and Nuxt), the full component list with the props that matter,
  tokens, and how to extend the kit. Read it before writing any markup.
- `references/style-brief.md`: every knob, its values, and the exact token or class it changes.
  Read it whenever the prompt says anything about look and feel.

## 1. Read the project first

Before designing, find out what is already decided:

- **Vue or Nuxt.** `nuxt.config.*` means Nuxt: pages live in `pages/` (Nuxt 4: `app/pages/`),
  layouts in `layouts/`, and the main CSS is usually `app/assets/css/main.css`. Plain Vue with
  Vite: `src/`, a router file, and the CSS imported from `main.ts`.
- **The kit's setup.** Find the CSS file that imports `@fernandojvideira/vue-ui-kit/theme.css`.
  If there is none, set it up as `references/kit.md` describes. If a component renders
  unstyled, the `@source` path is wrong.
- **The standing brief.** A `/* style brief: ... */` comment at the top of that CSS file, or a
  "Design" section in the project's `CLAUDE.md`, is the project's current look. Token overrides
  already in the file are part of it.
- **Existing screens.** Match what's there: layout shell, spacing, how headings are set. A new
  page that looks like a different product is a bug, even if it's pretty.
- **Another component library** (`@nuxt/ui`, PrimeVue...): use one library per surface and don't
  mix both on the same screen.

## 2. Resolve the style brief

Combine, in this order of precedence: what the prompt says, the standing brief, then the
defaults in `references/style-brief.md` (light-first, neutral zinc, the kit's near-black
primary, radius 0.5rem, comfortable density, system font, subtle motion, borders over shadows).

The user can say it loosely ("teal, sharp corners, compact, feels like Linear") or as knobs:

```
style: accent=teal neutral=stone radius=sm density=compact font=Geist mode=light motion=none depth=flat
```

Write the resolved brief back as one line before you start ("Brief: teal accent on stone, 4px
radius, compact, Geist, light-first, no motion, flat"). A reference product ("like Linear",
"like Things") is a direction to interpret, not a site to copy: take its density, type and
color temperature, never its logo, copy or exact layout.

Then apply it in the project's main CSS, after the `theme.css` import, as token overrides.
Never edit the kit's own files for a theme change. If the user says the brief should stick
("make this the default", "for this project"), update the `/* style brief */` comment too;
otherwise the brief applies to this task only.

## 3. Plan, then check the plan against the defaults

Before code, write a short plan:

- **Surface:** utility (app screen, dashboard, form, settings) or flagship (landing, marketing,
  product page). This sets the motion budget and how much expression is allowed.
- **The one job** of the screen and its primary action. One primary `Button` per view.
- **Layout:** an ASCII wireframe with alignment (app UI is left-aligned; centered is for a
  single focused action or a short hero), the max widths, and which kit components fill which
  region.
- **The one memorable thing**, if the surface has room for one: a large confident headline, a
  well-set number, a real product screenshot. Everything around it stays quiet.

Then read the plan as if a different, similar prompt produced it. If it would come out the same
for any SaaS app, change the part that is generic and say what you changed. These are the
defaults that make generated UI look generated:

| Default | Do instead |
|---|---|
| Every block wrapped in a `Card`, cards inside cards | A `Card` is for a real object (a project, an invoice, a plan). Group settings as sections with a heading and a `Separator`. Lists are rows, not cards |
| The same soft shadow under every card | Borders carry structure (`depth=flat` removes the kit's shadows). Shadow only on things that float: popovers, dialogs, sheets |
| Gradient washes, glows, gradient text, glass on content | Solid token colors. The only gradient is the faint `--primary` glow (8% opacity) the kit's `Hero` components ship with; keep it, or build the hero section from plain markup when the brief is flat |
| A row of four `StatCard`s with deltas on every dashboard | Show the metrics the user actually acts on. Two real numbers beat four filler ones; a table can be the dashboard |
| ALL-CAPS tracked eyebrow above every heading | The heading alone. A label above content only when it carries information |
| One word in a headline colored or italic | Set the whole headline well: size, weight, `tracking-tight` on large sizes only |
| Numbered markers (01 / 02 / 03) | Only for a real sequence (`Stepper`, `Timeline`) |
| `Badge` on everything, emoji as icons | `Badge` for a real status; icons from `@lucide/vue`, `size-4`, only where they speed up scanning |
| Fade-and-rise on every section, hover lift on every card | No entrance motion on utility screens. Motion answers an action (open, expand, confirm) |
| `→` on every link and button, "Get started" / "Learn more" | A verb that says what happens: "Create invoice", "Save changes" |
| Cream background with a terracotta accent, near-black with acid green | Pick color from the subject and the brief. The default here is neutral with one accent |
| Center-aligned everything | Left-aligned content with a clear left edge; center only the rare focused moment |

## 4. Build with the kit

Use the kit's components for everything they cover (the list is in `references/kit.md`):
`Button`, `Input`, `FormField`, `Select`, `Dialog`, `Sheet`, `Tabs`, `Table`, `Sidebar`,
`EmptyState`, `Skeleton`, `Toaster`/`toast`, `Navbar*`, `Hero*`, `Footer*` and the rest. Import
them from `@fernandojvideira/vue-ui-kit` (Nuxt doesn't auto-import them unless the project lists
them in `imports.presets`).

**Color.** Only token utilities: `bg-background`, `text-foreground`, `text-muted-foreground`,
`bg-muted`, `border-border`, `bg-primary`, `text-primary`, `ring-ring`. No raw palette classes
(`bg-blue-500`, `text-gray-600`): they break dark mode and the user's brief. The one exception is
a data status color, which follows `StatCard`'s emerald/red. Secondary text is
`text-muted-foreground`, not a lighter gray you picked.

**Type.** Hierarchy comes from size, weight and space, not from boxes. A small scale goes a long
way: `text-sm` for UI and body in apps, `text-base` for reading, then one or two heading sizes
per screen (`text-lg font-semibold` for a section, `text-2xl font-semibold tracking-tight` for
a page title; marketing headlines larger). `tabular-nums` on numbers that line up. Body text at
`max-w-prose` or narrower (under 80 characters). `font-medium` for emphasis inside UI, not bold.

**Space.** Tailwind's 4px steps on an 8px rhythm: `gap-2`, `gap-4`, `gap-6`, `gap-8`, `gap-12`,
`gap-16`. Related things close together, groups far apart: when in doubt, add space, not a
border. The density knob sets the scale (`references/style-brief.md`). Page widths: `max-w-2xl`
for forms and settings, `max-w-5xl`/`max-w-6xl` for app content, full width with a `Sidebar`
for dashboards.

**Overrides.** Every component takes `class`, merged with `cn()`, so `class="p-4"` beats the
component's own padding. Use that for local adjustments. A global change is a token, not a
class sprinkled on every instance.

**Something the kit doesn't have.** Build it the shadcn-vue way in the project's own
`components/ui/<name>/` (Nuxt: `app/components/ui/`): a reka-ui primitive if there is one,
variants with `class-variance-authority`, classes merged with the kit's exported `cn()`, token
colors, a `class` prop, and the kit's focus style (`focus-visible:outline-none
focus-visible:ring-1 focus-visible:ring-ring`). Never edit the kit in `node_modules`.

**Every state.** Design loading (`Skeleton` shaped like the content, `Spinner` only inside a
button or for waits with no shape), empty (`EmptyState` with one action that gets the user
going), error (`Alert variant="destructive"` or a `toast.error`, saying what went wrong and how
to fix it), and disabled (with the reason nearby). Respond to every action in under 100ms:
`Button` already presses on pointer-down through the kit's `.press` class.

**Dark mode.** Comes free from the tokens. Toggle it with `useColorMode()` and a `Sun`/`Moon`
icon from `@lucide/vue`. In Nuxt, add the kit's pre-hydration script (in `references/kit.md`)
so a dark preference doesn't flash light. Dark is dimmed, not inverted: if a surface needs to
stand out in dark mode, make it slightly lighter than the background, never darker.

**Motion.** Utility surfaces: state changes only (open, close, expand, select), 150 to 300ms,
the kit's `ease-settle` curve (`ease-[var(--ease-settle)]`), `transform` and `opacity` only. No
scroll-triggered effects, no ambient animation. Flagship surfaces may have one orchestrated
moment (a page-load sequence or one scroll-linked scene) and nothing scattered. Never take over
the scroll. Everything respects `prefers-reduced-motion` (the kit's own components already do;
yours must too, with `motion-safe:` / `motion-reduce:`).

**Accessibility floor.** Visible focus on everything interactive, full keyboard operation, tap
targets of at least 40px on touch (`size="lg"` buttons or padding on mobile), labels for every
control (`FormField` wires the `id`), `aria-label` on icon-only buttons, 4.5:1 for text, 3:1 for
control borders (the kit's light `--input` already is; its dark `--input` is not, so raise it as
`references/style-brief.md` shows). Layouts work
from 375px up without horizontal scroll.

**Code comments.** Only when extremely necessary: a non-obvious why, a constraint, a trap. One
short line, never restating the markup or the class names, no section banners.

**Copy.** Words are part of the design. Name things the way the user thinks of them ("Members",
not "User entities"). Sentence case. Buttons say what happens, and the same verb follows through
the flow ("Publish" makes a toast that says "Published"). Errors explain and offer the fix,
without apologizing. An empty screen invites the next action. When the brief has no real
content, write plausible content for the actual subject, never lorem ipsum, and never a
placeholder rectangle where the product should be.

## 5. The restraint pass

Before calling it done, look at the result (take a screenshot if a browser is available: phone
width and desktop, light and dark). For each effect, border, badge, icon and shadow, ask: if I
remove it, does the screen lose meaning or only decoration? Remove the decoration. Then check:

- One primary action per view, and it is obvious.
- One accent color doing the pointing; everything else is neutral tokens.
- Type and space carry the hierarchy; no box exists only to group.
- No card inside a card; no shadow on anything that doesn't float.
- Every state (loading, empty, error) exists, with real copy.
- Light and dark both look intended, and nothing uses a raw palette color.
- At least one thing was removed since the first draft.

If you can't remove anything from a utility screen, look again.

## Credits

Built on Anthropic's `frontend-design` skill (Apache-2.0) and s1gmamale1's `apple-design-skills`
(MIT), adapted to the Vue UI kit. See `NOTICE.md`.
