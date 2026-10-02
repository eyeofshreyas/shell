pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.components.containers
import qs.components.misc
import qs.services

Scope {
    LazyLoader {
        id: root

        StyledWindow {
            id: win

            readonly property ShellScreen activeScreen: Quickshell.screens.find(s => s.name === Hypr.focusedMonitor?.name) ?? Quickshell.screens[0]

            screen: win.activeScreen
            name: "display-mode"

            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true

            MouseArea {
                anchors.fill: parent
                onClicked: root.active = false
            }

            Content {
                anchors.centerIn: parent

                onClose: root.active = false
            }
        }
    }

    IpcHandler {
        function toggle(): void {
            if (root.active)
                root.active = false;
            else
                root.activeAsync = true;
        }

        function open(): void {
            root.activeAsync = true;
        }

        function close(): void {
            root.active = false;
        }

        target: "displayMode"
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "displayMode"
        description: "Toggle display mode switcher"
        onPressed: {
            if (root.active)
                root.active = false;
            else
                root.activeAsync = true;
        }
    }
}
