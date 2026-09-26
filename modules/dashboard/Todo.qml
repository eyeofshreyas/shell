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

Item {
    id: root

    implicitWidth: 480
    implicitHeight: Math.min(layout.implicitHeight, 480)

    function submit(): void {
        Todos.add(input.text);
        input.text = "";
    }

    ColumnLayout {
        id: layout

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: Tokens.padding.large
        anchors.rightMargin: Tokens.padding.large
        spacing: Tokens.spacing.medium

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            StyledTextField {
                id: input

                Layout.fillWidth: true
                placeholderText: Tr.tr("Add a task...")
                onAccepted: root.submit()
            }

            IconButton {
                icon: "add"
                type: IconButton.Filled
                onClicked: root.submit()
            }
        }

        StyledText {
            Layout.topMargin: Tokens.spacing.large
            Layout.alignment: Qt.AlignHCenter
            visible: list.count === 0
            text: Tr.tr("No tasks yet")
            color: Colours.palette.m3onSurfaceVariant
        }

        VerticalFadeListView {
            id: list

            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(contentHeight, 360)
            visible: count > 0
            spacing: Tokens.spacing.small
            model: ScriptModel {
                values: Todos.items
            }

            delegate: TodoRow {}
        }
    }

    component TodoRow: StyledRect {
        id: row

        required property var modelData

        width: ListView.view.width
        implicitHeight: rowLayout.implicitHeight + Tokens.padding.medium * 2

        radius: Tokens.rounding.large
        color: Colours.tPalette.m3surfaceContainer

        RowLayout {
            id: rowLayout

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Tokens.padding.medium
            anchors.rightMargin: Tokens.padding.medium
            spacing: Tokens.spacing.medium

            IconButton {
                icon: row.modelData.done ? "check_circle" : "radio_button_unchecked"
                type: IconButton.Text
                isToggle: true
                checked: row.modelData.done
                onClicked: Todos.toggle(row.modelData.id)
            }

            StyledText {
                Layout.fillWidth: true
                text: row.modelData.text
                wrapMode: Text.Wrap
                font.strikeout: row.modelData.done
                color: row.modelData.done ? Colours.palette.m3onSurfaceVariant : Colours.palette.m3onSurface
            }

            IconButton {
                icon: "delete"
                type: IconButton.Text
                onClicked: Todos.remove(row.modelData.id)
            }
        }
    }
}
