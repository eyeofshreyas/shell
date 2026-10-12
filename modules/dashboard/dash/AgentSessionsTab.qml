pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services

ColumnLayout {
    id: root

    spacing: Tokens.spacing.small

    StyledText {
        Layout.fillWidth: true
        visible: AgentSessions.sessions.length === 0
        wrapMode: Text.Wrap
        text: Tr.tr("No agent sessions yet. Run scripts/install-agent-hooks.sh, then start an agent.")
        color: Colours.palette.m3onSurfaceVariant
        font: Tokens.font.body.builders.small.scale(0.9).build()
    }

    Repeater {
        model: ScriptModel {
            values: AgentSessions.sessions.slice(0, 6)
        }

        ColumnLayout {
            id: session

            required property var modelData
            readonly property color stateColour: modelData.state === "waiting" || modelData.state === "error" ? Colours.palette.m3error : modelData.state === "working" ? Colours.palette.m3primary : Colours.palette.m3outline

            Layout.fillWidth: true
            spacing: 2

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                Rectangle {
                    implicitWidth: 8
                    implicitHeight: 8
                    radius: 4
                    color: session.stateColour
                }

                StyledText {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: session.modelData.agent ? `${session.modelData.project || Tr.tr("Claude")} · ${session.modelData.agent}` : (session.modelData.project || Tr.tr("Claude"))
                    font: Tokens.font.body.builders.small.weight(Font.Medium).build()
                }

                StyledText {
                    text: session.modelData.state === "waiting" ? (session.modelData.tool === "AskUserQuestion" ? Tr.tr("question") : Tr.tr("needs you")) : session.modelData.state === "error" ? Tr.tr("tool failed") : session.modelData.state === "working" ? (session.modelData.tool || Tr.tr("working")) : Tr.tr("idle")
                    color: session.stateColour
                    font: Tokens.font.body.builders.small.scale(0.85).build()
                }

                IconButton {
                    visible: session.modelData.pid > 0
                    icon: "open_in_new"
                    type: IconButton.Text
                    onClicked: AgentSessions.focusTerminal(session.modelData.pid)
                }
            }

            StyledText {
                Layout.fillWidth: true
                Layout.leftMargin: 16
                visible: text.length > 0
                elide: Text.ElideMiddle
                text: session.modelData.detail
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.builders.small.scale(0.85).build()
            }

            Repeater {
                model: ScriptModel {
                    values: session.modelData.edits.slice(0, 3)
                }

                RowLayout {
                    id: edit

                    required property var modelData

                    Layout.fillWidth: true
                    Layout.leftMargin: 16
                    spacing: Tokens.spacing.small

                    MaterialIcon {
                        text: "edit"
                        color: Colours.palette.m3outline
                        fontStyle: Tokens.font.icon.small
                    }

                    StyledText {
                        Layout.fillWidth: true
                        elide: Text.ElideMiddle
                        text: edit.modelData.file
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.mono.small
                    }

                    StyledText {
                        text: `+${edit.modelData.add}`
                        color: Colours.palette.m3tertiary
                        font: Tokens.font.mono.small
                    }

                    StyledText {
                        text: `−${edit.modelData.del}`
                        color: Colours.palette.m3error
                        font: Tokens.font.mono.small
                    }
                }
            }
        }
    }
}
