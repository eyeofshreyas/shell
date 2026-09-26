pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config

Singleton {
    id: root

    readonly property bool enabled: GlobalConfig.services.aiCliUsage.enabled && GlobalConfig.services.aiCliUsage.repoPath.length > 0

    // null when the CLI isn't detected/available, otherwise
    // { percentLeft: real, reset: string, weeklyPercentLeft: real|null, weeklyReset: string|null, status: string }
    property var codex: null
    property real lastFetched: 0

    function extractProvider(providers: var, name: string): var {
        const entry = providers.find(p => p.provider === name);
        if (!entry || !entry.available || !entry.usage?.primary)
            return null;
        return {
            percentLeft: entry.usage.primary.percent_left ?? 100,
            reset: entry.usage.primary.reset ?? "",
            weeklyPercentLeft: entry.usage.weekly?.percent_left ?? null,
            weeklyReset: entry.usage.weekly?.reset ?? "",
            status: entry.status ?? ""
        };
    }

    function fetch(): void {
        if (!enabled)
            return;
        fetchProc.running = true;
    }

    Process {
        id: fetchProc

        command: [GlobalConfig.services.aiCliUsage.nodeCommand, `${GlobalConfig.services.aiCliUsage.repoPath}/backend/index.js`, "snapshot", GlobalConfig.services.aiCliUsage.repoPath]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    const providers = data.providers ?? [];
                    root.codex = root.extractProvider(providers, "codex");
                    root.lastFetched = Date.now();
                } catch (e) {
                    console.warn(lc, `failed to parse ai-usage-widget output: ${e}`);
                }
            }
        }
    }

    // Periodic refresh
    Timer {
        interval: GlobalConfig.services.aiCliUsage.refreshInterval * 1000
        running: root.enabled
        repeat: true
        onTriggered: root.fetch()
    }

    // Initial fetch
    Component.onCompleted: fetch()

    LoggingCategory {
        id: lc

        name: "caelestia.qml.services.aiCliUsage"
        defaultLogLevel: LoggingCategory.Info
    }
}
