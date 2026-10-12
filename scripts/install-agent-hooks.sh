#!/usr/bin/env bash
# Wires coding agents to the shell's AgentSessions socket. See install-agent-hooks.py.
exec python3 "$(dirname "$0")/install-agent-hooks.py" "$@"
