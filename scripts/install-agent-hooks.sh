#!/usr/bin/env bash
# Wires Claude Code hook events to the shell's AgentSessions socket (Bit mascot).
# Safe to re-run: existing hooks are kept, ours are added only if missing.
# Usage: scripts/install-agent-hooks.sh [--remove]
set -euo pipefail

settings="${CLAUDE_SETTINGS:-$HOME/.claude/settings.json}"
marker="caelestia-agents.sock"
cmd='nc -UN "${XDG_RUNTIME_DIR:-/run/user/$UID}/caelestia-agents.sock" 2>/dev/null || true'
events=(SessionStart UserPromptSubmit PreToolUse PostToolUse PostToolUseFailure Notification Stop SessionEnd)

command -v jq >/dev/null || { echo "jq is required" >&2; exit 1; }
command -v nc >/dev/null || echo "warning: nc (openbsd-netcat) not found; hooks will do nothing until it is installed" >&2

mkdir -p "$(dirname "$settings")"
[ -f "$settings" ] || echo '{}' > "$settings"
cp "$settings" "$settings.bak-agents"

if [ "${1:-}" = "--remove" ]; then
    jq --arg m "$marker" '
        if .hooks then
            .hooks |= (map_values(map(select(([.hooks[]?.command] | any(contains($m))) | not))) | with_entries(select(.value | length > 0)))
            | if (.hooks | length) == 0 then del(.hooks) else . end
        else . end' "$settings.bak-agents" > "$settings"
    echo "Removed Bit hooks from $settings"
    exit 0
fi

tmp="$(mktemp)"
cp "$settings" "$tmp"
for ev in "${events[@]}"; do
    jq --arg ev "$ev" --arg cmd "$cmd" --arg m "$marker" '
        .hooks //= {}
        | .hooks[$ev] //= []
        | if (.hooks[$ev] | any(.hooks[]?.command | contains($m))) then .
          else .hooks[$ev] += [{hooks: [{type: "command", command: $cmd}]}] end' "$tmp" > "$tmp.n"
    mv "$tmp.n" "$tmp"
done
mv "$tmp" "$settings"
echo "Installed Bit hooks into $settings (backup: $settings.bak-agents)"
echo "Restart running Claude Code sessions (or open /hooks) to pick them up."
