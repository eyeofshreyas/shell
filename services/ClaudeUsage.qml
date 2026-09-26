pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config

Singleton {
    id: root

    readonly property bool enabled: GlobalConfig.services.claudeUsage.enabled

    property real sessionUtilization: 0
    property int sessionReset: 0
    property real weeklyUtilization: 0
    property int weeklyReset: 0
    property real todayCost: 0
    property real weekCost: 0
    property string rateLimitError: ""
    property real lastFetched: 0

    function formatReset(unixSeconds: int): string {
        if (!unixSeconds)
            return "";
        const diff = unixSeconds * 1000 - Date.now();
        if (diff <= 0)
            return "";
        const days = Math.floor(diff / 86400000);
        const hours = Math.floor((diff % 86400000) / 3600000);
        const minutes = Math.floor((diff % 3600000) / 60000);
        if (days > 0)
            return `${days}d ${hours}h`;
        return hours > 0 ? `${hours}h ${minutes}m` : `${minutes}m`;
    }

    function fetch(): void {
        if (!enabled)
            return;
        fetchProc.running = true;
    }

    Process {
        id: fetchProc

        command: [GlobalConfig.services.claudeUsage.command, "--once", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    root.sessionUtilization = data.session_utilization ?? 0;
                    root.sessionReset = data.session_reset ?? 0;
                    root.weeklyUtilization = data.weekly_utilization ?? 0;
                    root.weeklyReset = data.weekly_reset ?? 0;
                    root.todayCost = data.today_cost ?? 0;
                    root.weekCost = data.week_cost ?? 0;
                    root.rateLimitError = data.rate_limit_error ?? "";
                    root.lastFetched = Date.now();
                } catch (e) {
                    console.warn(lc, `failed to parse claude-usage output: ${e}`);
                }
            }
        }
    }

    // Periodic refresh
    Timer {
        interval: GlobalConfig.services.claudeUsage.refreshInterval * 1000
        running: root.enabled
        repeat: true
        onTriggered: root.fetch()
    }

    // Initial fetch
    Component.onCompleted: fetch()

    LoggingCategory {
        id: lc

        name: "caelestia.qml.services.claudeusage"
        defaultLogLevel: LoggingCategory.Info
    }
}
