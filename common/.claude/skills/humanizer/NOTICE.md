# Attribution

**Humanizer** by Siqi Chen, <https://github.com/blader/humanizer>, MIT licence (`LICENSE`, Copyright (c) 2025 Siqi Chen).
The patterns come from Wikipedia's "Signs of AI writing".

This is a **modified** copy, taken from a fork at a pinned commit:

- Fork: <https://github.com/FernandoJVideira/humanizer>, branch `each-fact-once`, commit
  `78e8acc1ac8a763bff63bf5d003ee6a80e3fdd98` (version 3.2.0, one commit on top of upstream
  `8c307f3`, release 3.1.0 plus upstream's later README fix).
- Only `SKILL.md` and `LICENSE` are vendored: the skill is the one file agents read.

## What was changed

A new pattern 3, **The same point twice**: a sentence restating the one before it, a preview plus an
"In summary" that repeat the body, a heading echoed by its first sentence, the same claim in a lead, a
bullet and a closer, twin words for one idea. It counts facts, not words, and keeps each fact once. It folds
in upstream's old pattern 24 (a heading repeated in the first sentence), so there are still 26 patterns;
patterns 3 to 23 moved up one number. "How to work" now lists the facts the text states so a repeat is
found across paragraphs, the draft keeps each claim once, and the final check looks for repeats that
were reworded instead of cut. "When not to act" keeps deliberate repetition. The full change, with the
README and changelog, is in the fork's commit.

## Updating

Work in the fork, not here: `git -C ~/Developer/Personal/humanizer fetch upstream && git merge upstream/main`
(the `upstream` remote is `blader/humanizer`), keep `python3 scripts/validate-package.py` passing (the skill has a
5,500-word cap), push, then fetch `SKILL.md` and `LICENSE` from the new commit
(`https://raw.githubusercontent.com/FernandoJVideira/humanizer/<commit>/SKILL.md`), compare each file's
`git hash-object` with the `sha` from `https://api.github.com/repos/FernandoJVideira/humanizer/contents/<file>?ref=<commit>`,
and update the commit above. Upstream renumbers patterns now and then, so expect merge conflicts on the headings.
