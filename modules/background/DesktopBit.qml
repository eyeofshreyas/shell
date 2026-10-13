import QtQuick
import "../dashboard/dash"
import qs.services

// Bit sitting on the desktop; drag it anywhere, the spot is remembered.
// The Loader stretches the root to the screen, so Bit lives in an inner item.
Item {
    id: root

    // The desktop clock's rectangle; walks never end on it.
    property rect avoid: Qt.rect(0, 0, 0, 0)

    Item {
        id: spot

        width: 96
        height: 96
        x: Bit.deskX >= 0 ? Math.min(Bit.deskX, root.width - width) : root.width - width - 80
        y: Bit.deskY >= 0 ? Math.min(Bit.deskY, root.height - height) : root.height - height - 260

        property bool walking: false
        property int walkMs: 1500

        Behavior on x {
            enabled: spot.walking

            NumberAnimation {
                duration: spot.walkMs
                easing.type: Easing.InOutSine
            }
        }

        Behavior on y {
            enabled: spot.walking

            NumberAnimation {
                duration: spot.walkMs
                easing.type: Easing.InOutSine
            }
        }

        function walk(): bool {
            const m = 32;
            for (let i = 0; i < 8; i++) {
                const nx = Math.max(0, Math.min(root.width - width, x + (Math.random() - 0.5) * 360));
                const ny = Math.max(0, Math.min(root.height - height, y + (Math.random() - 0.5) * 160));
                const a = root.avoid;
                if (a.width > 0 && nx + width + m > a.x && nx - m < a.x + a.width && ny + height + m > a.y && ny - m < a.y + a.height)
                    continue;
                walkMs = Math.max(600, Math.hypot(nx - x, ny - y) * 14);
                walking = true;
                Bit.moveDesktop(nx, ny);
                walkDone.interval = walkMs + 50;
                walkDone.restart();
                return true;
            }
            return false;
        }

        Timer {
            id: playing

            interval: 2200
        }

        Timer {
            id: walkDone

            onTriggered: spot.walking = false
        }

        BitMascot {
            id: mascot

            mood: (spot.walking || playing.running) && Bit.mood === "sleep" ? "idle" : Bit.mood
            anchors.fill: parent
            scale: 1.5
            transform: Translate {
                id: bob
            }
            rotation: 0

            SequentialAnimation {
                running: spot.walking
                loops: Animation.Infinite
                onRunningChanged: if (!running) {
                    bob.y = 0;
                    mascot.rotation = 0;
                }

                ParallelAnimation {
                    NumberAnimation {
                        target: bob
                        property: "y"
                        to: -5
                        duration: 160
                        easing.type: Easing.OutQuad
                    }

                    NumberAnimation {
                        target: mascot
                        property: "rotation"
                        to: 5
                        duration: 160
                    }
                }

                ParallelAnimation {
                    NumberAnimation {
                        target: bob
                        property: "y"
                        to: 0
                        duration: 160
                        easing.type: Easing.InQuad
                    }

                    NumberAnimation {
                        target: mascot
                        property: "rotation"
                        to: -5
                        duration: 160
                    }
                }
            }
        }

        Timer {
            interval: 6000
            running: true
            repeat: true
            onTriggered: {
                interval = 6000 + Math.random() * 10000;
                if (drag.active || spot.walking || Bit.mood === "working" || Bit.mood === "waiting")
                    return;
                if (Bit.walk && Math.random() < 0.5 && spot.walk())
                    return;
                playing.restart();
                mascot.cheer();
            }
        }

        DragHandler {
            id: drag

            target: spot
            xAxis.minimum: 0
            xAxis.maximum: root.width - spot.width
            yAxis.minimum: 0
            yAxis.maximum: root.height - spot.height
            onActiveChanged: if (!active)
                Bit.moveDesktop(spot.x, spot.y)
        }
    }
}
