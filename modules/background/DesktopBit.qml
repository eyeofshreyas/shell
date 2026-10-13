import QtQuick
import Caelestia.Config
import Caelestia.I18n
import "../dashboard/dash"
import qs.components
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

        function say(text: string, force: bool): void {
            if (!Bit.talk && !force)
                return;
            bubble.text = text;
            bubble.shown = true;
            playing.restart();
            bubbleHide.restart();
        }

        function pick(list: var): string {
            return list[Math.floor(Math.random() * list.length)];
        }

        Timer {
            id: bubbleHide

            interval: 3800
            onTriggered: bubble.shown = false
        }

        Connections {
            property string prev: Bit.mood
            property int prevPending: Bit.pending

            target: Bit

            function onMoodChanged(): void {
                if (Bit.mood === "error")
                    spot.say(Tr.tr("Oops, something broke"));
                else if (Bit.mood === "waiting")
                    spot.say(Tr.tr("Waiting for you"));
                else if (Bit.mood === "idle" && (prev === "working" || prev === "waiting"))
                    spot.say(Tr.tr("All done!"));
                prev = Bit.mood;
            }

            function onPendingChanged(): void {
                if (Bit.pending > prevPending)
                    spot.say(Tr.tr("Needs your OK"));
                prevPending = Bit.pending;
            }

            function onTiredChanged(): void {
                if (Bit.tired)
                    spot.say(Tr.tr("Claude usage is almost full"));
            }
        }

        Connections {
            target: Pomodoro

            function onFocusChanged(): void {
                if (Pomodoro.running)
                    spot.say(Pomodoro.focus ? Tr.tr("Focus time!") : Tr.tr("Break time! Stretch a little."));
            }
        }

        Timer {
            interval: 30 * 60 * 1000
            running: Bit.remind
            repeat: true
            onTriggered: {
                if (!Pomodoro.focus && Pomodoro.running)
                    return;
                spot.say(spot.pick([Tr.tr("Drink some water."), Tr.tr("Rest your eyes, look far away."), Tr.tr("Stand up and stretch."), Tr.tr("Sit up straight.")]), true);
            }
        }

        Timer {
            id: clickTimer

            interval: 250
            onTriggered: ShellState.forActive().aiChat = true
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
            onPrimaryClicked: clickTimer.restart()
            onPrimaryDoubleClicked: {
                clickTimer.stop();
                Pomodoro.toggle();
                spot.say(Pomodoro.running ? Tr.tr("Let's focus!") : Tr.tr("Timer paused."));
            }
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
                if (drag.active || spot.walking || (Pomodoro.running && Pomodoro.focus) || Bit.mood === "working" || Bit.mood === "waiting")
                    return;
                const chat = !bubble.shown && Math.random() < 0.35;
                if (Bit.walk && Math.random() < 0.5 && spot.walk()) {
                    if (chat)
                        spot.say(spot.pick([Tr.tr("Just stretching my legs."), Tr.tr("Off for a stroll.")]));
                    return;
                }
                playing.restart();
                mascot.cheer();
                if (chat)
                    spot.say(spot.pick([Tr.tr("Wheee!"), Tr.tr("Boing!"), Tr.tr("Look at me!")]));
            }
        }

        Item {
            id: bubble

            property string text
            property bool shown: false

            width: label.implicitWidth + 24
            height: label.implicitHeight + 14
            x: Math.max(8 - spot.x, Math.min(root.width - 8 - spot.x - width, (spot.width - width) / 2))
            y: Math.max(8 - spot.y, -height - 22)
            opacity: shown ? 1 : 0
            scale: shown ? 1 : 0.85
            visible: opacity > 0
            transformOrigin: Item.Bottom

            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutBack
                }
            }

            Rectangle {
                width: 10
                height: 10
                rotation: 45
                x: spot.width / 2 - bubble.x - 5
                y: bubble.height - 6
                color: bubbleBody.color
            }

            Rectangle {
                id: bubbleBody

                anchors.fill: parent
                radius: 12
                color: Colours.palette.m3surfaceContainerHighest

                StyledText {
                    id: label

                    anchors.centerIn: parent
                    text: bubble.text
                    color: Colours.palette.m3onSurface
                    font: Tokens.font.body.builders.small.build()
                }
            }
        }

        StyledRect {
            id: pill

            readonly property real below: Math.min(spot.height + 18, root.height - spot.y - height - 8)

            visible: Pomodoro.active
            x: (spot.width - width) / 2
            y: below
            implicitWidth: pillLabel.implicitWidth + 20
            implicitHeight: pillLabel.implicitHeight + 8
            radius: height / 2
            color: Pomodoro.focus ? Colours.palette.m3primaryContainer : Colours.palette.m3tertiaryContainer

            StyledText {
                id: pillLabel

                anchors.centerIn: parent
                text: Pomodoro.label
                color: Pomodoro.focus ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onTertiaryContainer
                font: Tokens.font.body.builders.small.build()
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    Pomodoro.reset();
                    spot.say(Tr.tr("Timer cleared."));
                }
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
