#!/usr/bin/env python3
"""Relays an agent's hook event (JSON on stdin) to the shell's AgentSessions socket.

Usage: agent-hook.py [--agent NAME] [EventName]

NAME tags the agent (none = Claude Code); EventName is for agents that don't put
the event in their payload. Events are fire-and-forget, except PermissionRequest
from an agent whose answers the dashboard can give: it waits for a click on
Allow / Deny / Always (or an answered question). With no click, no shell or a
timeout it prints nothing, so the agent asks in its own terminal as if this relay
were not installed. Nothing that allows anything is ever printed without a
decision a human made.
"""
import json
import os
import socket
import sys

SOCKET = os.path.join(os.environ.get("XDG_RUNTIME_DIR") or f"/run/user/{os.getuid()}", "caelestia-agents.sock")
WAIT = 118  # the installers raise the agents' hook timeout to 120

EVENTS = {
    "BeforeTool": "PreToolUse", "BeforeToolSelection": "PreToolUse", "AfterTool": "PostToolUse",
    "AfterModel": "PostToolUse", "BeforeAgent": "UserPromptSubmit", "AfterAgent": "Stop",
    "startup": "SessionStart", "exit": "SessionEnd", "PreInvocation": "UserPromptSubmit",
    "PostInvocation": "PostToolUse", "pre_tool_use": "PreToolUse", "post_tool_use": "PostToolUse",
    "user_prompt_submit": "UserPromptSubmit", "session_start": "SessionStart", "session_end": "SessionEnd",
    "stop": "Stop", "sessionStart": "SessionStart", "userPromptSubmitted": "UserPromptSubmit",
    "agentStop": "Stop", "notification": "Notification", "preToolUse": "PreToolUse",
    "postToolUse": "PostToolUse", "permissionRequest": "PermissionRequest", "sessionEnd": "SessionEnd",
    "beforeSubmitPrompt": "UserPromptSubmit", "postToolUseFailure": "PostToolUseFailure",
    "subagentStart": "SubagentStart", "subagentStop": "SubagentStop",
}
ARG_ALIASES = {"CommandLine": "command", "FilePath": "file_path", "Path": "path", "Url": "url", "Query": "query", "Pattern": "pattern"}
TAKES_DECISIONS = ("", "codex", "copilot", "muse")
WANTS_JSON = ("gemini", "antigravity", "copilot", "muse")


def first_str(d, *keys):
    return next((d[k] for k in keys if isinstance(d.get(k), str) and d[k]), None)


def normalize(p):
    """Maps each agent's field names onto Claude Code's."""
    call = p["toolCall"] if isinstance(p.get("toolCall"), dict) else {}
    if "tool_name" not in p and (name := first_str(p, "toolName", "tool") or first_str(call, "name")):
        p["tool_name"] = name
    if "tool_input" not in p:
        args = p.get("toolArgs")
        if isinstance(args, str):
            try:
                args = json.loads(args)
            except ValueError:
                args = None
        if not isinstance(args, dict) and isinstance(call.get("args"), dict):
            args = dict(call["args"])
            for src, dst in ARG_ALIASES.items():
                if src in args:
                    args[dst] = args[src]
        if isinstance(args, dict):
            p["tool_input"] = args
    if not p.get("session_id"):
        sid = first_str(p, "conversationId", "conversation_id", "sessionId") or os.environ.get("GEMINI_SESSION_ID")
        if sid:
            p["session_id"] = sid
    if not p.get("cwd"):
        roots = next((p[k] for k in ("workspacePaths", "workspace_roots") if isinstance(p.get(k), list) and p[k]), [])
        p["cwd"] = first_str(p, "workdir") or (roots[0] if roots and isinstance(roots[0], str) else os.getcwd())


def answers_fit(tool_input, answers):
    """True when answers answers exactly the questions asked, with offered labels."""
    questions = (tool_input or {}).get("questions")
    if not questions or len(questions) != len(answers):
        return False
    for q in questions:
        labels = [o.get("label") for o in q.get("options", [])]
        pick = answers.get(q.get("question"))
        if q.get("multiSelect"):
            if not (isinstance(pick, list) and pick and len(set(pick)) == len(pick) and all(x in labels for x in pick)):
                return False
        elif pick not in labels or not isinstance(pick, str):
            return False
    return True


def reply(agent, event, decision, payload):
    """The line to print back to the agent, or None for silence."""
    if event != "PermissionRequest":
        if agent == "antigravity" and event == "PreToolUse":
            return '{"decision":"ask"}'  # "{}" reads as a denial there; this keeps its own prompt
        return "{}" if agent in WANTS_JSON else None
    kind = decision.get("decision") if agent in TAKES_DECISIONS and isinstance(decision, dict) else None
    if agent in ("copilot", "muse"):
        word = {"allow": "allow", "always": "allow", "deny": "deny"}.get(kind)
        if word is None and agent == "copilot":
            word = "ask"  # Copilot is fail-closed: silence would deny
        return json.dumps({"permissionDecision": word}) if word else None
    out = None
    if kind in ("allow", "always"):
        out = {"behavior": "allow"}
        if kind == "always" and agent == "" and payload.get("permission_suggestions"):
            out["updatedPermissions"] = payload["permission_suggestions"]
    elif kind == "deny":
        out = {"behavior": "deny", "message": "Denied from the Caelestia dashboard"}
    elif kind == "answer" and agent == "" and isinstance(decision.get("answers"), dict):
        inp = payload.get("tool_input")
        if payload.get("tool_name") == "AskUserQuestion" and answers_fit(inp, decision["answers"]):
            out = {"behavior": "allow", "updatedInput": {**inp, "answers": decision["answers"]}}
    if out is None:
        return None
    return json.dumps({"hookSpecificOutput": {"hookEventName": "PermissionRequest", "decision": out}})


def main():
    args = sys.argv[1:]
    agent = ""
    if "--agent" in args and args.index("--agent") + 1 < len(args):
        agent = args[args.index("--agent") + 1]
    positional = [a for i, a in enumerate(args) if not a.startswith("--") and (i == 0 or args[i - 1] != "--agent")]

    try:
        payload = json.load(sys.stdin)
        assert isinstance(payload, dict)
    except (ValueError, AssertionError):
        if line := reply(agent, EVENTS.get(positional[0], positional[0]) if positional else "", None, {}):
            print(line)
        return

    raw = payload.get("hook_event_name") or (positional[0] if positional else "")
    event = EVENTS.get(raw, raw)
    if event == "Stop" and payload.get("status") == "error":
        event = "StopFailure"
    normalize(payload)
    payload.update(hook_event_name=event, agent=agent or payload.get("agent", ""), pid=os.getppid())
    data = (json.dumps(payload) + "\n").encode()

    decision = None
    waits = event == "PermissionRequest" and agent in TAKES_DECISIONS
    try:
        s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        s.settimeout(WAIT if waits else 0.3)
        s.connect(SOCKET)
        s.sendall(data)
        if waits:
            buf = b""
            while b"\n" not in buf:
                chunk = s.recv(4096)
                if not chunk:
                    break
                buf += chunk
            decision = json.loads(buf.decode()) if buf.strip() else None
    except (OSError, ValueError):
        pass
    if line := reply(agent, event, decision, payload):
        print(line, flush=True)


if __name__ == "__main__":
    main()
