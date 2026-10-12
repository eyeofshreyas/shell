import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services

StyledRect {
    id: root

    required property var approval
    // { questionText: label | [labels] } for AskUserQuestion
    property var picks: ({})
    readonly property bool isQuestion: approval.questions.length > 0
    readonly property bool lone: approval.questions.length === 1 && !approval.questions[0].multiSelect
    readonly property bool complete: approval.questions.every(q => (picks[q.question]?.length ?? 0) > 0)

    function pick(q: var, label: string): void {
        const next = Object.assign({}, picks);
        if (q.multiSelect) {
            const cur = next[q.question] ?? [];
            next[q.question] = cur.includes(label) ? cur.filter(l => l !== label) : [...cur, label];
        } else {
            next[q.question] = label;
        }
        picks = next;
        if (lone)
            AgentSessions.decide(approval.id, "answer", picks);
    }

    implicitHeight: content.implicitHeight + Tokens.padding.medium * 2
    radius: Tokens.rounding.medium
    color: Colours.palette.m3errorContainer

    ColumnLayout {
        id: content

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: Tokens.padding.medium
        spacing: Tokens.spacing.small

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            MaterialIcon {
                text: root.isQuestion ? "help" : "shield"
                color: Colours.palette.m3onErrorContainer
                fill: 1
            }

            StyledText {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: `${root.approval.agent || Tr.tr("Claude")} · ${root.approval.project}`
                color: Colours.palette.m3onErrorContainer
                font: Tokens.font.body.builders.small.weight(Font.DemiBold).build()
            }

            StyledText {
                text: root.isQuestion ? Tr.tr("question") : root.approval.tool
                color: Colours.palette.m3onErrorContainer
                font: Tokens.font.body.builders.small.scale(0.85).build()
            }
        }

        StyledText {
            Layout.fillWidth: true
            visible: !root.isQuestion
            wrapMode: Text.Wrap
            maximumLineCount: 3
            elide: Text.ElideRight
            text: root.approval.summary
            color: Colours.palette.m3onErrorContainer
            font: Tokens.font.mono.small
        }

        Repeater {
            model: root.approval.questions

            ColumnLayout {
                id: question

                required property var modelData

                Layout.fillWidth: true
                spacing: Tokens.spacing.extraSmall

                StyledText {
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    text: question.modelData.question
                    color: Colours.palette.m3onErrorContainer
                    font: Tokens.font.body.builders.small.weight(Font.Medium).build()
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small

                    Repeater {
                        model: question.modelData.options

                        Chip {
                            id: option

                            required property var modelData

                            label: modelData.label
                            current: {
                                const p = root.picks[question.modelData.question];
                                return Array.isArray(p) ? p.includes(modelData.label) : p === modelData.label;
                            }
                            onClicked: root.pick(question.modelData, modelData.label)
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            Item {
                Layout.fillWidth: true
            }

            TextButton {
                text: Tr.tr("Reply in terminal")
                type: TextButton.Text
                inactiveOnColour: Colours.palette.m3onErrorContainer
                onClicked: AgentSessions.decide(root.approval.id, "ask", {})
            }

            TextButton {
                visible: !root.isQuestion
                text: Tr.tr("Deny")
                type: TextButton.Text
                inactiveOnColour: Colours.palette.m3onErrorContainer
                onClicked: AgentSessions.decide(root.approval.id, "deny", {})
            }

            TextButton {
                visible: !root.isQuestion && root.approval.hasSuggestions
                text: Tr.tr("Always")
                type: TextButton.Tonal
                onClicked: AgentSessions.decide(root.approval.id, "always", {})
            }

            TextButton {
                visible: !root.isQuestion
                text: Tr.tr("Allow")
                type: TextButton.Filled
                onClicked: AgentSessions.decide(root.approval.id, "allow", {})
            }

            TextButton {
                visible: root.isQuestion && !root.lone
                text: Tr.tr("Send")
                type: TextButton.Filled
                disabled: !root.complete
                onClicked: AgentSessions.decide(root.approval.id, "answer", root.picks)
            }
        }
    }
}
