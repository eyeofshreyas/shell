pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services

Item {
    id: root

    readonly property real lastFetched: Math.max(ClaudeUsage.lastFetched, AiCliUsage.lastFetched)
    // claude-usage falls back to last-known values on a rate-limited/failed API call
    // (rate_limit_error is non-fatal), so only treat it as truly unavailable when we've
    // never had a successful fetch to fall back on.
    readonly property bool claudeUnavailable: ClaudeUsage.enabled && ClaudeUsage.rateLimitError.length > 0 && ClaudeUsage.lastFetched === 0
    readonly property bool claudeStale: ClaudeUsage.enabled && ClaudeUsage.rateLimitError.length > 0 && ClaudeUsage.lastFetched > 0
    property real now: Date.now()
    property int tab: 0
    property int tabBeforeAsk: 0
    property bool wardrobe: false
    readonly property int pending: AgentSessions.approvals.length

    function formatAgo(ms: real): string {
        const mins = Math.max(0, Math.floor(ms / 60000));
        if (mins < 1)
            return Tr.tr("just now");
        if (mins < 60)
            return Tr.tr("%1m ago").arg(mins);
        return Tr.tr("%1h ago").arg(Math.floor(mins / 60));
    }

    implicitWidth: layout.implicitWidth + Tokens.padding.large * 2
    implicitHeight: layout.implicitHeight + Tokens.padding.large * 2

    // A permission request or question gets its own tab, and the card returns to where it was afterwards
    onPendingChanged: {
        if (pending > 0 && tab !== 3) {
            tabBeforeAsk = tab;
            tab = 3;
        } else if (pending === 0 && tab === 3) {
            tab = tabBeforeAsk;
        }
    }

    HoverHandler {
        id: cardHover
    }

    // Drop a file on the card to ask the AI chat about it
    DropArea {
        anchors.fill: parent
        onDropped: drop => {
            if (!drop.hasUrls)
                return;
            Ai.attachFile(drop.urls[0].toString());
            Ai.sendUserMessage(Tr.tr("What is this file? Summarise it."));
            const screenState = ShellState.forActive();
            screenState.dashboard = false;
            screenState.aiChat = true;
        }
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

            BitMascot {
                id: mascot

                Layout.preferredWidth: implicitWidth
                Layout.preferredHeight: implicitHeight
                pointer: cardHover.hovered ? mapFromItem(root, cardHover.point.position) : Qt.point(NaN, NaN)
                onSecondaryClicked: root.wardrobe = !root.wardrobe
            }

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

        Flow {
            Layout.fillWidth: true
            visible: root.wardrobe
            spacing: Tokens.spacing.small

            Repeater {
                model: [
                    {
                        id: "auto",
                        label: Tr.tr("Auto")
                    },
                    {
                        id: "none",
                        label: Tr.tr("Bare")
                    },
                    {
                        id: "cap",
                        label: Tr.tr("Cap")
                    },
                    {
                        id: "bow",
                        label: Tr.tr("Bow")
                    },
                    {
                        id: "shades",
                        label: Tr.tr("Shades")
                    },
                    {
                        id: "crown",
                        label: Tr.tr("Crown")
                    },
                    {
                        id: "pumpkin",
                        label: Tr.tr("Pumpkin")
                    },
                    {
                        id: "santa",
                        label: Tr.tr("Santa")
                    },
                    {
                        id: "party",
                        label: Tr.tr("Party")
                    },
                    {
                        id: "wizard",
                        label: Tr.tr("Wizard")
                    },
                    {
                        id: "catears",
                        label: Tr.tr("Cat")
                    },
                    {
                        id: "halo",
                        label: Tr.tr("Halo")
                    },
                    {
                        id: "headphones",
                        label: Tr.tr("Phones")
                    },
                    {
                        id: "tophat",
                        label: Tr.tr("Top hat")
                    },
                    {
                        id: "flower",
                        label: Tr.tr("Flower")
                    }
                ]

                Chip {
                    required property var modelData

                    label: modelData.label
                    current: Bit.outfitPref === modelData.id
                    onClicked: Bit.setOutfit(modelData.id)
                }
            }

            Chip {
                label: Tr.tr("On desktop")
                current: Bit.desktop
                onClicked: Bit.setDesktop(!Bit.desktop)
            }

            Chip {
                label: Tr.tr("Walk")
                current: Bit.walk
                onClicked: Bit.setWalk(!Bit.walk)
            }

            Chip {
                label: Tr.tr("Talk")
                current: Bit.talk
                onClicked: Bit.setTalk(!Bit.talk)
            }

            Chip {
                label: Tr.tr("Remind")
                current: Bit.remind
                onClicked: Bit.setRemind(!Bit.remind)
            }

            Chip {
                label: Tr.tr("Sounds")
                current: Bit.sounds
                onClicked: Bit.setSounds(!Bit.sounds)
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            Chip {
                visible: root.pending > 0
                label: Tr.tr("Ask")
                current: root.tab === 3
                badge: root.pending
                onClicked: root.tab = 3
            }

            Chip {
                label: Tr.tr("Usage")
                current: root.tab === 0
                onClicked: root.tab = 0
            }

            Chip {
                label: Tr.tr("Agents")
                current: root.tab === 1
                badge: AgentSessions.sessions.length
                onClicked: root.tab = 1
            }

            Chip {
                label: Tr.tr("Week")
                current: root.tab === 2
                onClicked: root.tab = 2
            }

            Chip {
                label: Tr.tr("Services")
                current: root.tab === 4
                onClicked: root.tab = 4
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            visible: root.tab === 3
            spacing: Tokens.spacing.small

            Repeater {
                model: ScriptModel {
                    values: AgentSessions.approvals
                }

                AgentApproval {
                    required property var modelData

                    Layout.fillWidth: true
                    approval: modelData
                }
            }
        }

        AgentSessionsTab {
            Layout.fillWidth: true
            visible: root.tab === 1
        }

        AgentRecapTab {
            Layout.fillWidth: true
            visible: root.tab === 2
        }

        ServicesTab {
            Layout.fillWidth: true
            visible: root.tab === 4
        }

        ColumnLayout {
            Layout.fillWidth: true
            visible: root.tab === 0
            spacing: Tokens.spacing.small

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
                label: AiCliUsage.codex?.period === "monthly" ? Tr.tr("Codex (monthly)") : Tr.tr("Codex (5h)")
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
                text: root.claudeStale ? Tr.tr("Updated %1 (rate limited, last known)").arg(root.formatAgo(root.now - root.lastFetched)) : Tr.tr("Updated %1").arg(root.formatAgo(root.now - root.lastFetched))
                color: root.claudeStale ? Colours.palette.m3error : Colours.palette.m3outline
                font: Tokens.font.body.builders.small.scale(0.75).build()
            }
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
