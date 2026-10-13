pragma ComponentBehavior: Bound

import "../dashboard/dash"
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

    signal closeRequested

    property bool busy: false
    property color surface: Colours.palette.m3surfaceContainerHigh

    Connections {
        target: Ai

        function onMessageUpdated(): void {
            root.refreshBusy();
        }

        function onMessagesChanged(): void {
            root.refreshBusy();
        }
    }

    function refreshBusy(): void {
        const m = Ai.messageByID[Ai.messageIDs[Ai.messageIDs.length - 1]];
        busy = !!m && m.role === "assistant" && !m.done;
    }

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

                Item {
                    Layout.preferredWidth: 48
                    Layout.preferredHeight: 48

                    BitMascot {
                        anchors.fill: parent
                        anchors.margins: 6
                        mood: root.busy ? "working" : "idle"
                        tool: ""
                    }
                }

                ColumnLayout {
                    spacing: 0

                    StyledText {
                        text: Bit.name
                        font: Tokens.font.clock.size(Tokens.font.title.medium.pointSize).weight(Font.Bold).build()
                        color: Colours.palette.m3onSurface
                    }

                    StyledText {
                        text: root.busy ? qsTr("Thinking…") : qsTr("Ready")
                        font: Tokens.font.label.small
                        color: root.busy ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                    }
                }

                Item { Layout.fillWidth: true }

                // Provider switcher
                SplitButton {
                    id: providerSelector

                    type: SplitButton.Tonal
                    horizontalPadding: Tokens.padding.medium
                    verticalPadding: Tokens.padding.small
                    stateLayer.disabled: true

                    menuItems: providerVariants.instances
                    fallbackText: Tr.tr("No Provider")

                    label.Layout.maximumWidth: 100
                    label.elide: Text.ElideRight

                    menu.onItemSelected: item => Ai.setProvider(item.modelData)
                    menu.attachTo: providerSelector
                    menu.attachSideX: Menu.Left
                    menu.thisSideX: Menu.Left
                    menu.parent: root

                    // Menu assigns `active` on click, which would kill a plain binding
                    Binding {
                        target: providerSelector
                        property: "active"
                        value: providerSelector.menuItems.find(m => m.modelData === Ai.currentProvider) ?? providerSelector.menuItems[0] ?? null
                    }

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

                    menuItems: modelVariants.instances
                    fallbackText: qsTr("No Model")

                    label.Layout.maximumWidth: 130
                    label.elide: Text.ElideRight

                    menu.onItemSelected: item => Ai.setModel(item.modelData)
                    menu.attachTo: modelSelector
                    menu.attachSideX: Menu.Left
                    menu.thisSideX: Menu.Left
                    menu.parent: root

                    Binding {
                        target: modelSelector
                        property: "active"
                        value: modelSelector.menuItems.find(m => m.modelData === Ai.currentModelId) ?? modelSelector.menuItems[0] ?? null
                    }

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
                    icon: "close"
                    type: IconButton.Text
                    onClicked: root.closeRequested()
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
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Tokens.padding.large
                anchors.rightMargin: Tokens.padding.large
                visible: !Ai.messageIDs.some(id => Ai.messageByID[id]?.role !== "interface")
                spacing: Tokens.spacing.small

                BitMascot {
                    Layout.preferredWidth: 72
                    Layout.preferredHeight: 72
                    Layout.bottomMargin: Tokens.spacing.small
                    mood: "idle"
                    tool: ""
                    scale: 1.25
                    transformOrigin: Item.BottomLeft
                }

                StyledText {
                    text: qsTr("Hi, I'm %1.").arg(Bit.name)
                    font: Tokens.font.clock.size(Tokens.font.headline.large.pointSize).weight(Font.Bold).build()
                    color: Colours.palette.m3onSurface
                }

                StyledText {
                    Layout.bottomMargin: Tokens.spacing.normal
                    text: qsTr("What are we working on?")
                    font: Tokens.font.body.large
                    color: Colours.palette.m3onSurfaceVariant
                }

                Repeater {
                    model: [
                        {
                            icon: "event_note",
                            text: qsTr("Plan my day")
                        },
                        {
                            icon: "bug_report",
                            text: qsTr("Explain an error message")
                        },
                        {
                            icon: "terminal",
                            text: qsTr("Write a shell script")
                        }
                    ]

                    StyledRect {
                        id: starter

                        required property var modelData

                        implicitWidth: starterRow.implicitWidth + Tokens.padding.large * 2
                        implicitHeight: starterRow.implicitHeight + Tokens.padding.medium * 2
                        radius: Tokens.rounding.full
                        color: Qt.alpha(Colours.palette.m3primary, 0.1)

                        StateLayer {
                            color: Colours.palette.m3primary
                            onClicked: Ai.sendUserMessage(starter.modelData.text)
                        }

                        RowLayout {
                            id: starterRow

                            anchors.centerIn: parent
                            spacing: Tokens.spacing.small

                            MaterialIcon {
                                text: starter.modelData.icon
                                color: Colours.palette.m3primary
                                fontStyle: Tokens.font.icon.small
                            }

                            StyledText {
                                text: starter.modelData.text
                                font: Tokens.font.body.medium
                                color: Colours.palette.m3onSurface
                            }
                        }
                    }
                }
            }

            // Edge fades so scrolled text melts into the bubble
            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 18
                gradient: Gradient {
                    GradientStop { position: 0; color: root.surface }
                    GradientStop { position: 1; color: Qt.alpha(root.surface, 0) }
                }
            }

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 18
                gradient: Gradient {
                    GradientStop { position: 0; color: Qt.alpha(root.surface, 0) }
                    GradientStop { position: 1; color: root.surface }
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

                    color: Colours.palette.m3surfaceContainer
                    radius: Tokens.rounding.full
                    border.width: 1
                    border.color: inputField.activeFocus ? Colours.palette.m3primary : "transparent"

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
                                text: qsTr("Message %1…").arg(Bit.name)
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

        BitMascot {
            visible: !messageItem.isUser
            width: 30
            height: 30
            y: 2
            mood: messageItem.messageDone ? "idle" : "working"
            tool: ""
        }

        // Message bubble
        StyledRect {
            id: messageBubble

            anchors.left: isUser ? undefined : parent.left
            anchors.leftMargin: isUser ? 0 : 38
            anchors.right: isUser ? parent.right : undefined

            implicitWidth: {
                const maxWidth = isUser ? parent.width * 0.8 : parent.width - 38;
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

            color: isUser ? Colours.palette.m3primaryContainer : "transparent"
            radius: Tokens.rounding.large

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
                text: isUser ? messageContent : messageContent.split("```").map((t, i) => i % 2 ? t : t.replace(/^#{1,6}\s+(.*)$/gm, "**$1**\n")).join("```")
                color: isUser
                    ? Colours.palette.m3onPrimaryContainer
                    : Colours.palette.m3onSurface
                wrapMode: Text.Wrap
                textFormat: isUser ? Text.PlainText : Text.MarkdownText
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
