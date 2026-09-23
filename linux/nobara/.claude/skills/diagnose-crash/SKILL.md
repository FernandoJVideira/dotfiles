---
name: diagnose-crash
description: >
  Diagnose why a program crashed on this Nobara (Fedora) machine, from a
  systemd-coredump core dump or from the logs. Use when a process has
  segfaulted, aborted, or dumped core, when asked why an application crashed
  or disappeared, or when the desktop dropped back to the SDDM login screen
  (Hyprland crash) or the bar/widgets vanished (Quickshell/end4-pC crash).
  Triggers: crash, segfault, SIGSEGV, SIGABRT, core dump, coredumpctl,
  "why did X crash", "X keeps crashing", "got kicked to login", backtrace
  symbolization.
---

# Diagnosing a Crash (Nobara / Fedora)

Work from evidence. The goal is an honest account of what happened, not a
plausible-sounding story. Adapted from Omarchy's diagnose-crash skill for
this machine (Fedora base, dnf, systemd-coredump, Hyprland + end4-pC).

## Establish the facts

`coredumpctl info <pid>` is the starting point (`coredumpctl list` to find the
pid). Beyond the backtrace, note the **command line** the process was started
with - it usually reveals what the program was working on when it died.

`coredumpctl list` also shows whether this is a one-off or a pattern. Repeated
crashes of the same program, or several programs dying together, point
somewhere different than a single failure does.

## Rule out the boring causes first

Check resource exhaustion before blaming the program: `free -h`, and
`journalctl -k -b | grep -i -E "oom|out of memory"`. A process killed by the
OOM killer is not a bug in that process. This laptop has an NVIDIA GTX 1050 Ti
plus Intel iGPU, so also check `journalctl -b -p err | grep -i -E "nvidia|drm|gpu"`
for GPU resets around the crash time - compositor crashes are often driver-side.

## Correlate against the timeline

The crash timestamp is the most underused piece of evidence. Compare it with:

- **The journal** around that moment (`journalctl --since ... --until ...`),
  for warnings from the same or neighbouring processes.
- **Recent package changes.** `dnf history list` (dnf5) shows recent
  transactions; a crash that starts right after an update points at the update.
  Note the third-party sources here: Terra, RPM Fusion, the COPRs
  illogical-impulse enabled (Hyprland comes from sdegler/hyprland), and
  prebuilt RPMs it downloads from its own GitHub releases (quickshell-git,
  matugen) - none of these are stock Fedora.
- **Filesystem mtimes** of config files - a config edited the second before the
  crash strongly suggests the trigger (`~/.config/hypr/custom/*.lua`,
  `~/.config/illogical-impulse/config.json`, `~/.config/quickshell/end4-pC`).

## This desktop's usual suspects

- **Hyprland crashed** (session dropped to SDDM): look for its own crash
  report, typically `~/.cache/hyprland/hyprlandCrashReport*.txt` (check that it
  exists before relying on it), plus `coredumpctl info Hyprland`. Recent
  edits to `~/.config/hypr/custom/*.lua` are the first suspect - a Lua error
  there can break the whole config load.
- **Quickshell / end4-pC crashed** (bar and widgets gone, compositor fine):
  run it in the foreground to see the real error instead of the silenced one -
  `killall qs; qs -c end4-pC` - QML binding errors and missing files print
  there. "Could not find "end4-pC" config directory" means
  `~/.config/quickshell/end4-pC` is missing or Quickshell isn't finding it.
- **Lots of visual weirdness but no crash**: Quickshell may have fallen back to
  illogical-impulse's default `ii` config because end4-pC wasn't found.
- **Claude Code sidebar model** (`services/ai/ClaudeCodeApiStrategy.qml`)
  failing silently: run `claude -p hi --verbose --output-format stream-json`
  by hand; errors that aren't JSON are swallowed by the UI.

## Read the whole core, not just frame 0

Thread stacks other than the crashing one show what work was **in flight**
(thumbnailers, image loaders, IPC readers, GPU queues). That context often
explains the trigger even when the crashing frame itself cannot be symbolized.
Note any third-party code in the address space (plugins, out-of-tree drivers,
the NVIDIA userspace) - worth flagging, but do not pin blame on it without
evidence that it is actually implicated.

## Symbolize when you can

Fedora runs a public debuginfod server. `gdb` may not be installed - if it
isn't, say so and offer `sudo dnf install gdb`; don't install it unprompted.

```bash
core=$(mktemp -t crash-XXXXXX.core)
trap 'rm -f "$core"' EXIT
coredumpctl dump <pid> --output="$core"
DEBUGINFOD_URLS="https://debuginfod.fedoraproject.org" \
  gdb -q <executable> "$core" \
  -batch -ex 'set debuginfod enabled on' -ex 'bt'
```

A core is a verbatim copy of the process's memory and can hold passwords,
tokens, and private documents (this machine runs a Proton Pass SSH agent).
Write it to a fresh `mktemp` path, never a predictable shared one, and delete
it when you are done.

Debug symbols are unavailable for many third-party packages (Hyprland from
a COPR, quickshell-git from illogical-impulse's own prebuilt RPMs - Fedora's
debuginfod serves neither). When frames
stay unresolved, say so - never invent function names. An unsymbolized stack
still has shape: which library each frame belongs to, and whether the crash
came from a signal handler, a main loop, or a worker thread.

## Report

1. What crashed, and what it was doing at the time.
2. The most likely mechanism - separating clearly what the evidence **proves**
   from what you are **inferring**.
3. Whether any user data was lost, and where it can be recovered from.
4. Whether it is likely to recur, and what would avoid or fix it.

Be straight about the limits of the evidence. If the cause is ambiguous, say so
rather than assembling confidence out of guesswork.

**Leave the system as you found it.** Diagnosis reads; it does not fix, tidy,
or reconfigure. The one thing to clean up is your own: delete the core you
extracted.

## If it looks like an upstream bug

Most crashes are bugs in the applications, not in this setup. Where the
evidence points upstream, route it correctly:

- **Hyprland**: hyprwm/Hyprland issues, attaching the crash report file.
- **illogical-impulse (base config/installer)**: its maintainers explicitly ask
  for GitHub *Discussions* (category "Extra Distros" for Fedora), not issues.
- **end4-pC**: the user's fork (FernandoJVideira/end4-pC) or upstream
  pctrade/end4-pC, depending on whether the bug is in our Claude Code changes.

Offer to draft the report; never file anything unprompted.
