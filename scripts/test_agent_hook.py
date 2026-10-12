#!/usr/bin/env python3
"""Self-check for agent-hook.py: python3 scripts/test_agent_hook.py"""
import importlib.util
import json
import os

spec = importlib.util.spec_from_file_location("hook", os.path.join(os.path.dirname(__file__), "agent-hook.py"))
h = importlib.util.module_from_spec(spec)
spec.loader.exec_module(h)

p = {"toolCall": {"name": "run_command", "args": {"CommandLine": "ls"}}, "conversationId": "c1", "workspacePaths": ["/w"]}
h.normalize(p)
assert (p["tool_name"], p["tool_input"]["command"], p["session_id"], p["cwd"]) == ("run_command", "ls", "c1", "/w")
p = {"toolName": "bash", "toolArgs": '{"command":"npm test"}', "sessionId": "s", "workdir": "/a"}
h.normalize(p)
assert (p["tool_input"]["command"], p["session_id"], p["cwd"]) == ("npm test", "s", "/a")

claude = {"permission_suggestions": [{"type": "addRules"}], "tool_name": "Bash"}
allow = lambda a, d, pl=claude: json.loads(h.reply(a, "PermissionRequest", {"decision": d}, pl) or "null")
assert allow("", "allow")["hookSpecificOutput"]["decision"] == {"behavior": "allow"}
assert "updatedPermissions" in allow("", "always")["hookSpecificOutput"]["decision"]
assert "updatedPermissions" not in allow("codex", "always")["hookSpecificOutput"]["decision"]
assert h.reply("", "PermissionRequest", None, claude) is None  # no click -> silence
assert h.reply("", "PermissionRequest", {"decision": "ask"}, claude) is None
assert h.reply("gemini", "PermissionRequest", {"decision": "allow"}, claude) is None  # never allowed for others
assert json.loads(h.reply("copilot", "PermissionRequest", None, claude)) == {"permissionDecision": "ask"}
assert json.loads(h.reply("muse", "PermissionRequest", {"decision": "deny"}, claude)) == {"permissionDecision": "deny"}
assert h.reply("antigravity", "PreToolUse", None, {}) == '{"decision":"ask"}'
assert h.reply("", "Stop", None, {}) is None

q = {"tool_name": "AskUserQuestion", "tool_input": {"questions": [{"question": "Q?", "options": [{"label": "A"}, {"label": "B"}]}]}}
good = h.reply("", "PermissionRequest", {"decision": "answer", "answers": {"Q?": "A"}}, q)
assert json.loads(good)["hookSpecificOutput"]["decision"]["updatedInput"]["answers"] == {"Q?": "A"}
assert h.reply("", "PermissionRequest", {"decision": "answer", "answers": {"Q?": "Z"}}, q) is None
assert h.reply("", "PermissionRequest", {"decision": "answer", "answers": {"Q?": "A", "x": "y"}}, q) is None
print("ok")
