pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.services

// Coco's chat: a big speech bubble whose tail points at desktop Coco.
Variants {
    model: Screens.screens

    StyledWindow {
        id: win

        readonly property int tail: 18
        readonly property int bodyHeight: 560

        required property ShellScreen modelData

        readonly property var state: ShellState.forScreen(modelData)
        readonly property bool open: state?.aiChat ?? false
        readonly property bool nearBit: Bit.desktop && modelData.name === Screens.screens[0]?.name

        property real px: 0
        property real py: 0
        property real tailX: -1

        function place(): void {
            if (!nearBit) {
                tailX = -1;
                px = screen.width - width - 24;
                py = screen.height - bodyHeight - 24;
                return;
            }
            const bx = Bit.deskX >= 0 ? Bit.deskX : screen.width - 176;
            const by = Bit.deskY >= 0 ? Bit.deskY : screen.height - 356;
            px = Math.max(8, Math.min(screen.width - width - 8, bx + 48 - width / 2));
            py = Math.max(8, by - 20 - height);
            tailX = Math.max(36, Math.min(width - 36, bx + 48 - px));
        }

        screen: modelData
        name: "aichat"
        visible: open
        onOpenChanged: {
            if (open) {
                place();
                pop.restart();
            }
        }

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
        exclusionMode: ExclusionMode.Ignore

        anchors.top: true
        anchors.left: true
        margins.top: py
        margins.left: px
        implicitWidth: 620
        implicitHeight: bodyHeight + (tailX >= 0 ? tail : 0)

        HyprlandFocusGrab {
            active: win.open
            windows: [win]
            onCleared: win.state.aiChat = false
        }

        Shortcut {
            sequence: "Escape"
            onActivated: win.state.aiChat = false
        }

        Item {
            id: bubble

            anchors.fill: parent
            transformOrigin: Item.Bottom

            ParallelAnimation {
                id: pop

                NumberAnimation {
                    target: bubble
                    property: "scale"
                    from: 0.85
                    to: 1
                    duration: 220
                    easing.type: Easing.OutBack
                }

                NumberAnimation {
                    target: bubble
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 160
                }
            }

            Shape {
                id: body

                readonly property color fill: Qt.tint(Colours.palette.m3surfaceContainerHigh, Qt.alpha(Colours.palette.m3primary, 0.1))
                readonly property real r: 36
                readonly property real w: width
                readonly property real h: win.bodyHeight
                readonly property bool hasTail: win.tailX >= 0
                readonly property real tx: hasTail ? win.tailX : w / 2
                readonly property real hw: hasTail ? 20 : 0
                readonly property real tip: hasTail ? win.tail : 0

                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    fillColor: body.fill
                    strokeColor: Qt.alpha(Colours.palette.m3primary, 0.28)
                    strokeWidth: 1

                    startX: body.r
                    startY: 0

                    PathLine { x: body.w - body.r; y: 0 }
                    PathArc { x: body.w; y: body.r; radiusX: body.r; radiusY: body.r }
                    PathLine { x: body.w; y: body.h - body.r }
                    PathArc { x: body.w - body.r; y: body.h; radiusX: body.r; radiusY: body.r }
                    PathLine { x: body.tx + body.hw; y: body.h }
                    PathQuad { x: body.tx - 8; y: body.h + body.tip; controlX: body.tx + 6; controlY: body.h + body.tip * 0.7 }
                    PathQuad { x: body.tx - body.hw; y: body.h; controlX: body.tx - 14; controlY: body.h + 2 }
                    PathLine { x: body.r; y: body.h }
                    PathArc { x: 0; y: body.h - body.r; radiusX: body.r; radiusY: body.r }
                    PathLine { x: 0; y: body.r }
                    PathArc { x: body.r; y: 0; radiusX: body.r; radiusY: body.r }
                }
            }

            Loader {
                x: 22
                y: 18
                width: parent.width - 44
                height: win.bodyHeight - 36
                active: win.open

                sourceComponent: AiChat {
                    surface: body.fill
                    onCloseRequested: win.state.aiChat = false
                }
            }
        }
    }
}
