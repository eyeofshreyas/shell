pragma ComponentBehavior: Bound

import qs.components
import qs.components.containers
import qs.components.controls
import qs.components.effects
import qs.services
import qs.utils
import Caelestia.Config
import Caelestia.I18n
import Caelestia
import Quickshell
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

Item {
    id: root

    anchors.fill: parent

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Compact header
        StyledRect {
            Layout.fillWidth: true
            implicitHeight: headerRow.implicitHeight + Tokens.padding.small * 2

            color: "transparent"

            RowLayout {
                id: headerRow
                anchors.fill: parent
                anchors.margins: Tokens.padding.small
                spacing: Tokens.spacing.medium

                StyledText {
                    text: qsTr("Chat")
                    font.pointSize: Tokens.font.body.large.pointSize
                    font.weight: Font.Medium
                    color: Colours.palette.m3onSurface
                }

                Item { Layout.fillWidth: true }

                // Provider switcher
                SplitButton {
                    id: providerSelector

                    type: SplitButton.Tonal
                    horizontalPadding: Tokens.padding.medium
                    verticalPadding: Tokens.padding.small
                    stateLayer.disabled: true

                    active: menuItems.find(m => m.modelData === Ai.currentProvider) ?? menuItems[0]
                    menuItems: providerVariants.instances
                    fallbackText: Tr.tr("No Provider")

                    menu.onItemSelected: item => Ai.setProvider(item.modelData)

                    Variants {
                        id: providerVariants

                        model: Ai.providers

                        MenuItem {
                            required property string modelData

                            text: Ai.providerNames[modelData] ?? modelData
                        }
                    }
                }

                // Model switcher
                SplitButton {
                    id: modelSelector

                    type: SplitButton.Tonal
                    horizontalPadding: Tokens.padding.medium
                    verticalPadding: Tokens.padding.small
                    stateLayer.disabled: true

                    active: menuItems.find(m => m.modelData === Ai.currentModelId) ?? menuItems[0]
                    menuItems: modelVariants.instances
                    fallbackText: qsTr("No Model")

                    label.Layout.maximumWidth: 160
                    label.elide: Text.ElideRight

                    menu.onItemSelected: item => Ai.setModel(item.modelData)

                    Variants {
                        id: modelVariants

                        model: Ai.modelsOf(Ai.currentProvider)

                        MenuItem {
                            required property string modelData

                            text: Ai.models[modelData].name
                        }
                    }
                }

                IconButton {
                    icon: "settings"
                    type: IconButton.Text
                }
            }
        }

        // Messages area
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            StyledListView {
                id: messageList

                anchors.fill: parent
                anchors.leftMargin: Tokens.padding.large
                anchors.rightMargin: Tokens.padding.large
                anchors.topMargin: Tokens.padding.medium
                anchors.bottomMargin: Tokens.padding.small

                clip: true
                spacing: Tokens.spacing.small

                model: Ai.messageIDs

                delegate: MessageItem {
                    required property int index
                    required property var modelData

                    width: messageList.width
                    messageId: modelData
                }

                onCountChanged: Qt.callLater(() => {
                    messageList.positionViewAtEnd();
                })
            }

            // Empty state
            ColumnLayout {
                anchors.centerIn: parent
                visible: messageList.count === 0
                spacing: Tokens.spacing.small

                MaterialIcon {
                    Layout.alignment: Qt.AlignHCenter
                    text: "chat_bubble_outline"
                    color: Colours.palette.m3outline
                    fontStyle: Tokens.font.icon.extraLarge
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("Start a conversation")
                    color: Colours.palette.m3onSurfaceVariant
                    font.pointSize: Tokens.font.body.medium.pointSize
                }
            }
        }

        // Input area with status
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: inputColumn.height
            Layout.minimumHeight: inputColumn.height
            Layout.topMargin: Tokens.padding.medium

            ColumnLayout {
                id: inputColumn
                width: parent.width
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: Tokens.padding.medium
                spacing: Tokens.spacing.small

                // Compact status bar / inline API key entry
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small
                    visible: !Ai.currentModelHasApiKey

                    MaterialIcon {
                        text: "warning"
                        color: Colours.palette.m3error
                        fontStyle: Tokens.font.icon.small
                    }

                    StyledTextField {
                        id: apiKeyField

                        Layout.fillWidth: true
                        font.pointSize: Tokens.font.body.small.pointSize
                        placeholderText: qsTr("API key required — paste it here")
                        echoMode: TextInput.Password

                        onAccepted: root.saveApiKey()
                    }

                    IconButton {
                        icon: "check"
                        type: IconButton.Text
                        disabled: apiKeyField.text.trim().length === 0
                        onClicked: root.saveApiKey()
                    }
                }

                // Input row
                StyledRect {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48

                    color: Colours.palette.m3surfaceContainerHighest
                    radius: Tokens.rounding.full

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Tokens.padding.large
                        anchors.rightMargin: Tokens.padding.small
                        spacing: Tokens.spacing.small

                        TextInput {
                            id: inputField

                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            color: Colours.palette.m3onSurface
                            font.pointSize: Tokens.font.body.medium.pointSize
                            verticalAlignment: TextInput.AlignVCenter

                            focus: true
                            activeFocusOnTab: true

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                text: qsTr("Message...")
                                color: Colours.palette.m3outline
                                font: inputField.font
                                visible: !inputField.text && !inputField.activeFocus
                            }

                            Keys.onReturnPressed: event => {
                                if (event.modifiers & Qt.ShiftModifier) {
                                    return;
                                }
                                sendMessage();
                                event.accepted = true;
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.IBeamCursor
                                acceptedButtons: Qt.NoButton
                            }
                        }

                        IconButton {
                            Layout.preferredWidth: 40
                            Layout.preferredHeight: 40
                            icon: "send"
                            type: IconButton.Filled
                            disabled: inputField.text.trim().length === 0
                            onClicked: sendMessage()
                        }
                    }
                }
            }
        }
    }

    function sendMessage() {
        const message = inputField.text.trim();
        if (message.length === 0) return;

        Ai.sendUserMessage(message);
        inputField.text = "";
    }

    function saveApiKey() {
        if (apiKeyField.text.trim().length === 0) return;

        Ai.setApiKey(apiKeyField.text);
        apiKeyField.text = "";
    }

    // Message item component
    component MessageItem: Item {
        id: messageItem

        required property string messageId

        // Revision counter to force binding updates
        property int revision: 0

        // Direct property binding to the message object with revision dependency
        readonly property var message: {
            revision;
            return Ai.messageByID[messageItem.messageId];
        }

                // Extract properties with revision dependency to ensure reactivity
        readonly property string messageContent: {
            revision;
            return message?.content ?? "";
        }
        readonly property string messageRole: {
            revision;
            return message?.role ?? "";
        }
        readonly property bool messageThinking: {
            revision;
            return message?.thinking ?? false;
        }
        readonly property bool messageDone: {
            revision;
            return message?.done ?? false;
        }
        readonly property string messageModel: {
            revision;
            return message?.model ?? "";
        }

        function formatText(content) {
            // Simple markdown to HTML conversion
            content = content.replace(/\*\*(.*?)\*\*/g, '<b>$1</b>'); // **bold**
            content = content.replace(/\*(.*?)\*/g, '<b>$1</b>'); // *italic* (treating as bold for simplicity)
            content = content.replace(/`(.*?)`/g, '<code>$1</code>'); // `code`
            content = content.replace(/```([\s\S]*?)```/g, '<pre>$1</pre>'); // ```codeblock```
            return content;
        }

        readonly property bool isUser: messageRole === "user"
        readonly property bool isInterface: messageRole === "interface"

        visible: message !== undefined && !isInterface
        implicitHeight: visible ? messageBubble.implicitHeight + Tokens.spacing.small : 0

        // Listen for message updates and increment revision to trigger re-evaluation
        Connections {
            target: Ai
            function onMessageUpdated(msgId) {
                if (msgId === messageItem.messageId) {
                    messageItem.revision++;
                }
            }
            function onMessagesChanged() {
                messageItem.revision++;
            }
        }

        // Message bubble
        StyledRect {
            id: messageBubble

            anchors.left: isUser ? undefined : parent.left
            anchors.right: isUser ? parent.right : undefined

            implicitWidth: {
                const maxWidth = parent.width * 0.75;
                const padding = Tokens.padding.medium * 2;
                if (messageContent.length > 0) {
                    const textWidth = messageText.implicitWidth + padding;
                    return Math.min(maxWidth, Math.max(60, textWidth));
                } else {
                    // Thinking dots
                    return 60;
                }
            }
            implicitHeight: {
                const padding = Tokens.padding.medium;
                if (messageContent.length > 0) {
                    const bottomPadding = isUser ? padding : Tokens.padding.small;
                    return messageText.height + padding + bottomPadding;
                } else {
                    // Thinking dots height
                    return 32;
                }
            }

            color: isUser
                ? Colours.palette.m3primaryContainer
                : Colours.palette.m3surfaceContainerHigh
            radius: Tokens.rounding.large

            // Subtle shadow for depth
            layer.enabled: true
            layer.effect: DropShadow {
                horizontalOffset: 0
                verticalOffset: 1
                radius: 2
                samples: 5
                color: Qt.rgba(0, 0, 0, 0.08)
            }

            // Message text
            StyledText {
                id: messageText

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.leftMargin: Tokens.padding.medium
                anchors.rightMargin: Tokens.padding.medium
                anchors.topMargin: Tokens.padding.medium
                anchors.bottomMargin: isUser ? Tokens.padding.medium : Tokens.padding.small

                visible: messageContent.length > 0
                text: isUser ? messageContent : formatText(messageContent)
                color: isUser
                    ? Colours.palette.m3onPrimaryContainer
                    : Colours.palette.m3onSurface
                wrapMode: Text.Wrap
                textFormat: isUser ? Text.PlainText : Text.RichText
                font.pointSize: Tokens.font.body.medium.pointSize
            }

            // Thinking indicator (animated dots)
            Row {
                id: thinkingDots
                anchors.centerIn: parent
                visible: messageContent.length === 0 && messageThinking && !messageDone
                spacing: 6

                Repeater {
                    model: 3

                    Rectangle {
                        width: 8
                        height: 8
                        radius: 4
                        color: isUser
                            ? Colours.palette.m3onPrimaryContainer
                            : Colours.palette.m3onSurfaceVariant

                        // Smooth wave animation
                        SequentialAnimation on scale {
                            running: messageContent.length === 0 && messageThinking && !messageDone
                            loops: Animation.Infinite

                            PauseAnimation { duration: index * 200 }
                            NumberAnimation {
                                from: 1.0
                                to: 1.4
                                duration: 500
                                easing.type: Easing.InOutQuad
                            }
                            NumberAnimation {
                                from: 1.4
                                to: 1.0
                                duration: 500
                                easing.type: Easing.InOutQuad
                            }
                            PauseAnimation { duration: (2 - index) * 200 }
                        }

                        SequentialAnimation on opacity {
                            running: messageContent.length === 0 && messageThinking && !messageDone
                            loops: Animation.Infinite

                            PauseAnimation { duration: index * 200 }
                            NumberAnimation {
                                from: 0.4
                                to: 1.0
                                duration: 500
                                easing.type: Easing.InOutQuad
                            }
                            NumberAnimation {
                                from: 1.0
                                to: 0.4
                                duration: 500
                                easing.type: Easing.InOutQuad
                            }
                            PauseAnimation { duration: (2 - index) * 200 }
                        }
                    }
                }
            }
        }
    }
}
