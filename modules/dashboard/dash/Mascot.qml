import QtQuick
import qs.components

// "Bit": a small squircle that mirrors the state of your AI agents.
// mood: "sleep" | "idle" | "working" | "waiting"
Item {
    id: root

    property string mood: "idle"
    property string tool: ""
    property bool dancing: false
    // pointer position in this item's coordinates (NaN = not hovering)
    property point pointer: Qt.point(NaN, NaN)
    property color body: "#6750A4"
    property color eye: "#FFFFFF"
    property color accent: "#B3261E"

    // transient reaction: "" | "happy" | "annoyed" | "dizzy"
    property string emote: ""

    readonly property bool sleeping: mood === "sleep"
    readonly property bool waiting: mood === "waiting"
    readonly property bool working: mood === "working"
    readonly property bool typing: working && /^(Edit|Write|MultiEdit|NotebookEdit|Bash)$/.test(tool)
    readonly property bool hovering: !isNaN(pointer.x)
    readonly property string badge: waiting ? "priority_high" : !working ? "" : tool === "Bash" ? "terminal" : /^(Edit|Write|MultiEdit|NotebookEdit)$/.test(tool) ? "edit" : /^(Grep|Glob)$/.test(tool) ? "search" : tool === "Read" ? "visibility" : /^Web/.test(tool) ? "language" : /^(Task|Agent)$/.test(tool) ? "hub" : "more_horiz"

    property real blink: 1
    property real scanX: 0
    property real lift: 0
    property real wobble: 0
    property real squish: 1

    readonly property real lookX: hovering && !working ? Math.max(-3.5, Math.min(3.5, (pointer.x - width / 2) / 14)) : scanX
    readonly property real lookY: typing ? 2.5 : hovering && !working ? Math.max(-2, Math.min(2.5, (pointer.y - height / 2) / 14)) : 0

    implicitWidth: 64
    implicitHeight: 64

    property string prevMood: mood

    onMoodChanged: {
        if (mood === "idle" && (prevMood === "working" || prevMood === "waiting"))
            cheer();
        prevMood = mood;
    }

    Component.onCompleted: greet.start()

    function cheer(): void {
        emote = "happy";
        emoteTimer.interval = 1400;
        emoteTimer.restart();
        hop.restart();
    }

    function poke(): void {
        pokes++;
        pokeReset.restart();
        if (pokes >= 4) {
            pokes = 0;
            emote = "dizzy";
            emoteTimer.interval = 2200;
        } else {
            emote = "annoyed";
            emoteTimer.interval = 900;
        }
        emoteTimer.restart();
    }

    property int pokes: 0

    Timer {
        id: pokeReset

        interval: 1600
        onTriggered: root.pokes = 0
    }

    Timer {
        id: emoteTimer

        onTriggered: root.emote = ""
    }

    Timer {
        id: greet

        interval: 400
        onTriggered: {
            if (!root.sleeping) {
                root.emote = "happy";
                emoteTimer.interval = 1200;
                emoteTimer.restart();
            }
            hop.restart();
        }
    }

    Timer {
        interval: 2500
        running: !root.sleeping
        repeat: true
        onTriggered: {
            interval = 2000 + Math.random() * 3000;
            blinkAnim.restart();
        }
    }

    SequentialAnimation {
        id: blinkAnim

        NumberAnimation {
            target: root
            property: "blink"
            to: 0.08
            duration: 70
        }
        NumberAnimation {
            target: root
            property: "blink"
            to: 1
            duration: 110
        }
    }

    SequentialAnimation {
        id: hop

        NumberAnimation {
            target: root
            property: "lift"
            to: -14
            duration: 170
            easing.type: Easing.OutQuad
        }
        NumberAnimation {
            target: root
            property: "lift"
            to: 0
            duration: 170
            easing.type: Easing.InQuad
        }
        NumberAnimation {
            target: root
            property: "lift"
            to: -7
            duration: 120
            easing.type: Easing.OutQuad
        }
        NumberAnimation {
            target: root
            property: "lift"
            to: 0
            duration: 120
            easing.type: Easing.InQuad
        }
    }

    // eyes sweep left/right while reading/searching/thinking
    SequentialAnimation {
        running: root.working && !root.typing
        loops: Animation.Infinite
        NumberAnimation {
            target: root
            property: "scanX"
            to: -3.5
            duration: 450
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: root
            property: "scanX"
            to: 3.5
            duration: 450
            easing.type: Easing.InOutSine
        }
        onRunningChanged: if (!running)
            root.scanX = 0
    }

    // quick keystroke bounce while editing / running commands
    SequentialAnimation {
        running: root.typing
        loops: Animation.Infinite
        NumberAnimation {
            target: root
            property: "squish"
            to: 0.94
            duration: 90
        }
        NumberAnimation {
            target: root
            property: "squish"
            to: 1
            duration: 90
        }
        PauseAnimation {
            duration: 120
        }
        onRunningChanged: if (!running)
            root.squish = 1
    }

    // impatient hop while waiting for you
    SequentialAnimation {
        running: root.waiting && root.emote === ""
        loops: Animation.Infinite
        PauseAnimation {
            duration: 400
        }
        NumberAnimation {
            target: root
            property: "lift"
            to: -8
            duration: 200
            easing.type: Easing.OutQuad
        }
        NumberAnimation {
            target: root
            property: "lift"
            to: 0
            duration: 200
            easing.type: Easing.InQuad
        }
        onRunningChanged: if (!running)
            root.lift = 0
    }

    // sway when dizzy, boogie when music plays
    SequentialAnimation {
        running: root.emote === "dizzy" || (root.dancing && !root.working && !root.waiting)
        loops: Animation.Infinite
        NumberAnimation {
            target: root
            property: "wobble"
            to: root.emote === "dizzy" ? 12 : 7
            duration: root.emote === "dizzy" ? 180 : 320
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: root
            property: "wobble"
            to: root.emote === "dizzy" ? -12 : -7
            duration: root.emote === "dizzy" ? 180 : 320
            easing.type: Easing.InOutSine
        }
        onRunningChanged: if (!running)
            root.wobble = 0
    }

    SequentialAnimation {
        running: root.dancing && !root.working && !root.waiting && !root.sleeping
        loops: Animation.Infinite
        NumberAnimation {
            target: root
            property: "lift"
            to: -5
            duration: 160
            easing.type: Easing.OutQuad
        }
        NumberAnimation {
            target: root
            property: "lift"
            to: 0
            duration: 160
            easing.type: Easing.InQuad
        }
        onRunningChanged: if (!running)
            root.lift = 0
    }

    Item {
        x: (root.width - width) / 2
        y: root.height - 8
        width: 42 * (1 + root.lift / 45)
        height: 7
        opacity: Math.max(0.2, 1 + root.lift / 22)

        Repeater {
            model: 3

            Rectangle {
                required property int index

                anchors.centerIn: parent
                width: parent.width * (1 - index * 0.22)
                height: parent.height * (1 - index * 0.22)
                radius: height / 2
                color: Qt.alpha(root.sleeping ? root.eye : root.body, 0.16)
            }
        }
    }

    Rectangle {
        id: shape

        width: 48
        height: root.sleeping ? 40 : 46
        radius: 18
        x: (root.width - width) / 2
        y: root.height - height - 4 + root.lift
        color: root.body
        border.width: root.waiting ? 2 : 0
        border.color: root.accent
        opacity: root.sleeping ? 0.6 : 1
        rotation: root.wobble
        transformOrigin: Item.Bottom
        scale: root.squish
        transform: [
            Rotation {
                origin.x: shape.width / 2
                origin.y: shape.height / 2
                axis {
                    x: 0
                    y: 1
                    z: 0
                }
                angle: root.lookX * 4
            },
            Rotation {
                origin.x: shape.width / 2
                origin.y: shape.height / 2
                axis {
                    x: 1
                    y: 0
                    z: 0
                }
                angle: -root.lookY * 5
            }
        ]

        SequentialAnimation on scale {
            running: !root.working && !root.waiting && !root.dancing
            loops: Animation.Infinite
            NumberAnimation {
                to: 1.04
                duration: root.sleeping ? 2400 : 1600
                easing.type: Easing.InOutSine
            }
            NumberAnimation {
                to: 1
                duration: root.sleeping ? 2400 : 1600
                easing.type: Easing.InOutSine
            }
            onRunningChanged: if (!running)
                shape.scale = Qt.binding(() => root.squish)
        }

        // top-light / bottom-shade
        Rectangle {
            anchors.fill: parent
            radius: shape.radius
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: "#4dffffff"
                }
                GradientStop {
                    position: 0.4
                    color: "#00ffffff"
                }
                GradientStop {
                    position: 1
                    color: "#59000000"
                }
            }
        }

        // side shade on the right, like a lit sphere
        Rectangle {
            anchors.fill: parent
            radius: shape.radius
            gradient: Gradient {
                orientation: Gradient.Horizontal

                GradientStop {
                    position: 0
                    color: "#1affffff"
                }
                GradientStop {
                    position: 0.55
                    color: "#00000000"
                }
                GradientStop {
                    position: 1
                    color: "#40000000"
                }
            }
        }

        // glossy highlight
        Rectangle {
            x: 6
            y: 3
            width: parent.width * 0.52
            height: parent.height * 0.26
            radius: height / 2
            rotation: -8
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: "#99ffffff"
                }
                GradientStop {
                    position: 1
                    color: "#00ffffff"
                }
            }
        }

        Item {
            id: face

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.horizontalCenterOffset: root.lookX * 1.5
            y: parent.height * 0.3 + root.lookY * 1.4
            width: parent.width
            height: parent.height * 0.5

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 11

                Repeater {
                    model: 2

                    Item {
                        id: eyeSlot

                        required property int index
                        readonly property bool happy: root.emote === "happy"
                        readonly property bool dizzy: root.emote === "dizzy"
                        readonly property bool annoyed: root.emote === "annoyed"

                        width: 10
                        height: 16

                        // normal eye
                        Rectangle {
                            visible: !eyeSlot.happy && !eyeSlot.dizzy
                            width: root.waiting ? 10 : 8
                            height: root.sleeping ? 2.5 : eyeSlot.annoyed ? 4 : Math.max(2.5, (root.waiting ? 15 : 11) * root.blink)
                            radius: Math.min(width, height) / 2
                            gradient: Gradient {
                                GradientStop {
                                    position: 0
                                    color: Qt.lighter(root.eye, 1.5)
                                }
                                GradientStop {
                                    position: 1
                                    color: Qt.darker(root.eye, 1.25)
                                }
                            }
                            anchors.centerIn: parent
                            anchors.verticalCenterOffset: 1

                            Rectangle {
                                visible: parent.height > 7
                                x: parent.width * 0.18
                                y: parent.height * 0.1
                                width: Math.max(2, parent.width * 0.38)
                                height: width
                                radius: width / 2
                                color: "#e6ffffff"
                            }
                        }

                        // happy ^ ^ eye
                        Item {
                            visible: eyeSlot.happy
                            anchors.centerIn: parent
                            width: 10
                            height: 5
                            clip: true

                            Rectangle {
                                width: 10
                                height: 10
                                radius: 5
                                color: "transparent"
                                border.width: 2.5
                                border.color: root.eye
                            }
                        }

                        // dizzy spiral eye
                        Text {
                            visible: eyeSlot.dizzy
                            anchors.centerIn: parent
                            text: "@"
                            color: root.eye
                            font.pixelSize: 13
                            font.bold: true

                            RotationAnimator on rotation {
                                running: eyeSlot.dizzy
                                from: 0
                                to: eyeSlot.index === 0 ? 360 : -360
                                duration: 600
                                loops: Animation.Infinite
                            }
                        }

                        // annoyed brow
                        Rectangle {
                            visible: eyeSlot.annoyed
                            width: 10
                            height: 2.5
                            radius: 1.25
                            color: root.eye
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: 0
                            rotation: eyeSlot.index === 0 ? 18 : -18
                        }
                    }
                }
            }

            // mouth
            Rectangle {
                visible: !root.sleeping
                anchors.horizontalCenter: parent.horizontalCenter
                y: parent.height * 0.82
                width: root.emote === "happy" ? 12 : root.emote === "dizzy" ? 9 : root.emote === "annoyed" ? 9 : root.waiting ? 8 : root.working ? 6 : 10
                height: root.emote === "happy" ? 6 : root.emote === "dizzy" ? 6 : root.emote === "annoyed" ? 2.5 : root.waiting ? 8 : root.working ? 6 : 3.5
                radius: root.emote === "happy" ? 6 : Math.min(width, height) / 2
                color: root.waiting || root.emote === "dizzy" ? "transparent" : root.eye
                border.width: root.waiting || root.emote === "dizzy" ? 2 : 0
                border.color: root.eye
            }
        }
    }

    // what the agent is doing right now
    MaterialIcon {
        id: badgeIcon

        visible: root.badge !== "" && root.emote === ""
        x: shape.x + shape.width - 8
        y: 0
        text: root.badge
        color: root.waiting ? root.accent : root.body

        SequentialAnimation on y {
            running: badgeIcon.visible
            loops: Animation.Infinite
            NumberAnimation {
                to: 3
                duration: 400
                easing.type: Easing.InOutSine
            }
            NumberAnimation {
                to: 0
                duration: 400
                easing.type: Easing.InOutSine
            }
        }
    }

    Text {
        visible: root.sleeping
        x: shape.x + shape.width - 6
        y: 2
        text: "z"
        color: root.eye === "#ffffff" ? "#aaaaaa" : root.body
        opacity: 0.8
        font.pixelSize: 12
        font.bold: true
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.poke()
    }
}
