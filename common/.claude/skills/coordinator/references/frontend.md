# Frontend design (Vue and Nuxt UI): the coordinator's part

Any slice that creates or changes what the user sees (a page, a component, a layout, styling)
follows the `vue-ui-design` skill: the user's Vue UI kit (`@fernandojvideira/vue-ui-kit`, shadcn-vue
style), and a clean, minimal look that doesn't read as AI-generated. Your part:

- **Resolve the style brief in the Plan** and write it as one line in the spec. Precedence: what
  the user said in this task (loose words or `style: accent=... radius=...` knobs), then the
  project's standing brief from the Project Map, then the skill's defaults (light-first, neutral
  grays, one accent, `md` radius, comfortable density, system font, subtle motion, flat depth).
  The user's words win over every default, anti-patterns included.
- **One slice owns the tokens.** Theme changes (token overrides in the main CSS, the
  `/* style brief */` comment) go to a single slice that runs before the screens that depend on
  them, so parallel workers don't write the same CSS file.
- **Say the surface** for each screen: utility (app, dashboard, form, settings) or flagship
  (landing, marketing). It sets how much motion and expression is allowed.
- **Put the `DESIGN:` block** from the worker template in every frontend slice. Workers that have
  the `vue-ui-design` skill invoke it; the block carries the essentials for workers that don't.
- **Review the look as well as the diff** (step 5): token colors only, no raw palette classes, no
  card inside a card, one primary button per view, loading/empty/error states present, both color
  modes, and the kit's components used where they exist instead of hand-rolled copies. If a dev
  server and a browser are available, have the worker check a screenshot at phone and desktop
  width before reporting.
