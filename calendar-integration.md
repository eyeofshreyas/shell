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

Build the branch and run a throwaway second `qs` instance rather than
restarting your actual daily shell:

```bash
cd /path/to/this/repo
cmake -B build -G Ninja -DVERSION= -DGIT_REVISION=
cmake --build build

QML2_IMPORT_PATH="$PWD/build/qml:$QML2_IMPORT_PATH" qs -p . -n &

# Open the dashboard on that instance specifically:
qs -p . ipc call drawers toggle dashboard
# (same command toggles it closed again)

# When done:
pkill -f "qs -p $PWD"
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
