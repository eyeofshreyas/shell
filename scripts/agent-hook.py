#!/usr/bin/env python3
"""Relays an agent's hook event (JSON on stdin) to the shell's AgentSessions socket.

Usage: agent-hook.py [--agent NAME]

Events are fire-and-forget, except PermissionRequest: it waits for the person to
click Allow / Deny / Always (or answer a question) in the dashboard. With no click,
no shell or a timeout it prints nothing, so the agent asks in its own terminal as
if this relay were not installed. Nothing that allows anything is ever printed
without a decision a human made.
"""
import json
import os
import socket
import sys

SOCKET = os.path.join(os.environ.get("XDG_RUNTIME_DIR") or f"/run/user/{os.getuid()}", "caelestia-agents.sock")
# Gemini CLI event names -> the Claude Code names the shell understands
EVENTS = {"BeforeAgent": "UserPromptSubmit", "AfterAgent": "Stop", "BeforeTool": "PreToolUse", "AfterTool": "PostToolUse"}
WAIT = 118  # Claude Code's hook timeout is raised to 120 by the installer


def reply_json(decision, payload):
    """The documented PermissionRequest output, or None for anything unrecognised."""
    kind = decision.get("decision")
    out = None
    if kind in ("allow", "always"):
        out = {"behavior": "allow"}
        if kind == "always" and payload.get("permission_suggestions"):
            out["updatedPermissions"] = payload["permission_suggestions"]
    elif kind == "deny":
        out = {"behavior": "deny", "message": "Denied from the Caelestia dashboard"}
    elif kind == "answer" and isinstance(decision.get("answers"), dict):
        questions = (payload.get("tool_input") or {}).get("questions")
        if questions:
            out = {"behavior": "allow", "updatedInput": {"questions": questions, "answers": decision["answers"]}}
    if out is None:
        return None
    return json.dumps({"hookSpecificOutput": {"hookEventName": "PermissionRequest", "decision": out}})


def main():
    args = sys.argv[1:]
    agent = args[args.index("--agent") + 1] if "--agent" in args and args.index("--agent") + 1 < len(args) else ""
    try:
        payload = json.load(sys.stdin)
    except ValueError:
        return

    payload["hook_event_name"] = EVENTS.get(payload.get("hook_event_name"), payload.get("hook_event_name"))
    payload["agent"] = agent
    payload["pid"] = os.getppid()
    line = (json.dumps(payload) + "\n").encode()

    try:
        s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        if payload["hook_event_name"] != "PermissionRequest":
            s.settimeout(0.3)
            s.connect(SOCKET)
            s.sendall(line)
            return
        s.settimeout(WAIT)
        s.connect(SOCKET)
        s.sendall(line)
        buf = b""
        while b"\n" not in buf:
            chunk = s.recv(4096)
            if not chunk:
                break
            buf += chunk
        out = reply_json(json.loads(buf.decode()), payload) if buf.strip() else None
        if out:
            print(out, flush=True)
    except (OSError, ValueError):
        pass


if __name__ == "__main__":
    main()
