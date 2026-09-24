# Google Calendar integration

Shows your Google Calendar events on the dashboard: a dot on calendar days
that have events, an "Upcoming" row listing events coming up, and desktop
reminders before an event starts.

Ported from [PR #1275](https://github.com/caelestia-dots/shell/pull/1275)
onto the current C++ config architecture. Disabled by default — it does
nothing until you enable it and install the `gws` CLI it depends on.

## Prerequisites

- The [`gws`](https://github.com/googleworkspace/cli) CLI (Google Workspace
  CLI) available in `PATH`, authenticated with calendar access.

### Install gws

Pick one:

```bash
npm install -g @googleworkspace/cli        # needs a user-writable npm prefix
cargo install --git https://github.com/googleworkspace/cli --locked
nix run github:googleworkspace/cli
brew install googleworkspace-cli
```

Or download a prebuilt binary from the
[releases page](https://github.com/googleworkspace/cli/releases) and put it
in `~/.local/bin` (or anywhere on `PATH`).

### Authenticate gws

```bash
gws auth setup   # requires the gcloud CLI
```

If you don't have `gcloud` (it's AUR-only on Arch), set up OAuth manually
instead:

1. Create/open a project at <https://console.cloud.google.com/>.
2. **APIs & Services → OAuth consent screen** → type **External**, testing
   mode is fine.
3. **Test users** → add your own Google account email. Skipping this makes
   login fail with a generic "Access blocked" error.
4. **APIs & Services → Library** → enable **Google Calendar API**.
5. **APIs & Services → Credentials → Create Credentials → OAuth client ID**
   → type **Desktop app** → download the JSON.
6. Save it to `~/.config/gws/client_secret.json`.
7. Run:
   ```bash
   gws auth login
   ```
   This prints a URL to open and approve in your browser.

Verify it works before touching the shell config:

```bash
gws calendar +agenda
```

This should print your real events as JSON. If it errors, fix that first —
the shell will just silently do nothing if `gws` isn't working.

## Enabling it

Add to `~/.config/caelestia/shell.json`:

```json
{
    "services": {
        "calendar": {
            "enabled": true,
            "command": "gws",
            "agendaDays": 30,
            "upcomingHours": 24,
            "reminderMinutes": 10,
            "refreshInterval": 900
        }
    }
}
```

| Option | Default | Description |
|---|---|---|
| `enabled` | `false` | Master toggle. Requires `gws` in `PATH`. |
| `command` | `"gws"` | Path or name of the gws binary. |
| `agendaDays` | `30` | How many days ahead to fetch events. |
| `upcomingHours` | `24` | Hours ahead to show in the dashboard's "Upcoming" row. |
| `reminderMinutes` | `10` | Minutes before an event to send a desktop notification. `0` disables reminders. |
| `refreshInterval` | `900` | Seconds between background refreshes. |

Events are cached to `~/.local/state/caelestia/gcalendar.json` so they show
instantly on shell restart, then refresh in the background.

## Testing without touching your live shell

Running a second full `qs` instance against your real config/state
duplicates the `Bar` (shrinks your tiled window area — both bars reserve
exclusive screen space) and the `Background` (can turn your wallpaper
black — only one process can usually decode a video wallpaper at a time).
Both are avoidable with an isolated config, so the test instance never
touches your real `~/.config/caelestia`, `~/.local/state/caelestia`, or
`~/.cache/caelestia` at all:

```bash
cd /path/to/this/repo
cmake -B build -G Ninja -DVERSION= -DGIT_REVISION=
cmake --build build

# Isolated XDG dirs, just for this test instance
export XDG_CONFIG_HOME=/tmp/caelestia-test/config
export XDG_STATE_HOME=/tmp/caelestia-test/state
export XDG_CACHE_HOME=/tmp/caelestia-test/cache
mkdir -p "$XDG_CONFIG_HOME/caelestia" "$XDG_STATE_HOME/caelestia"

cat > "$XDG_CONFIG_HOME/caelestia/shell.json" <<'JSON'
{
    "background": { "wallpaperEnabled": false },
    "border": { "thickness": 0 },
    "bar": { "excludedScreens": ["^.*$"] },
    "services": {
        "calendar": {
            "enabled": true,
            "command": "gws",
            "agendaDays": 30,
            "upcomingHours": 720,
            "reminderMinutes": 10,
            "refreshInterval": 900
        }
    }
}
JSON

# Carry over your real Material You palette so the test instance isn't
# themed with fallback colours (read-only copy, one-time, not synced back)
cp ~/.local/state/caelestia/scheme.json "$XDG_STATE_HOME/caelestia/scheme.json"

# Launch via a script rather than inline `VAR=val qs ... &` — env vars on an
# inline background launch can silently fail to reach the process depending
# on your shell; a script makes sure `qs` actually sees them.
cat > /tmp/caelestia-test/launch.sh <<EOF
#!/bin/bash
export XDG_CONFIG_HOME="$XDG_CONFIG_HOME"
export XDG_STATE_HOME="$XDG_STATE_HOME"
export XDG_CACHE_HOME="$XDG_CACHE_HOME"
export QML2_IMPORT_PATH="$PWD/build/qml:\$QML2_IMPORT_PATH"
cd "$PWD"
exec qs -p . -n
EOF
chmod +x /tmp/caelestia-test/launch.sh
/tmp/caelestia-test/launch.sh &

# Open the dashboard on that instance specifically:
XDG_CONFIG_HOME="$XDG_CONFIG_HOME" XDG_STATE_HOME="$XDG_STATE_HOME" XDG_CACHE_HOME="$XDG_CACHE_HOME" \
  qs -p . ipc call drawers toggle dashboard
# (same command toggles it closed again)
```

> [!IMPORTANT]
> `excludedScreens` entries are only treated as regex if wrapped in
> `^...$` — anything else is compared as an exact string match against
> the screen name. `[".*"]` silently never matches anything; it has to be
> `["^.*$"]`. `border.thickness: 0` matters too: even with the bar
> disabled, every screen unconditionally reserves `border.thickness`
> exclusive space on all four edges (that's a property of `Drawers`
> itself, not the bar) — zeroing it in this isolated config is what makes
> the reserved area come out identical to your baseline (verified with
> `hyprctl monitors -j`, `.reserved` field, before vs. after).

`background.wallpaperEnabled: false` skips the wallpaper renderer
entirely (no decode contention, no black overlay — Dashboard/Calendar are
unaffected by this). Copying `scheme.json` gives the test instance your
real generated colour palette instead of a fallback theme. None of this
touches your real config/state since `XDG_CONFIG_HOME`/`XDG_STATE_HOME`
are overridden just for this process's environment.

When done, find and kill the test instance specifically (don't use
`pkill` by command line — it can match more than you expect):

```bash
qs list --all              # find the instance whose Config path is this repo
qs kill --pid <pid>        # or: qs kill --id <instance id>
```

Scroll the calendar with the mouse wheel to change month and see the event
dots; the "Upcoming" row appears below the calendar if anything falls
within `upcomingHours`.

## What's not included

This port covers only the dashboard calendar-dot indicator and "Upcoming"
row (PR #1275's first commit). The PR's final version also added a
separate sidebar upcoming-events widget with independent hour configs
(`dashUpcomingHours` / `sidebarUpcomingHours`, `dashboard.showUpcoming`,
`sidebar.showUpcoming`) from a later commit — that part hasn't been
ported.

## Troubleshooting

- **Nothing shows up**: check `enabled: true` is set and `gws` is on
  `PATH` for the shell process (not just your shell's `PATH` — Quickshell
  may have a different environment depending on how it's launched).
- **No dots/Upcoming row even though `gws` works standalone**: your events
  may be outside the `upcomingHours` window, or in a different month than
  the one currently shown.
- **`gws` errors about auth**: re-run `gws calendar +agenda` directly to
  debug — it's independent of the shell integration.
