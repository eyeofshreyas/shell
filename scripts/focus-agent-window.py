#!/usr/bin/env python3
"""Focuses the Hyprland window whose process is an ancestor of the given pid.

Usage: focus-agent-window.py PID
Walks up the process tree from the agent to the terminal that owns it. Exits 1
when no ancestor owns a window (e.g. a terminal multiplexer server in between).
"""
import json
import subprocess
import sys


def parent(pid):
    try:
        with open(f"/proc/{pid}/stat") as f:
            return int(f.read().rsplit(")", 1)[1].split()[1])
    except (OSError, ValueError, IndexError):
        return 0


def main():
    pid = int(sys.argv[1])
    windows = {c["pid"] for c in json.loads(subprocess.check_output(["hyprctl", "clients", "-j"]))}
    while pid > 1:
        if pid in windows:
            subprocess.run(["hyprctl", "dispatch", f"hl.dsp.focus({{ window = 'pid:{pid}' }})"], check=True)
            return 0
        pid = parent(pid)
    return 1


if __name__ == "__main__":
    sys.exit(main())
