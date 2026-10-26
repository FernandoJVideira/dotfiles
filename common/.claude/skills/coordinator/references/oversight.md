# Oversight: you run the fleet

Spawning an agent starts your responsibility for it; it ends when the agent has finished and you
have read its result. You know what every agent is doing, and you step in when it goes wrong.

**Run ledger.** Keep one row per agent, in the plan and updated on every signal: its `agentId`
(from the spawn result; that is its address), slice, model, the files it may change, state
(running, waiting on me, done, stopped, replaced), the last signal and when it came, and the
corrections you have sent. Show the user a compact version when a wave starts, when something
changes, and at the end.

**Four ways to see what is happening**

1. **Worker event messages.** Workers send one-line messages to `main` with `SendMessage`, and
   only when something happens (the worker template lists the events). They arrive in your
   conversation as agent messages that name the sender. Each one is billed at your rate, which is
   why workers send no start messages, milestones or progress chatter.
2. **`ListAgents`.** Every subagent, helpers included, with its state (running, completed,
   killed). Use it when a signal says something is wrong or you need to know a worker is still
   alive.
3. **The watcher.** Only when two or more workers run in parallel; a lone worker needs none.
   Start `Monitor` on `references/watch-slices.py` (next to this file; installed at
   `~/.claude/skills/coordinator/references/`):

   ```
   python3 -I ~/.claude/skills/coordinator/references/watch-slices.py <repo> <slices-file>
   ```

   The slices file (in your scratchpad, not the repo) has one line per slice: its name, then the
   files and folders its worker may change. One watcher per git repo (separate API/client repos
   need two). It costs nothing while it is quiet: in-scope edits print nothing, and it prints
   `OUT-OF-SCOPE <path>` and `OVERLAP <path> <a> <b>` once per path, `IDLE <slice> <seconds>` once
   per quiet spell, and `ACTIVE <slice> <path>` when an idle slice moves again. It stops itself
   after 20 events or 15 minutes with no change. Set `timeout_ms` to 1800000 and `TaskStop` it
   when the wave ends. Re-arm only under the limits in "Cost and loop limits" in `SKILL.md`.
4. **The working tree.** `git status`, `git diff --stat` and `git diff <path>` on a slice's files,
   read-only, when you want facts instead of the worker's account. Never Read or tail a worker's
   `output_file`: it is the full transcript and floods your context.

**What calls for action**

- an `OUT-OF-SCOPE` or `OVERLAP` line
- an event message: `STATUS ... BLOCKED`, `STATUS ... STUCK`, a deviation from the spec, or a
  `SUGGEST` (see "Who decides")
- the same failure twice (same test, error or command) in a message or a report
- `IDLE`: check `ListAgents` once. If the worker is running, ask it for a one-line status once.
  If it stays silent and unchanged, it is stopped and replaced at the next notification you get
  (that uses its one replacement)
- a worker's work that contradicts another slice's contract (a renamed field, a changed shape)
- the user changing the request while workers run
- a destructive command (`rm -rf` outside build folders, `git reset --hard`, `git clean`, force
  push, dropping tables, deleting migrations) in a message or in the diff
- an agent that shows `completed` without a report matching the spec, or `killed` unexpectedly

**Intervention ladder** (take the lowest step that works)

1. **Guide.** `SendMessage` to its `agentId`: what is wrong, which file and line, what to do
   instead. Workers keep their context. One message with every point.
2. **Redirect.** The spec was wrong or the user changed it: send the change as a delta ("change X
   to Y; ignore my earlier point about Z; keep what you have done on W").
3. **Relay.** Workers cannot see each other. When one slice's result changes what another needs
   to know, send that fact to the affected worker yourself.
4. **Stop.** `TaskStop` with its `agentId`, for: edits outside its files after a warning, a
   destructive command, no progress after a guide, or the user cancelling. Then `git diff` what
   it left behind and decide what to keep. Cleaning up is a worker's job, never yours.
5. **Replace.** A fresh worker with the original spec plus what is done and verified, what went
   wrong, and the rule that was broken. Prefer this to resuming an agent whose own context is the
   problem.
6. **Escalate.** Tell the user (`AskUserQuestion`) when a decision is theirs, or when a worker
   was denied a permission. Do not do the denied action for it and do not hand it to another
   agent: that would go around the user's choice.

Put every intervention in your next status update to the user in one line: which agent, why,
what you did.

## Who decides

Your word is final for every agent: a worker follows your spec and your messages exactly, even
when it disagrees, and says so once in its report. Only the user can overrule you. Workers see
the real code and you do not, so take their critiques and suggestions seriously:

- A worker sends `SUGGEST <slice> | what | why (file and line, an error, a number) | cost` in a
  message only when the point changes what it is doing right now or spares another slice
  rework: a wrong or risky spec, a contract that does not fit the code, a bug that blocks the
  slice. Everything else (a better name, a cleanup, a nearby bug) waits for the `SUGGESTIONS`
  line of its final report, batched.
- **Judge it on evidence.** A file and line, an error, a failing test or a measured cost counts.
  "I would prefer" or "might be cleaner" does not. Check a claim that matters with `git diff` or
  `grep` before acting on it.
- **Answer every `SUGGEST` once, in one line:** `ACCEPT <the change>` (update the spec and the
  ledger, and relay the delta to every worker it touches) or `REJECT <reason>`. A mid-run
  suggestion exists because it affects the worker, so it should not be left hanging. A message
  that asks nothing of you gets no reply, and there are no acknowledgements from either side.
- **Scope stays yours.** Accept what fixes the slice within its files. Anything that adds files,
  dependencies, refactors or features is not done in this run: put it in the final report to the
  user as a follow-up.
- **A decision is final.** The worker complies and does not reopen it. It may reopen once with
  new evidence; the second answer is final too. A security or data-loss concern gets a real look,
  and if the risk is the user's to accept, ask the user instead of overruling or ignoring it.
- Architecture points are yours, with a one-line reason. If a critique shows the spec was wrong,
  fix the spec and send the delta to every affected worker.
