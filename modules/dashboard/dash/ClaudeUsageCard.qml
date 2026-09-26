pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services

Item {
    id: root

    readonly property real lastFetched: Math.max(ClaudeUsage.lastFetched, AiCliUsage.lastFetched)
    readonly property bool claudeUnavailable: ClaudeUsage.enabled && ClaudeUsage.rateLimitError.length > 0
    property real now: Date.now()

    implicitWidth: layout.implicitWidth + Tokens.padding.large * 2
    implicitHeight: layout.implicitHeight + Tokens.padding.large * 2

    function formatAgo(ms: real): string {
        const mins = Math.max(0, Math.floor(ms / 60000));
        if (mins < 1)
            return Tr.tr("just now");
        if (mins < 60)
            return Tr.tr("%1m ago").arg(mins);
        return Tr.tr("%1h ago").arg(Math.floor(mins / 60));
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: root.now = Date.now()
    }

    ColumnLayout {
        id: layout

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.small

        RowLayout {
            Layout.fillWidth: true

            StyledText {
                Layout.fillWidth: true
                text: Tr.tr("AI usage")
                color: Colours.palette.m3primary
                font: Tokens.font.body.builders.small.weight(Font.DemiBold).build()
            }

            StyledText {
                visible: ClaudeUsage.enabled
                text: Tr.tr("Today: $%1").arg(ClaudeUsage.todayCost.toFixed(2))
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.builders.small.scale(0.85).build()
            }
        }

        UsageRow {
            Layout.fillWidth: true
            visible: ClaudeUsage.enabled && !root.claudeUnavailable
            label: Tr.tr("Claude session (5h)")
            percentUsed: ClaudeUsage.sessionUtilization * 100
            fgColour: Colours.palette.m3primary
            resetText: {
                const r = ClaudeUsage.formatReset(ClaudeUsage.sessionReset);
                return r ? Tr.tr("Resets in %1").arg(r) : "";
            }
        }

        UsageRow {
            Layout.fillWidth: true
            visible: ClaudeUsage.enabled && !root.claudeUnavailable
            label: Tr.tr("Claude weekly")
            percentUsed: ClaudeUsage.weeklyUtilization * 100
            fgColour: Colours.palette.m3tertiary
            resetText: {
                const r = ClaudeUsage.formatReset(ClaudeUsage.weeklyReset);
                return r ? Tr.tr("Resets in %1").arg(r) : "";
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            visible: root.claudeUnavailable
            spacing: 2

            StyledText {
                Layout.fillWidth: true
                text: Tr.tr("Claude usage unavailable")
                color: Colours.palette.m3error
                font: Tokens.font.body.builders.small.weight(Font.DemiBold).build()
            }

            StyledText {
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                text: ClaudeUsage.rateLimitError
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.builders.small.scale(0.8).build()
            }
        }

        UsageRow {
            Layout.fillWidth: true
            visible: AiCliUsage.codex !== null
            label: Tr.tr("Codex (5h)")
            percentUsed: 100 - (AiCliUsage.codex?.percentLeft ?? 100)
            fgColour: Colours.palette.m3secondary
            resetText: AiCliUsage.codex?.reset ? Tr.tr("Resets %1").arg(AiCliUsage.codex.reset) : ""
        }

        UsageRow {
            Layout.fillWidth: true
            visible: AiCliUsage.codex !== null && AiCliUsage.codex.weeklyPercentLeft !== null
            label: Tr.tr("Codex weekly")
            percentUsed: 100 - (AiCliUsage.codex?.weeklyPercentLeft ?? 100)
            fgColour: Colours.palette.m3outline
            resetText: AiCliUsage.codex?.weeklyReset ? Tr.tr("Resets %1").arg(AiCliUsage.codex.weeklyReset) : ""
        }

        StyledText {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.extraSmall
            horizontalAlignment: Text.AlignHCenter
            visible: root.lastFetched > 0
            text: Tr.tr("Updated %1").arg(root.formatAgo(root.now - root.lastFetched))
            color: Colours.palette.m3outline
            font: Tokens.font.body.builders.small.scale(0.75).build()
        }
    }

    component UsageRow: ColumnLayout {
        id: urow

        required property string label
        required property real percentUsed
        property string resetText: ""
        property color fgColour: Colours.palette.m3primary

        spacing: Tokens.spacing.extraSmall

        RowLayout {
            Layout.fillWidth: true

            StyledText {
                Layout.fillWidth: true
                text: urow.label
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.builders.small.build()
            }

            StyledText {
                text: `${Math.round(urow.percentUsed)}%`
                color: urow.fgColour
                font: Tokens.font.body.builders.small.weight(Font.DemiBold).build()
            }
        }

        StyledProgressBar {
            Layout.fillWidth: true
            implicitHeight: Tokens.padding.small
            value: urow.percentUsed / 100
            fgColour: urow.fgColour
        }

        StyledText {
            visible: text.length > 0
            text: urow.resetText
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.body.builders.small.scale(0.8).build()
        }
    }
}
