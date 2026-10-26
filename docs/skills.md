# Using the Claude Code skills

What each skill is and where it comes from is in the README. This page is how to drive them.

A skill runs in two ways. Claude Code picks one on its own when the request matches the
skill's description ("build a settings page" brings in `vue-ui-design`), or you call it by name:
`/coordinator add CSV export to the invoices page`. Calling it by name is the reliable way when
it matters. A skill added or changed by the installer shows up from the next session on.

## coordinator: multi-file work

```
/coordinator add a "last seen" column to the members table, sortable, backed by the API
```

It's a mode, like caveman. Start the session with `/coordinator` (alone, or with the first task)
and it stays on: every later request that changes code goes through the same workflow, and you
don't type the command again. Questions and explanations are answered directly, without
sub-agents.

| Say | Effect |
|---|---|
| `/coordinator`, `/coordinator <task>` | Turns it on for the session |
| `/coordinator status` | Says whether it's on, and shows the project layout it found |
| "stop coordinator" | Turns it off; Claude edits code itself again |

"normal mode" and "stop caveman" only affect caveman, so they leave the coordinator on.

Give it the outcome you want, not the steps. It works out the project layout first (monorepo,
client only, or API and client in separate repos), so open the session in the repo, or in the
parent folder when the API and the client are separate checkouts. Before spawning anyone it may
ask a question or two; those are the decisions that change the result, so answer them rather
than "you choose".

What you get at the end: the files changed per stack, the commands it ran with their results,
the assumptions it made, and what's left. It doesn't commit or push unless you ask, so say "and
commit it" in the request if you want that.

It handles Nuxt as well as plain Vue, with nothing to configure: file-based routes,
auto-imports, `useFetch` against `$fetch`, SSR, the Nitro `server/` folder, and `nuxi typecheck`.

For anything visual, put the look in the same request and it hands it to every frontend worker
(see the style brief below):

```
/coordinator build the billing settings page. style: accent=indigo density=compact
```

## vue-ui-design: interfaces with the UI kit

```
/vue-ui-design build the onboarding screen for new workspaces
```

It builds with `@fernandojvideira/vue-ui-kit`, in Vue or Nuxt, and keeps the result minimal: one
accent, hierarchy from type and space, no card soup, no gradients or entrance animations on app
screens, and loading, empty and error states with real copy. It reads the project first, so new
screens match the existing ones.

### Changing the look

Say it in words:

```
/vue-ui-design redo the dashboard: warmer, rounder, more breathing room, teal accent
```

or as knobs on one line, which is exact:

```
/vue-ui-design build the pricing page. style: accent=teal neutral=stone radius=lg density=airy font=Geist motion=subtle
```

| Knob | Values | Default |
|---|---|---|
| `accent` | `mono`, a color name (`blue`, `indigo`, `violet`, `sky`, `cyan`, `teal`, `emerald`, `green`, `amber`, `orange`, `red`, `rose`), or a hex | `mono` |
| `neutral` | `zinc`, `neutral`, `stone` (warm), `slate` (cool), `gray` | `zinc` |
| `radius` | `none`, `sm`, `md`, `lg`, `xl` | `md` |
| `density` | `compact`, `comfortable`, `airy` | `comfortable` |
| `font` | `system` or a family name (a new dependency) | `system` |
| `type` | `quiet`, `editorial`, `bold` | `quiet` |
| `mode` | `light`, `dark`, `light-only`, `dark-only` | `light` |
| `motion` | `none`, `subtle`, `expressive` (landing pages only) | `subtle` |
| `depth` | `flat`, `soft` (the kit's shadows), `layered` | `flat` |
| `preset` | `quiet`, `tool`, `editorial`, `soft` (sets several knobs at once) | `quiet` |
| `reference` | a product to take the feel from: `reference="Linear"` | none |

It answers with the brief it resolved ("Brief: teal on stone, lg radius, airy, Geist..."), so a
misread shows up before any code. What each value changes, down to the CSS token, is in
`common/.claude/skills/vue-ui-design/references/style-brief.md`.

A brief applies to that task only. To make it the project's look, add "make it the default": the
skill writes a `/* style brief: ... */` line at the top of the app's main CSS, and every later
session, and every coordinator worker, starts from it. Change it the same way, or edit that line.

Asking for something the defaults avoid (a dark hero, a gradient, a glass navbar) is fine. Your
words win; the skill then just makes it a good one.

## caveman: shorter replies

| Say | Effect |
|---|---|
| `/caveman`, "caveman mode", "be brief" | Terse replies, every technical fact kept, for the rest of the session |
| `/caveman ultra` | Maximum compression (the `ultracave` skill) |
| `/caveman wenyan` | Classical Chinese, even fewer characters (the `megacave` skill) |
| `/caveman status` | Says which mode is on |
| "stop caveman", "normal mode" | Back to normal |

The coordinator's sub-agents always reply in caveman mode; you don't need to turn it on for that.
Code, commit messages and error text are never compressed.

## humanizer: prose that doesn't sound generated

```
/humanizer <paste the text>
```

returns a draft, the patterns still left in it, and the final version. Name a file instead and it
edits the file in place, prose only (code, commands, paths and links stay as they are):

```
/humanizer docs/herdr.md
```

Paste a sample of your own writing first and it matches that voice instead of a neutral one.
Its most useful habit here is cutting the same point said twice in different words. Use the
plain `humanizer`, not the `anthropic-skills:humanizer` your account also syncs: that one is the
older upstream version without this fork's changes.

## When a skill doesn't show up

1. Start a new session. Skills load at session start.
2. `ls -l ~/.claude/skills`: each one should be a link into this repo's
   `common/.claude/skills`. If one is missing, run `common/install.sh`.
3. Check that its `SKILL.md` starts with a `---` block holding `name` and `description`; a skill
   without them isn't listed.
