# Notice

`vue-ui-design` is an original skill written for the `@fernandojvideira/vue-ui-kit`. Parts of
its guidance are adapted from two other skills; nothing from them is copied verbatim.

- **Anthropic's `frontend-design` skill**, from
  [anthropics/skills](https://github.com/anthropics/skills/tree/8a1541c4a3ffa5a20a5a91de0dcf3f0bab1d1ef4/skills/frontend-design)
  at commit `8a1541c4a3ffa5a20a5a91de0dcf3f0bab1d1ef4` (the same file ships in the
  `frontend-design` plugin of
  [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official/tree/58267944f92187b7d6a1c822165c96c81c864806/plugins/frontend-design)).
  Licensed under the Apache License 2.0, in `LICENSE-APACHE`. Adapted here: the list of
  defaults that make generated design look generated, the plan-then-review process, "spend
  boldness in one place", the quality floor, and the guidance on interface copy. Changed:
  aimed at minimal app UI with one component kit instead of a distinctive look per brief, and
  turned into kit-specific rules.
- **s1gmamale1's [apple-design-skills](https://github.com/s1gmamale1/apple-design-skills/tree/8a3fbea8b561405e5719d682ebd1d14c952aecd7)**
  at commit `8a3fbea8b561405e5719d682ebd1d14c952aecd7`, MIT License, in `LICENSE-MIT`
  (Copyright (c) 2026 s1gmamale1). Adapted here: the restraint pass ("does removing it lose
  meaning or only decoration?"), light-first with one accent, the utility versus flagship motion
  budget, dimming instead of inverting for dark mode, respond-in-100ms, and designing every
  state.

The kit's component names, tokens and setup come from the kit's own documentation. The
shadcn-vue conventions (reka-ui primitives, `cva` variants, `cn()`, `H S% L%` tokens) are the
kit's own design basis.

To update: compare the two upstream skills at their current commits with the ones above, carry
over what still fits a minimal kit-based UI, and change the commits here.
