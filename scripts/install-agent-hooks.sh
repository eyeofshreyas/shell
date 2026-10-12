#!/usr/bin/env bash
# Wires Claude Code hook events to the shell's AgentSessions socket (Bit mascot).
# Safe to re-run: other hooks are kept, ours (including the old nc-based ones) are replaced.
# Usage: scripts/install-agent-hooks.sh [--remove]
set -euo pipefail

settings="${CLAUDE_SETTINGS:-$HOME/.claude/settings.json}"
relay="$(cd "$(dirname "$0")" && pwd)/agent-hook.py"
marker_re='caelestia-agents\.sock|agent-hook\.py'
cmd="python3 '$relay'"
events=(SessionStart UserPromptSubmit PreToolUse PostToolUse PostToolUseFailure Notification PermissionRequest Stop SessionEnd)

command -v jq >/dev/null || { echo "jq is required" >&2; exit 1; }
command -v python3 >/dev/null || { echo "python3 is required" >&2; exit 1; }

mkdir -p "$(dirname "$settings")"
[ -f "$settings" ] || echo '{}' > "$settings"
cp "$settings" "$settings.bak-agents"

if [ "${1:-}" = "--remove" ]; then
    jq --arg m "$marker_re" '
        if .hooks then
            .hooks |= (map_values(map(select(([.hooks[]?.command // ""] | any(test($m))) | not))) | with_entries(select(.value | length > 0)))
            | if (.hooks | length) == 0 then del(.hooks) else . end
        else . end' "$settings.bak-agents" > "$settings"
    echo "Removed Bit hooks from $settings"
    exit 0
fi

tmp="$(mktemp)"
cp "$settings" "$tmp"
for ev in "${events[@]}"; do
    # PermissionRequest blocks while the card waits for a click; the relay gives up after 118s
    jq --arg ev "$ev" --arg cmd "$cmd" --arg m "$marker_re" --argjson t "$([ "$ev" = PermissionRequest ] && echo 120 || echo 5)" '
        .hooks //= {}
        | .hooks[$ev] = ((.hooks[$ev] // []) | map(select(([.hooks[]?.command // ""] | any(test($m))) | not)))
        | .hooks[$ev] += [{hooks: [{type: "command", command: $cmd, timeout: $t}]}]' "$tmp" > "$tmp.n"
    mv "$tmp.n" "$tmp"
done
mv "$tmp" "$settings"
echo "Installed Bit hooks into $settings (backup: $settings.bak-agents)"
echo "Restart running Claude Code sessions (or open /hooks) to pick them up."
