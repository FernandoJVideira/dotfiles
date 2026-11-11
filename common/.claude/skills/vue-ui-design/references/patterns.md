# Patterns by screen type

Read only the section for the screen you are building. The user's brief still wins over anything
here.

## Lists and tables

- **Counts.** Put a muted count next to every group or column header
  (`text-muted-foreground tabular-nums`). On editorial surfaces use a bracketed count, "(28)",
  instead of a pill `Badge`.
- **Rows.** A monospace ID (`font-mono text-xs text-muted-foreground`) plus a truncated title
  (`truncate`). Labels are one word. Statuses come from a small fixed set.
- **Row controls.** The checkbox, drag handle and row actions appear on row hover and on
  `focus-within`. On touch there is no hover, so they stay visible.
- **Footer.** An optional per-column calculation footer (count, sum).
- **Record metadata.** Label/value pairs: a small muted label over a plain value, like a
  colophon. Never a `Card` per field.
- **Opening a record.** From a list, open it in a side `Sheet` so the list keeps its context. Use
  a centered `Dialog` only for gallery or calendar views.

## Dashboards

- **One data source.** Views are saved configs (filter, sort, group, visible columns), switched
  with `Tabs`.
- **Order.** A summary first (one chart, or one or two numbers the user acts on), then exception
  tables ("Blocked", "Unassigned", "Overdue"), then a timeline or history.
- **Density.** At most 4 widgets per row. This extends the rule against four filler `StatCard`s.
- **Drill-down.** Clicking a chart part opens the matching records.

## Search and filters

- **Search field.** Segmented: a label above each segment and a plain placeholder ("Where" /
  "Add dates"). Once collapsed or submitted, the bar shows the chosen values, not empty fields.
- **Filter entry points.** A "Filters" button first, then one-tap chips for the 5 to 8 most used
  filters.
- **Result count.** In the page heading, rounded when large ("Over 1,000 homes in Lisbon").
- **Filter panel.** Lives in a `Sheet` (or a `Dialog` on desktop), grouped by topic, with a footer
  of "Clear all" plus a primary "Show N results" that updates live.
- **State.** All search and filter state lives in the URL query, so it survives reload and
  sharing.
- **Map or secondary pane.** A toggle, not a forced split.
- **No results.** Name the active filters and offer to remove the narrowest one.

## Onboarding

- **Entry screen.** One value line, one large primary action ("Get started"), and the login as a
  quiet secondary ("I already have an account").
- **Value first.** Let the user try, choose or configure before asking for an account. Ask for
  signup after.
- **Steps.** One question per step, large tap targets (choices as full-width rows or tiles), a
  progress indicator, a back action, and warm plain copy.
- **Does not transfer** to a calm product unless the brief asks: mascots, all-caps button labels,
  3D bottom-border buttons.

## Landing pages (flagship)

- **Hero.** An outcome-led headline, one supporting sentence, a primary and a secondary CTA.
- **Logo strip.** Muted, one row, directly under the hero.
- **Product shown.** A live HTML mock built from kit components, filled with dense realistic data
  (IDs, counts, relative times like "2 min ago") and framed like a window. Use it instead of a
  screenshot or an illustration.
- **Feature chapters.** An optional small sentence-case label, an outcome headline, one or two
  sentences, a link, then the UI. Alternate sides on desktop, stack on mobile.
- **Bento grid.** Mixed tile sizes are fine when every tile shows a real piece of the product.
- **Stats.** Every stat names its source or customer.
- **Closing CTA.** Repeats the hero's CTA pair verbatim.
- **Does not transfer** to a small product: live counters, big-number stat bands without real
  scale, audience-segment sections, news carousels.

## Long-running tasks

Instead of a lone spinner, show an inline list of finished steps with the current one last
("Connected to project", "Mapping posts…"), and end with a line that states the result with a
count ("47 posts mapped"). `Spinner` only on the current step.
