pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.containers
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

                ColumnLayout {
                    id: edit

                    required property var modelData
                    property bool open

                    Layout.fillWidth: true
                    Layout.leftMargin: 16
                    spacing: 2

                    Item {
                        Layout.fillWidth: true
                        implicitHeight: editRow.implicitHeight

                        RowLayout {
                            id: editRow

                            anchors.fill: parent
                            spacing: Tokens.spacing.small

                            MaterialIcon {
                                text: edit.open ? "expand_more" : "chevron_right"
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

                        StateLayer {
                            onClicked: edit.open = !edit.open
                        }
                    }

                    StyledRect {
                        Layout.fillWidth: true
                        visible: edit.open && edit.modelData.lines.length > 0
                        implicitHeight: Math.min(diff.implicitHeight, 180) + Tokens.padding.small * 2
                        radius: Tokens.rounding.small
                        color: Colours.tPalette.m3surfaceContainerHigh
                        clip: true

                        StyledFlickable {
                            anchors.fill: parent
                            anchors.margins: Tokens.padding.small
                            contentHeight: diff.implicitHeight
                            contentWidth: width

                            Column {
                                id: diff

                                width: parent.width

                                Repeater {
                                    model: edit.modelData.lines

                                    StyledText {
                                        required property string modelData

                                        width: diff.width
                                        elide: Text.ElideRight
                                        text: modelData
                                        color: modelData[0] === "+" ? Colours.palette.m3tertiary : modelData[0] === "-" ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
                                        font: Tokens.font.mono.small
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
