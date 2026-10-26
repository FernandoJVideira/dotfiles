# Nuxt projects: what to record and what changes

A `nuxt.config.*` (and `nuxt` in `package.json`) means Nuxt. Most Vue habits still apply, but
these change where code goes and how it's checked; record them in the Project Map:

- **Version and source dir.** Nuxt 4 puts app code under `app/` (`app/pages`, `app/components`,
  `app/composables`, `app/layouts`, `app/middleware`, `app/plugins`, `app/assets`); Nuxt 3, or a
  project that set `srcDir`, keeps them at the root. `server/`, `shared/` and `public/` stay at the
  root in both. Read `nuxt.config.*` for `srcDir`, `ssr`, `modules`, `runtimeConfig`, `nitro` and
  `routeRules`.
- **Routing is the file tree** (`pages/`), with `definePageMeta` for layout and middleware. A new
  screen is a file, not a router entry; route middleware lives in `middleware/`.
- **Auto-imports.** Components, composables, `utils/` and Vue/Nuxt APIs are imported
  automatically, so a missing `import` is normal and grep for an import finds nothing: search by
  name. Component names come from the path (`components/user/Card.vue` is `<UserCard>`).
  Packages in `node_modules` are not auto-imported unless listed in `imports`/`components` config.
- **Data fetching.** `useFetch` / `useAsyncData` for page data (SSR-aware, deduplicated, keyed),
  `$fetch` for actions in event handlers. Calling `$fetch` at the top of `setup` in an SSR app
  fetches twice; the spec should say which one a slice uses.
- **`server/` is Nitro**, a second backend inside the frontend. In a project with a Go API, find
  out what it is for (a BFF, an auth proxy, nothing) and keep business logic in Go unless the
  Project Map says otherwise. Put the Go-vs-Nitro boundary in the contract.
- **Config and env.** `runtimeConfig` in `nuxt.config`, read with `useRuntimeConfig()`; public
  values are `NUXT_PUBLIC_*` env vars. The Go API base URL is usually one of them.
- **SSR and hydration.** Unless `ssr: false`, pages render on the server first: no `window`,
  `document` or `localStorage` at setup time (use `onMounted`, `import.meta.client`, or
  `<ClientOnly>`), and server and client must render the same markup.
- **Commands.** `nuxi prepare` (generates `.nuxt/` types; run it before typechecking a fresh
  checkout), `nuxi typecheck` (not bare `vue-tsc`), `nuxi build` or the `build` script,
  `nuxi generate` for a static site, Vitest with `@nuxt/test-utils` when the project has it.
  Prefer the `package.json` scripts when they exist.
