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

    required property var def
    property bool open
    property bool manualEdit
    readonly property var view: Integrations.results[def.id] ?? ({})
    readonly property bool configured: Integrations.configured(def.id)
    readonly property bool editing: manualEdit || !configured
    readonly property bool failing: configured && (view.error?.length ?? 0) > 0
    readonly property string summary: {
        if (!configured)
            return Tr.tr("Add key");
        if (failing)
            return Tr.tr("Error");
        if (!view.fetched)
            return Tr.tr("Loading…");
        if (view.headline?.length > 0)
            return view.headlineSub ? `${view.headline} ${view.headlineSub}` : view.headline;
        return (view.rows?.length ?? 0) > 0 ? Tr.tr("%1 recent").arg(view.rows.length) : Tr.tr("Nothing yet");
    }

    signal toggled

    function save(): void {
        Integrations.setKey(def.id, keyField.text, urlField.text);
        keyField.text = "";
        urlField.text = "";
        manualEdit = false;
    }

    spacing: 2
    onOpenChanged: {
        if (!open)
            manualEdit = false;
    }

    Item {
        Layout.fillWidth: true
        implicitHeight: header.implicitHeight + Tokens.padding.small * 2

        RowLayout {
            id: header

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Tokens.spacing.small

            Rectangle {
                implicitWidth: 8
                implicitHeight: 8
                radius: 4
                color: root.configured ? root.def.colour : Colours.palette.m3outline
            }

            StyledText {
                text: root.def.name
                font: Tokens.font.body.builders.small.weight(Font.Medium).build()
            }

            StyledText {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: root.def.kind
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.builders.small.scale(0.85).build()
            }

            StyledText {
                text: root.summary
                color: root.failing ? Colours.palette.m3error : root.configured ? Colours.palette.m3onSurface : Colours.palette.m3outline
                font: Tokens.font.body.builders.small.scale(0.9).build()
            }

            MaterialIcon {
                text: root.open ? "expand_more" : "chevron_right"
                color: Colours.palette.m3outline
                fontStyle: Tokens.font.icon.small
            }
        }

        StateLayer {
            onClicked: root.toggled()
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 16
        visible: root.open
        spacing: Tokens.spacing.small

        RowLayout {
            Layout.fillWidth: true
            visible: root.configured
            spacing: Tokens.spacing.small

            Item {
                Layout.fillWidth: true
            }

            IconButton {
                visible: !root.editing
                icon: "refresh"
                type: IconButton.Text
                onClicked: Integrations.refresh(root.def.id)
            }

            IconButton {
                visible: root.def.open.length > 0
                icon: "open_in_new"
                type: IconButton.Text
                onClicked: Quickshell.execDetached(["xdg-open", root.def.open])
            }

            IconButton {
                icon: "key"
                type: IconButton.Text
                checked: root.manualEdit
                onClicked: root.manualEdit = !root.manualEdit
            }
        }

        StyledText {
            Layout.fillWidth: true
            visible: root.failing && !root.editing
            wrapMode: Text.Wrap
            text: root.view.error ?? ""
            color: Colours.palette.m3error
            font: Tokens.font.body.builders.small.scale(0.9).build()
        }

        ColumnLayout {
            Layout.fillWidth: true
            visible: root.editing
            spacing: Tokens.spacing.small

            StyledText {
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                text: root.def.hint
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.builders.small.scale(0.9).build()
            }

            StyledTextField {
                id: urlField

                Layout.fillWidth: true
                visible: root.def.needsUrl ?? false
                placeholderText: Tr.tr("Server URL, e.g. http://localhost:5678")
                onAccepted: keyField.forceActiveFocus()
            }

            StyledTextField {
                id: keyField

                Layout.fillWidth: true
                echoMode: TextInput.Password
                placeholderText: root.configured ? Tr.tr("New key (replaces the saved one)") : Tr.tr("Paste key")
                onAccepted: root.save()
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                Item {
                    Layout.fillWidth: true
                }

                TextButton {
                    visible: root.configured
                    text: Tr.tr("Remove key")
                    type: TextButton.Text
                    onClicked: {
                        Integrations.removeKey(root.def.id);
                        root.manualEdit = false;
                    }
                }

                TextButton {
                    text: Tr.tr("Save")
                    type: TextButton.Filled
                    disabled: keyField.text.trim().length === 0 || ((root.def.needsUrl ?? false) && urlField.text.trim().length === 0)
                    onClicked: root.save()
                }
            }
        }

        Repeater {
            model: ScriptModel {
                values: root.configured && !root.editing && !root.failing ? (root.view.rows ?? []) : []
            }

            Item {
                id: row

                required property var modelData

                Layout.fillWidth: true
                implicitHeight: rowLayout.implicitHeight + Tokens.padding.small

                RowLayout {
                    id: rowLayout

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Tokens.spacing.small

                    Rectangle {
                        implicitWidth: 6
                        implicitHeight: 6
                        radius: 3
                        color: row.modelData.dot
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            text: row.modelData.title
                            font: Tokens.font.body.small
                        }

                        StyledText {
                            Layout.fillWidth: true
                            visible: text.length > 0
                            elide: Text.ElideRight
                            text: row.modelData.sub
                            color: Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.body.builders.small.scale(0.85).build()
                        }
                    }

                    StyledText {
                        text: row.modelData.right
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.mono.small
                    }
                }

                StateLayer {
                    disabled: row.modelData.url.length === 0
                    onClicked: Quickshell.execDetached(["xdg-open", row.modelData.url])
                }
            }
        }
    }
}
