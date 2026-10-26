# Style brief: knobs and what they change

The user tweaks the look in the prompt, either in plain words ("warmer, rounder, more space") or
as knobs on one line:

```
style: accent=teal neutral=stone radius=sm density=compact font=Geist mode=light motion=none depth=flat
```

Map plain words onto the nearest knob values and say which ones you picked. Any knob not given
keeps the standing brief's value (the `/* style brief */` comment in the project's main CSS, or
the "Design" section of its `CLAUDE.md`), or the default below. A preset sets several knobs at
once; knobs written next to it override the preset.

All CSS below goes in the project's main CSS file **after** `@import
'@fernandojvideira/vue-ui-kit/theme.css'`. Tokens are `H S% L%` triplets with no `hsl()`
wrapper. When a project sticks with a brief, put it at the top of that file:

```css
/* style brief: accent=teal neutral=stone radius=sm density=compact font=Geist mode=light motion=subtle depth=flat */
```

## Defaults

| Knob | Default | Why |
|---|---|---|
| `accent` | `mono` | The kit's near-black primary (white in dark mode). One accent only when the brief has one |
| `neutral` | `zinc` | The kit's own grays |
| `radius` | `md` | The kit's `0.5rem` |
| `density` | `comfortable` | The kit's own paddings |
| `font` | `system` | The OS face (SF on Apple, Segoe on Windows): native, fast, no dependency |
| `type` | `quiet` | An app scale; headlines get larger only on flagship surfaces |
| `mode` | `light` | Designed light first, dark checked too; the app follows the OS |
| `motion` | `subtle` | State changes only |
| `depth` | `flat` | Borders carry structure; shadows only on floating layers |

Match an existing project before applying a default: if its screens already use the kit's card
shadows, `depth` is `soft` for that project unless the user says otherwise.

## Presets

| Preset | Sets | Good for |
|---|---|---|
| `quiet` | all defaults | Most apps; the starting point |
| `tool` | `density=compact radius=sm depth=flat type=quiet font=system` + `font-mono` for IDs, codes and logs | Admin panels, internal tools, data-heavy screens |
| `editorial` | `density=airy type=editorial radius=sm depth=flat`, a serif or a distinctive sans for headings | Blogs, docs, content sites, portfolios |
| `soft` | `density=airy radius=lg depth=layered` | Consumer apps, onboarding, anything that should feel friendly |

## `accent`

Changes `--primary`, `--ring` and `--primary-foreground` in both modes, and `--chart-1`. `mono`
keeps the kit's values. A named color uses the row below (Tailwind's palette, picked so the text
on a primary button and `text-primary` on the page both reach 4.5:1):

| accent | `:root --primary` | `.dark --primary` |
|---|---|---|
| blue | `221.2 83.2% 53.3%` | `213.1 93.9% 67.8%` |
| indigo | `243.4 75.4% 58.6%` | `234.5 89.5% 73.9%` |
| violet | `262.1 83.3% 57.8%` | `255.1 91.7% 76.3%` |
| sky | `201.3 96.3% 32.2%` | `198.4 93.2% 59.6%` |
| cyan | `192.9 82.3% 31%` | `187.9 85.7% 53.3%` |
| teal | `175.3 77.4% 26.1%` | `172.5 66% 50.4%` |
| emerald | `162.9 93.5% 24.3%` | `158.1 64.4% 51.6%` |
| green | `142.4 71.8% 29.2%` | `141.9 69.2% 58%` |
| amber | `26 90.5% 37.1%` | `43.3 96.4% 56.3%` |
| orange | `17.5 88.3% 40.4%` | `27 96% 61%` |
| red | `0 72.2% 50.6%` | `0 90.6% 70.8%` |
| rose | `345.3 82.7% 40.8%` | `351.3 94.5% 71.4%` |

With any of these, `--primary-foreground` is `0 0% 98%` in light mode and `240 5.9% 10%` in dark
mode (dark-mode accents are light, so their button text is dark). `--ring` matches `--primary`.

```css
:root { --primary: 175.3 77.4% 26.1%; --primary-foreground: 0 0% 98%; --ring: 175.3 77.4% 26.1%; --chart-1: 175.3 77.4% 26.1%; }
.dark { --primary: 172.5 66% 50.4%; --primary-foreground: 240 5.9% 10%; --ring: 172.5 66% 50.4%; --chart-1: 172.5 66% 50.4%; }
```

A hex or brand color: convert it to `H S% L%` (`#0f766e` is `175.3 77.4% 26.1%`). Check
`--primary-foreground` against it (4.5:1 or better; switch to `240 5.9% 10%` when the color is
light) and the color itself as text on `--background` (4.5:1). If it fails as text, darken it
for light mode and lighten it for dark mode until it passes, and tell the user the value moved.
`red` as the accent competes with `--destructive`; say so and suggest a neighbor (`rose`,
`orange`) unless the user insists.

Use the accent for what should be found: the primary button, the current nav item, links,
focus rings, selection, one data series. Not for headings, backgrounds or decoration.

## `neutral`

Changes the hue of every gray (backgrounds, text, borders, muted surfaces) and keeps the kit's
lightness values, so contrast stays where the kit set it. `warm` means `stone`, `cool` means
`slate`.

- **`zinc`**: the kit's values, nothing to add.
- **`neutral`**: pure grays. Every kit token whose hue is `240` becomes `0 0% <same L>`, in both
  `:root` and `.dark` (for example `--muted-foreground: 0 0% 46.1%`, `--border: 0 0% 80%`).
- **`stone`, `slate`, `gray`**: the blocks below. Drop the `--primary` lines when `accent` isn't
  `mono`.

```css
/* stone */
:root {
  --foreground: 30 10% 3.9%; --card-foreground: 30 10% 3.9%; --popover-foreground: 30 10% 3.9%;
  --primary: 30 5.9% 10%; --ring: 30 5.9% 10%;
  --secondary: 30 4.8% 95.9%; --secondary-foreground: 30 5.9% 10%;
  --muted: 30 4.8% 95.9%; --muted-foreground: 30 3.8% 46.1%;
  --accent: 30 4.8% 95.9%; --accent-foreground: 30 5.9% 10%;
  --border: 30 5.9% 80%; --input: 30 3.8% 58%;
}
.dark {
  --background: 30 10% 3.9%; --card: 30 10% 3.9%; --popover: 30 10% 3.9%;
  --primary-foreground: 30 5.9% 10%; --ring: 30 4.9% 83.9%;
  --secondary: 30 3.7% 15.9%; --muted: 30 3.7% 15.9%; --muted-foreground: 30 5% 64.9%;
  --accent: 30 3.7% 15.9%; --border: 30 3.7% 15.9%; --input: 30 5% 40%;
}

/* slate */
:root {
  --foreground: 215 30% 3.9%; --card-foreground: 215 30% 3.9%; --popover-foreground: 215 30% 3.9%;
  --primary: 215 17.7% 10%; --ring: 215 17.7% 10%;
  --secondary: 215 14.4% 95.9%; --secondary-foreground: 215 17.7% 10%;
  --muted: 215 14.4% 95.9%; --muted-foreground: 215 11.4% 46.1%;
  --accent: 215 14.4% 95.9%; --accent-foreground: 215 17.7% 10%;
  --border: 215 17.7% 80%; --input: 215 11.4% 58%;
}
.dark {
  --background: 215 30% 3.9%; --card: 215 30% 3.9%; --popover: 215 30% 3.9%;
  --primary-foreground: 215 17.7% 10%; --ring: 215 14.7% 83.9%;
  --secondary: 215 11.1% 15.9%; --muted: 215 11.1% 15.9%; --muted-foreground: 215 15% 64.9%;
  --accent: 215 11.1% 15.9%; --border: 215 11.1% 15.9%; --input: 215 11.1% 40%;
}

/* gray */
:root {
  --foreground: 220 16% 3.9%; --card-foreground: 220 16% 3.9%; --popover-foreground: 220 16% 3.9%;
  --primary: 220 9.4% 10%; --ring: 220 9.4% 10%;
  --secondary: 220 7.7% 95.9%; --secondary-foreground: 220 9.4% 10%;
  --muted: 220 7.7% 95.9%; --muted-foreground: 220 6.1% 46.1%;
  --accent: 220 7.7% 95.9%; --accent-foreground: 220 9.4% 10%;
  --border: 220 9.4% 80%; --input: 220 6.1% 58%;
}
.dark {
  --background: 220 16% 3.9%; --card: 220 16% 3.9%; --popover: 220 16% 3.9%;
  --primary-foreground: 220 9.4% 10%; --ring: 220 7.8% 83.9%;
  --secondary: 220 5.9% 15.9%; --muted: 220 5.9% 15.9%; --muted-foreground: 220 8% 64.9%;
  --accent: 220 5.9% 15.9%; --border: 220 5.9% 15.9%; --input: 220 5.9% 40%;
}
```

**Dark-mode input borders.** The kit's dark `--input` equals its `--border` (15.9% lightness,
about 1.35:1 on the dark background), below the 3:1 a form control's edge needs. The blocks above
already raise it to 40% lightness (about 3.2:1); with `zinc` or `neutral`, add
`.dark { --input: 240 5% 40%; }` (or `0 0% 40%`) yourself.

## `radius`

| radius | `--radius` | Feel |
|---|---|---|
| `none` | `0rem` | Strict, technical |
| `sm` | `0.25rem` | Precise, tool-like |
| `md` | `0.5rem` | The kit's default |
| `lg` | `0.75rem` | Softer, consumer |
| `xl` | `1rem` | Friendly, playful |

`Card` uses Tailwind's `rounded-xl`, which doesn't follow `--radius` on its own. Tie it in so
cards scale with everything else (at `md` this is the same `0.75rem` as before):

```css
:root { --radius: 0.25rem; }
@theme inline { --radius-xl: calc(var(--radius) * 1.5); }
```

`Badge`, `Switch` and `Avatar` stay round at every radius; pills and circles are shapes, not
corner choices. Nested corners: an element inside a padded rounded container gets a smaller
radius (`rounded-md` inside `rounded-xl`), never the same one.

## `density`

The kit's components carry their own padding (`Card` parts `p-6`, buttons `h-9`). Density sets
the page rhythm around them and, where it differs from the kit, the `class` overrides you apply
consistently to every instance (or put once in a small wrapper in the project's
`components/ui/`).

| | compact | comfortable | airy |
|---|---|---|---|
| Page padding | `px-4 py-4 md:px-6` | `px-6 py-6 md:px-8 md:py-8` | `px-6 py-10 md:px-12 md:py-16` |
| Gap inside a group | `gap-2` / `gap-3` | `gap-4` | `gap-6` |
| Gap between groups | `gap-6` | `gap-8` / `gap-12` | `gap-16` / `gap-24` |
| `Card` parts | `class="p-4"` (`CardContent`/`CardFooter`: `p-4 pt-0`) | kit default | `class="p-8"` (`p-8 pt-0`) |
| Buttons in toolbars and rows | `size="sm"` | default | default, `size="lg"` for the primary action |
| Table rows | kit default (`TableCell` is `p-2`) | kit default | `TableCell class="px-4 py-3"`, `TableHead class="px-4"` |
| Body text | `text-sm` | `text-sm` (apps), `text-base` (reading) | `text-base` |

## `font`

`system` uses Tailwind's default stack, nothing to load. A named family:

```css
@theme { --font-sans: 'Geist', ui-sans-serif, system-ui, sans-serif; }
/* optional second family for headings only */
@theme { --font-display: 'Instrument Serif', ui-serif, Georgia, serif; }   /* class: font-display */
```

Loading it is a new dependency, so name it in your report:

- **Nuxt:** the `@nuxt/fonts` module, which finds families named in CSS and self-hosts them.
- **Vue + Vite:** the family's `@fontsource-variable/<name>` package, imported once in `main.ts`.

Pick for the subject, and use at most two families (if two, make them clearly different, like a
serif display over a sans body). Inter is what everyone reaches for, so use it when asked, not by
default. `font-mono` is for code, IDs and logs, never for labels or headings.

## `type`

| type | Page title | Section | Body | Notes |
|---|---|---|---|---|
| `quiet` | `text-2xl font-semibold tracking-tight` | `text-lg font-semibold` | `text-sm` / `text-base` | Apps and dashboards |
| `editorial` | `text-4xl md:text-5xl font-semibold tracking-tight` (or `font-display font-normal`) | `text-2xl` | `text-base md:text-lg leading-relaxed` | Reading surfaces; serif body gets `leading-relaxed` or looser |
| `bold` | `text-5xl md:text-7xl font-semibold tracking-tighter leading-[1.05]` | `text-3xl` | `text-lg` | Flagship heroes only; the headline is the design |

Large sizes get tighter tracking; small text never does. Line length stays under 80 characters
(`max-w-prose`, `max-w-xl` for intros).

## `mode`

| mode | What to do |
|---|---|
| `light` | Design and review in light first, check dark. The app follows the OS through `useColorMode()` |
| `dark` | Design and review in dark first, check light. Default the app to dark: set `class="dark"` on `<html>` (`index.html`, or `app.head.htmlAttrs` in `nuxt.config`) and treat "no stored preference" as dark in the toggle and in Nuxt's pre-hydration script |
| `light-only` / `dark-only` | Fix the class on `<html>`, render no toggle, and still keep both token sets valid |

## `motion`

| motion | Allowed |
|---|---|
| `none` | Only the kit's built-in feedback (`.press`, overlay open/close). No transitions of your own |
| `subtle` | Transitions on state changes (open, close, expand, select, reorder): 150 to 300ms, `ease-[var(--ease-settle)]`, `transform`/`opacity` only |
| `expressive` | Flagship surfaces only: one orchestrated moment (a page-load sequence, or one scroll-linked scene driven by scroll progress, never by hijacking the scroll). Utility screens in the same app stay `subtle` |

Every level honors `prefers-reduced-motion` (`motion-safe:` / `motion-reduce:`), and none of
them adds fade-ups to every section or hover lifts to every card.

## `depth`

| depth | CSS | Result |
|---|---|---|
| `flat` | `@theme { --shadow: 0 0 #0000; --shadow-sm: 0 0 #0000; }` | Cards, inputs and buttons lose their shadows, and so do the active tab and the switch and slider thumbs (they stay visible through color); borders carry structure. Popovers, menus, dialogs, sheets and tooltips keep theirs (`shadow-md` and up), so floating layers still float |
| `soft` | nothing | The kit's default soft shadows |
| `layered` | `.dark { --card: 240 6% 7%; --popover: 240 6% 9%; }` (keep the neutral's hue) | Dark-mode surfaces get lighter as they rise, the way a dimmed UI shows elevation. Light mode keeps the kit's shadows |

Glass (`backdrop-blur`) is for chrome that floats over content, like a sticky navbar on a long
page, never for cards. One effect per surface.

## `reference`

`reference="Linear"` (or any product) is a direction: take its density, type, color temperature
and how much it shows at once, and turn those into the knobs above, written back to the user.
Never copy its logo, copy, illustrations or exact layouts.
