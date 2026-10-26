#!/usr/bin/env python3
"""Watch a git repo while sub-agents edit it, and print one line per thing the coordinator
should react to. Meant to run under the Monitor tool: each stdout line is a notification, and
every notification costs the coordinator tokens, so this stays quiet on purpose.

    python3 -I watch-slices.py <repo> <slices-file> [--interval 30] [--idle 300]
                               [--max-events 20] [--give-up 900]

<slices-file> has one slice per line: a name, then the repo-relative files or folders that
slice's worker may change, separated by spaces. Blank lines and lines starting with # are
skipped. Example:

    members-api   internal/members  migrations/0042_last_seen.sql
    members-ui    app/pages/members  app/components/members

Only changes made after the watcher starts count; files that were already dirty are ignored
until they change again. Lines printed (each at most once per cause):

    OUT-OF-SCOPE <path>       a change that no slice is allowed to make (once per path)
    OVERLAP <path> <a> <b>    a change inside two slices at once (once per path)
    IDLE <slice> <seconds>    no file in the slice changed for that long (once per quiet
                              spell; a hint, not proof: the worker may be reading or thinking)
    ACTIVE <slice> <path>     the slice changed again after an IDLE line

It exits by itself, with a STOPPING line, after --max-events event lines (a flood means the
filter is wrong or something is looping) or when nothing in any slice has changed for
--give-up seconds. Routine in-scope edits print nothing.

Stdlib only; read-only: it runs `git status` and hashes files, and never edits anything.
"""
import argparse
import hashlib
import os
import subprocess
import sys
import time


def changed(repo):
    out = subprocess.run(
        ["git", "-C", repo, "status", "--porcelain", "-z", "--untracked-files=all"],
        capture_output=True, check=True,
    ).stdout.decode("utf-8", "surrogateescape")
    paths, parts = [], out.split("\0")
    i = 0
    while i < len(parts):
        entry = parts[i]
        i += 1
        if len(entry) < 4:
            continue
        paths.append(entry[3:])
        if entry[0] in "RC":  # rename/copy: the next field is the old path
            i += 1
    return paths


def signature(repo, path):
    try:
        with open(os.path.join(repo, path), "rb") as f:
            return hashlib.sha1(f.read()).hexdigest()
    except OSError:
        return "gone"


def snapshot(repo):
    return {p: signature(repo, p) for p in changed(repo)}


def load_slices(path):
    slices = {}
    with open(path, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            name, *owned = line.split()
            slices[name] = [o.rstrip("/") for o in owned]
    return slices


def owners(slices, path):
    return [
        name for name, owned in slices.items()
        if any(path == o or path.startswith(o + "/") for o in owned)
    ]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("repo")
    ap.add_argument("slices")
    ap.add_argument("--interval", type=float, default=30)
    ap.add_argument("--idle", type=float, default=300)
    ap.add_argument("--max-events", type=int, default=20)
    ap.add_argument("--give-up", type=float, default=900)
    args = ap.parse_args()

    repo = os.path.abspath(args.repo)
    slices = load_slices(args.slices)
    seen = snapshot(repo)
    now = time.time()
    last_change = {name: now for name in slices}
    idle_flagged = {name: False for name in slices}
    reported = set()  # ("oos"|"overlap", path): each reported once
    last_any = now
    events = 0

    def emit(line):
        nonlocal events
        print(line, flush=True)
        events += 1
        if events >= args.max_events:
            print(f"STOPPING event limit ({args.max_events}) reached", flush=True)
            sys.exit(0)

    print(f"WATCHING {len(slices)} slices in {repo}", flush=True)

    while True:
        time.sleep(args.interval)
        now = time.time()
        try:
            current = snapshot(repo)
        except subprocess.CalledProcessError as e:
            print(f"ERROR git status failed: {e.stderr.decode().strip()}", flush=True)
            sys.exit(1)
        for path, sig in sorted(current.items()):
            if seen.get(path) == sig:
                continue
            seen[path] = sig
            last_any = now
            hit = owners(slices, path)
            if not hit:
                if ("oos", path) not in reported:
                    reported.add(("oos", path))
                    emit(f"OUT-OF-SCOPE {path}")
            elif len(hit) > 1:
                if ("overlap", path) not in reported:
                    reported.add(("overlap", path))
                    emit(f"OVERLAP {path} {' '.join(hit)}")
            else:
                name = hit[0]
                last_change[name] = now
                if idle_flagged[name]:
                    idle_flagged[name] = False
                    emit(f"ACTIVE {name} {path}")
        for name in slices:
            quiet = now - last_change[name]
            if quiet >= args.idle and not idle_flagged[name]:
                idle_flagged[name] = True
                emit(f"IDLE {name} {int(quiet)}")
        if now - last_any >= args.give_up:
            print(f"STOPPING no change in any slice for {int(now - last_any)}s", flush=True)
            sys.exit(0)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        sys.exit(0)
