# Session handoff: porting the Coucou features into the shell

Branch: `developer` only (`main` mirrors upstream). Do not commit or push unless asked; ask before each commit.
Reference clone: https://github.com/eyeofshreyas/coucou.git (MIT code; a notch companion app). Previously cloned to
`/tmp/claude-1000/.../scratchpad/coucou` (gone if /tmp was cleared; re-clone). Interesting folders: `windows/src/mochi/`,
`windows/src/views/` (chat, diff, github, integrations, recap, spotify, ticker, upload, usage, wardrobe), `windows/src/recap/`.

Rules: our mascot is **Bit**. Do not copy Mochi's art/sounds or the "Coucou"/"Mochi" names (MIT covers code only).
Skipped by agreement: phone apps, App Store, macOS-only features.
Safety rule: nothing that allows anything is printed without a decision a human clicked.

## Done (committed)
| Commit | What |
|---|---|
| d5a48440 | dev-run fix for blank screen on boot |
| 45ea96d9 | AI usage card: approve from shell, multi-agent tab, edit ticker, jump to terminal |
| 423ac9f3 | Group 1: more agents (Codex/Gemini/Copilot/Muse/Cursor/Antigravity/OpenCode/Amp installers), expandable diffs, weekly recap (Week tab) |
| 2db98703 | Group 2: Bit outfits/wardrobe, desktop Bit, file drop, sounds, shortcuts, Ask tab |
| 3a1a50d2 | Group 3: Services sub-tab (GitHub, Vercel, n8n, Notion, Resend; Stripe/Cal.com left for later, see coucou integrations.rs). Live API calls untested (no keys): check XHR headers, GitHub User-Agent |

AI usage card tabs: 0 Usage, 1 Agents, 2 Week, 3 Ask, 4 Services (permission requests/questions; auto-switches and returns). Default `tab: 0`.

## To do
1. **Group 4: Chat + voice** (written, awaiting commit; 4a chat verified visually, 4b voice verified up to transcription):
   - 4a: provider switcher (Claude/Gemini/OpenAI/Ollama/...) next to the model switcher in the AI chat (`modules/aichat/AiChat.qml`,
     `services/Ai.qml` `providers`/`setProvider`, new `services/ai/AnthropicApiStrategy.qml`, test `node scripts/test_anthropic.mjs`).
     The chat panel was already broken on HEAD (old `Appearance.*` API, `Tokens` read inside `PropertyChanges`, missing `Colours` import); fixed here.
     Keys go in the chat's own key flow (keyring `apiKeys.anthropic` / `apiKeys.openai`). Live Claude/OpenAI requests are untested (no keys). Provider dropdown not clicked in a test.
   - 4b: "OK Bit" is push-to-talk (the original wake word is macOS-only): bind `caelestia:bitListen` in Hyprland; press to record (pw-record),
     press again to transcribe with `whisper-cli` (whisper.cpp) using the model at `~/.local/share/caelestia/whisper-model.bin`, then the text is sent to the AI chat
     (`services/Voice.qml`). Not installed here: whisper-cli, so the transcribe->chat step is untested. No spoken replies (no TTS installed).
2. Optional small follow-up: Bit's seasonal outfit (`services/Bit.qml`, `seasonal`) is only evaluated at shell start;
   make it re-check daily. Auto dates: Oct 20 - Nov 1 pumpkin, Dec 15-26 santa, Dec 31 - Jan 2 party.

## Not yet tested
- Desktop Bit (needs an empty workspace), file drop on the card, sound playback (`pw-play`), wardrobe chip clicks.
- Bit shortcuts: user must bind `caelestia:bitAllow`, `caelestia:bitDeny`, `caelestia:bitJump`, `caelestia:bitListen` in the Hyprland config.
- Jump-to-terminal with a real terminal; real installs for copilot/muse/cursor/antigravity/opencode/amp
  (only claude/codex/gemini exist on the real home; the rest tested in a fake HOME); Codex needs `/hooks` trust;
  running Claude sessions need a restart to pick up hooks.

## Untracked, leave alone
`modules/session/Content.qml.backup`, `plugin/src/Caelestia/I18n/trs/`

## Dev workflow notes
- Run: `dev-run.sh` (entr auto-restart). Reload by `touch modules/dashboard/dash/ClaudeUsageCard.qml`, wait ~25s,
  poll `qs ipc --pid $(pgrep -x quickshell) call drawers list` for readiness. Restart resets in-memory state.
- Open dashboard: `qs ipc --pid $(pgrep -x quickshell) call drawers toggle dashboard` (toggle only; opens on the focused
  monitor: eDP-1 x=0, HDMI-A-1 x=1920, both 1920x1080; `grim` full capture is 3840x1080; skipped if a window is fullscreen).
- Don't use ydotool absolute mouse for UI clicks. Never `pkill -f agent-hook.py` from a command containing that string.
- Lint: `python3 scripts/qml-lint-conventions.py --file <path>` (one file at a time; `Mascot.qml` has a pre-existing 54-violation baseline).
  Translations: `python3 scripts/trs-check.py` (128 pre-existing errors elsewhere; keep it at 128). `Tr.tr()` needs literal strings.
- QML conventions: order = id, properties, signals, functions, bindings, children, components. StateLayer inside layouts
  needs a wrapping Item. ScriptModel needs `import Quickshell`. Persistence pattern: FileView + Timer under `${Paths.data}`
  (= `~/.local/share/caelestia`). Services in `services/` are in module `qs.services`.
- Test data in `~/.local/share/caelestia` (`bit.json`, `agent-stats.json`) can be deleted to reset.
- Key files: `services/AgentSessions.qml`, `services/Bit.qml`, `scripts/agent-hook.py`, `scripts/install-agent-hooks.py`,
  `modules/dashboard/dash/ClaudeUsageCard.qml`, `AgentSessionsTab.qml`, `AgentRecapTab.qml`, `AgentApproval.qml`,
  `Mascot.qml`, `BitMascot.qml`, `MascotOutfit.qml`, `modules/background/DesktopBit.qml`.
