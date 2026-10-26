# The Vue UI kit

`@fernandojvideira/vue-ui-kit`: Vue 3 components in the shadcn-vue style, built on reka-ui,
`class-variance-authority`, `tailwind-merge` and Tailwind v4, with icons from `@lucide/vue`. It
ships source (`.vue` files), so the app's own Vite build compiles it. When a detail here isn't
enough, the kit's own docs are in the package: `node_modules/@fernandojvideira/vue-ui-kit/docs/`
(`COMPONENTS.md` is the prop-by-prop reference, `EXAMPLES.md` has full page templates) and the
components themselves in `src/components/ui/<name>/`.

## Setup

The package is installed from the user's own registry; if it's missing, ask the user to install
it rather than guessing a source. Tailwind v4 needs `tailwindcss` and `@tailwindcss/vite`.

**Vue + Vite:** `tailwindcss()` in `vite.config.ts` plugins, and in the CSS imported by
`main.ts` (here `src/assets/main.css`):

```css
@import 'tailwindcss';
@source '../../node_modules/@fernandojvideira/vue-ui-kit/src';
@import '@fernandojvideira/vue-ui-kit/theme.css';
/* style brief + token overrides go here, after theme.css */
```

**Nuxt 4:** in `nuxt.config.ts`, `css: ['~/assets/css/main.css']` and
`vite: { plugins: [tailwindcss()] }`. The file is `app/assets/css/main.css`, three levels from
`node_modules`:

```css
@import 'tailwindcss';
@source '../../../node_modules/@fernandojvideira/vue-ui-kit/src';
@import '@fernandojvideira/vue-ui-kit/theme.css';
```

A pre-Nuxt-4 layout (no `app/` folder) has `assets/css/main.css`, one `../` fewer. `@source` is
relative to the CSS file; a component that renders unstyled means that path is wrong. If the app
already uses `@nuxt/ui`, add only the `@source` and `theme.css` lines to its existing `main.css`
and don't register the Tailwind plugin twice.

**Imports.** Always explicit: `import { Button, Card } from '@fernandojvideira/vue-ui-kit'`.
Nuxt auto-imports its own `components/` but not this package, unless the project lists the names
in `imports.presets`.

**Nuxt SSR.** Overlays teleport and are SSR-safe; `Carousel` becomes interactive after mount;
nothing needs `<ClientOnly>`. `useColorMode()` is a no-op on the server, so a dark preference
flashes light for a frame unless the app adds this script before hydration:

```ts
// nuxt.config.ts
app: {
  head: {
    script: [{
      innerHTML: `(function(){try{var m=localStorage.getItem('vue-ui-kit-color-mode');var d=m==='dark'||(m!=='light'&&matchMedia('(prefers-color-scheme: dark)').matches);document.documentElement.classList.toggle('dark',d)}catch(e){}})()`,
      tagPosition: 'head',
    }],
  },
},
```

**Router links.** Components built on reka-ui's `Primitive` take `as` / `asChild`:
`<NavLink :as="NuxtLink" to="/about">` or `<Button as-child><RouterLink to="/new">New</RouterLink></Button>`.
Active state is a plain `active` prop, computed by the app.

## Components

Every component takes `class`, merged with `cn()` so a conflicting utility you pass wins.

| Area | Components | Notes |
|---|---|---|
| Actions | `Button` (`variant`: default, destructive, outline, secondary, ghost, link; `size`: default, sm, lg, icon), `Toggle`, `ToggleGroup`/`ToggleGroupItem` | `size="icon"` needs an `aria-label`. One `default` button per view |
| Forms | `FormField` (`label`, `hint`, `error`; slot gives `{ id }`), `Label`, `Input`, `Textarea`, `NumberInput`, `Checkbox` (tri-state), `Switch`, `RadioGroup`/`RadioGroupItem`, `Select` (+ `SelectTrigger`, `SelectValue`, `SelectContent`, `SelectItem`, `SelectGroup`, `SelectLabel`, `SelectSeparator`), `Combobox`, `Slider` (`v-model` is always an array), `DatePicker`, `Calendar`, `FileUpload`, `MarkdownEditor`, `Rating` | `FormField` is layout, not validation: pass your own error string. A `Switch` or `Checkbox` reads better as an inline `Label` + control pair |
| Layout | `Card` (+ `CardHeader`, `CardTitle`, `CardDescription`, `CardContent`, `CardFooter`), `Separator` (`orientation`), `Tabs` (+ `TabsList`, `TabsTrigger`, `TabsContent`), `Accordion` (+ `AccordionItem`, `AccordionTrigger`, `AccordionContent`), `Sidebar` (`v-model:collapsed`, `v-model:open`; slots `header`, default, `footer`) + `SidebarLink` | `Card` is `rounded-xl border shadow` with `p-6` parts. `Sidebar` is a rail on `lg`+ and an overlay below |
| Navigation | `Navbar` (pill), `NavbarSimple`, `NavbarTransparent`, `NavbarCentered`, `NavLink` (`active`), `Breadcrumb` (+ `BreadcrumbItem`, `BreadcrumbSeparator`), `Pagination`, `Stepper`, `CommandPalette` | `Navbar` shrinks on scroll (`shrinkOnScroll`, `scrollThreshold`) |
| Overlays | `Dialog` (+ `DialogTrigger`, `DialogContent`, `DialogHeader`, `DialogFooter`, `DialogTitle`, `DialogDescription`, `DialogClose`), `AlertDialog` (+ `AlertDialogAction`, `AlertDialogCancel`, ...), `Sheet` (+ `SheetContent`, `SheetHeader`, ...), `Popover` (+ `PopoverTrigger`, `PopoverContent`), `DropdownMenu` (+ `DropdownMenuTrigger`, `DropdownMenuContent`, `DropdownMenuItem`, `DropdownMenuLabel`, `DropdownMenuSeparator`, `DropdownMenuGroup`), `Tooltip` (+ `TooltipTrigger`, `TooltipContent`; one `TooltipProvider` at the app root) | `AlertDialog` only for destructive confirmation; a `Sheet` for a side task; a `Dialog` for a short self-contained one |
| Feedback | `Alert` (`variant`: default, destructive) + `AlertTitle`/`AlertDescription`, `Toaster` + `toast()` (vue-sonner), `Progress` (`modelValue`, `max`), `Spinner` (`label`), `Skeleton`, `EmptyState` (`title`, `description`; slots `icon`, `actions`) | Mount one `<Toaster />` near the app root |
| Data | `Table` (+ `TableHeader`, `TableBody`, `TableRow`, `TableHead`, `TableCell`), `StatCard` (`label`, `value`, `delta`, `trend`), `Badge` (`variant`: default, secondary, destructive, outline), `Avatar` (+ `AvatarImage`, `AvatarFallback`), `Timeline`, `LineChart`, `AreaChart`, `BarChart`, `DoughnutChart` | Charts read `--chart-1`..`--chart-5`. `StatCard` trends use raw emerald/red. `Badge` is static: no hover |
| Marketing | `Hero` (split; slots `badge`, `title`, `description`, `actions`, `visual`), `HeroCentered`, `HeroMedia` (`background` slot, light text baked in), `Footer`, `FooterSimple`, `FooterCentered`, `FooterNewsletter`, `PricingCard`, `ProductCard`, `Testimonial`, `LogoCloud`, `Carousel` (+ `CarouselContent`, `CarouselItem`, `CarouselPrevious`, `CarouselNext`) | Heroes have a fade-and-rise entrance (reduced-motion aware) and a faint `--primary` glow |

Also exported: `cn()`, `useColorMode()` (`{ mode, isDark }`, `mode` is `'light' | 'dark' |
'system'`, persisted), `useClickOutside(target, onOutside)` for custom dismissable overlays, and
`provideLabels`/`useLabels` for translating the kit's built-in strings ("Close", "Loading"...)
when the app isn't in English.

Not in the kit on purpose: an account menu (build it from `DropdownMenu` + `Avatar`, pinned to
the `Sidebar` footer in dashboards), a 404 page (a page of markup with an `EmptyState`-like
layout), and validation.

## Tokens

All colors are `H S% L%` triplets on `:root` with a `.dark` set, mapped to Tailwind colors in an
`@theme inline` block, so `bg-primary`, `text-muted-foreground` and `border-border` are real
utilities:

`--background`, `--foreground`, `--card`, `--popover`, `--primary`, `--secondary`, `--muted`,
`--accent`, `--destructive` (each with a `-foreground` pair), `--border` (dividers, 80% L),
`--input` (control edges, 58% L, 3:1 on white), `--ring`, `--radius` (`0.5rem`; `rounded-lg` is
`--radius`, `md` and `sm` step down by 2px), `--chart-1`..`--chart-5`.

Also from `theme.css`: `--ease-settle` (`cubic-bezier(0.16, 1, 0.3, 1)`, use as
`ease-[var(--ease-settle)]`), the `.press` class (scale 0.97 on `:active`, used by `Button`),
reduced-motion handling for the kit's own animations, a stronger `--border` under
`prefers-contrast: more`, and a 300ms ease on the light/dark switch.

`--accent` is the kit's hover surface (a light gray), not a brand color. The brand color is
`--primary`.

## Extending

A component the kit doesn't have goes in the project's own `components/ui/<name>/` with an
`index.ts`, written like the kit's:

```ts
// components/ui/segmented/index.ts
import { cva, type VariantProps } from 'class-variance-authority'
export { default as Segmented } from './Segmented.vue'
export const segmentedVariants = cva(
  'inline-flex items-center rounded-md bg-muted p-1 text-muted-foreground',
  { variants: { size: { default: 'h-9', sm: 'h-8 text-xs' } }, defaultVariants: { size: 'default' } },
)
export type SegmentedVariants = VariantProps<typeof segmentedVariants>
```

```vue
<script setup lang="ts">
import type { HTMLAttributes } from 'vue'
import { cn } from '@fernandojvideira/vue-ui-kit'
import { segmentedVariants, type SegmentedVariants } from '.'
const props = defineProps<{ size?: SegmentedVariants['size']; class?: HTMLAttributes['class'] }>()
</script>

<template>
  <div :class="cn(segmentedVariants({ size }), props.class)"><slot /></div>
</template>
```

Use a reka-ui primitive when the behavior exists there (it brings keyboard handling and ARIA),
token colors only, and the kit's focus style. A structural change to an existing kit component
belongs in the kit's own repo, not in `node_modules`; say so to the user instead of patching it.
