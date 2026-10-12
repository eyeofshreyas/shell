import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services

ColumnLayout {
    id: root

    readonly property var week: AgentSessions.recap(7)
    readonly property var cells: [
        {
            label: Tr.tr("Sessions"),
            value: week.sessions
        },
        {
            label: Tr.tr("Files"),
            value: week.files
        },
        {
            label: Tr.tr("Lines"),
            value: `+${week.add} −${week.del}`
        },
        {
            label: Tr.tr("Commands"),
            value: week.commands
        },
        {
            label: Tr.tr("Permissions"),
            value: week.permissions
        },
        {
            label: Tr.tr("Longest"),
            value: week.longest > 0 ? Tr.tr("%1 min").arg(Math.max(1, Math.round(week.longest / 60000))) : "–"
        }
    ]

    spacing: Tokens.spacing.small

    StyledText {
        Layout.fillWidth: true
        text: Tr.tr("Last 7 days")
        color: Colours.palette.m3onSurfaceVariant
        font: Tokens.font.body.builders.small.scale(0.9).build()
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 3
        columnSpacing: Tokens.spacing.small
        rowSpacing: Tokens.spacing.small

        Repeater {
            model: root.cells

            StyledRect {
                id: cell

                required property var modelData

                Layout.fillWidth: true
                implicitHeight: col.implicitHeight + Tokens.padding.small * 2
                radius: Tokens.rounding.small
                color: Colours.tPalette.m3surfaceContainerHigh

                ColumnLayout {
                    id: col

                    anchors.centerIn: parent
                    spacing: 0

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: cell.modelData.value
                        font: Tokens.font.body.builders.medium.weight(Font.DemiBold).build()
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: cell.modelData.label
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.builders.small.scale(0.85).build()
                    }
                }
            }
        }
    }

    StyledText {
        Layout.fillWidth: true
        elide: Text.ElideRight
        visible: root.week.sessions > 0
        text: Tr.tr("Top agent %1 · top project %2 · busiest %3").arg(root.week.topAgent).arg(root.week.topProject || "–").arg(root.week.busiestDay)
        color: Colours.palette.m3onSurfaceVariant
        font: Tokens.font.body.builders.small.scale(0.85).build()
    }

    StyledText {
        Layout.fillWidth: true
        visible: root.week.sessions === 0
        wrapMode: Text.Wrap
        text: Tr.tr("Nothing yet. Stats start counting from the first agent session; they stay on this machine.")
        color: Colours.palette.m3onSurfaceVariant
        font: Tokens.font.body.builders.small.scale(0.9).build()
    }
}
