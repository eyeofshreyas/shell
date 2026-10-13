import QtQuick
import qs.components

// "Bit": a small squircle that mirrors the state of your AI agents.
// mood: "sleep" | "idle" | "working" | "waiting" | "error"
Item {
    id: root

    property string mood: "idle"
    property string tool: ""
    property bool dancing: false
    property bool tired: false
    // pointer position in this item's coordinates (NaN = not hovering)
    property point pointer: Qt.point(NaN, NaN)
    property color body: "#6750A4"
    property color eye: "#FFFFFF"
    property color accent: "#B3261E"

    // transient reaction: "" | "happy" | "annoyed" | "dizzy" | "love"
    property string emote: ""
    // "" | cap | bow | shades | crown | pumpkin | santa | party | wizard | catears | halo | headphones | tophat | flower
    property string outfit: ""

    property bool yawning: false

    readonly property bool sleeping: mood === "sleep" && !yawning && !hovering
    readonly property bool waiting: mood === "waiting"
    readonly property bool working: mood === "working"
    readonly property bool failing: mood === "error"
    readonly property bool asking: waiting && tool === "AskUserQuestion"
    readonly property bool thinking: working && tool === ""
    readonly property bool typing: working && /^(Edit|Write|MultiEdit|NotebookEdit|Bash)$/.test(tool)
    readonly property bool hovering: !isNaN(pointer.x)
    readonly property string badge: {
        if (failing)
            return "error";
        if (waiting)
            return asking ? "question_mark" : "priority_high";
        if (working) {
            if (thinking)
                return "more_horiz";
            if (tool === "Bash")
                return "terminal";
            if (/^(Edit|Write|MultiEdit|NotebookEdit)$/.test(tool))
                return "edit";
            if (/^(Grep|Glob)$/.test(tool))
                return "search";
            if (tool === "Read")
                return "visibility";
            if (/^Web/.test(tool))
                return "language";
            if (/^(Task|Agent)$/.test(tool))
                return "hub";
            return "more_horiz";
        }
        return tired && !sleeping ? "water_drop" : "";
    }

    property real blink: 1
    property real scanX: 0
    property real lift: 0
    property real wobble: 0
    property real squish: 1
    property real roll: 0
    property real spark: 0
    property real shakeX: 0
    property real tilt: asking ? 9 : 0

    Behavior on tilt {
        NumberAnimation {
            duration: 220
            easing.type: Easing.OutQuad
        }
    }

    readonly property real lookX: thinking ? 2.5 : hovering && !working ? Math.max(-3.5, Math.min(3.5, (pointer.x - width / 2) / 14)) : scanX
    readonly property real lookY: typing ? 2.5 : thinking ? -2 : hovering && !working ? Math.max(-2, Math.min(2.5, (pointer.y - height / 2) / 14)) : 0

    implicitWidth: 64
    implicitHeight: 64

    property string prevMood: mood

    onMoodChanged: {
        if (mood === "idle" && (prevMood === "working" || prevMood === "waiting" || prevMood === "error"))
            cheer();
        else if (mood === "sleep" && prevMood !== "sleep")
            yawn();
        else if (mood === "error")
            shakeAnim.restart();
        prevMood = mood;
    }

    onHoveringChanged: {
        if (!hovering && mood === "sleep")
            yawn();
    }

    signal secondaryClicked
    signal primaryDoubleClicked
    signal primaryClicked

    function yawn(): void {
        yawning = true;
        yawnTimer.restart();
    }

    Component.onCompleted: greet.start()

    function cheer(): void {
        emote = "happy";
        emoteTimer.interval = 1400;
        emoteTimer.restart();
        hop.restart();
        rollAnim.restart();
        sparkAnim.restart();
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
        id: yawnTimer

        interval: 1500
        onTriggered: root.yawning = false
    }

    Timer {
        id: loveTimer

        interval: 1900
        onTriggered: {
            if (root.emote === "" && !root.waiting && !root.failing && !root.sleeping) {
                root.emote = "love";
                emoteTimer.interval = 2600;
                emoteTimer.restart();
            }
        }
    }

    SequentialAnimation {
        id: rollAnim

        NumberAnimation {
            target: root
            property: "roll"
            from: 0
            to: 360
            duration: 950
            easing.type: Easing.InOutQuad
        }
        ScriptAction {
            script: root.roll = 0
        }
    }

    NumberAnimation {
        id: sparkAnim

        target: root
        property: "spark"
        from: 0
        to: 1
        duration: 1000
        easing.type: Easing.OutCubic
    }

    SequentialAnimation {
        id: shakeAnim

        loops: 3
        NumberAnimation {
            target: root
            property: "shakeX"
            to: 4
            duration: 55
        }
        NumberAnimation {
            target: root
            property: "shakeX"
            to: -4
            duration: 55
        }
        onFinished: root.shakeX = 0
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
        running: root.working && !root.typing && !root.thinking
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
        running: root.waiting && !root.asking && root.emote === ""
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
        height: root.sleeping ? 40 : root.yawning ? 51 : 46
        radius: 18
        x: (root.width - width) / 2 + root.shakeX

        Behavior on height {
            NumberAnimation {
                duration: 350
                easing.type: Easing.InOutQuad
            }
        }

        y: root.height - height - 4 + root.lift
        color: root.body
        border.width: root.waiting || root.failing ? 2 : 0
        border.color: root.accent
        opacity: root.sleeping ? 0.6 : 1
        rotation: root.wobble + root.tilt
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
            },
            Rotation {
                origin.x: shape.width / 2
                origin.y: shape.height / 2
                angle: root.roll
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
                        readonly property bool love: root.emote === "love"

                        width: 10
                        height: 16

                        // normal eye
                        Rectangle {
                            visible: !eyeSlot.happy && !eyeSlot.dizzy && !eyeSlot.love
                            width: root.waiting || root.failing ? 10 : 8
                            height: root.sleeping ? 2.5 : root.yawning || root.failing ? 3 : eyeSlot.annoyed ? 4 : Math.max(2.5, (root.waiting ? 15 : root.tired ? 6 : 11) * root.blink)
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

                        // love heart eye
                        Text {
                            visible: eyeSlot.love
                            anchors.centerIn: parent
                            text: "\u2665"
                            color: "#FF4D6D"
                            font.pixelSize: 15
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

            // love blush
            Repeater {
                model: 2

                Rectangle {
                    required property int index

                    visible: root.emote === "love"
                    x: parent.width / 2 + (index === 0 ? -23 : 14)
                    y: parent.height * 0.62
                    width: 9
                    height: 5
                    radius: 2.5
                    color: "#66FF4D6D"
                }
            }

            // mouth
            Rectangle {
                readonly property bool ring: root.waiting || root.yawning || root.emote === "dizzy"

                visible: !root.sleeping
                anchors.horizontalCenter: parent.horizontalCenter
                y: parent.height * 0.82
                width: {
                    if (root.yawning)
                        return 10;
                    if (root.emote === "happy")
                        return 12;
                    if (root.emote === "love")
                        return 11;
                    if (root.emote === "dizzy" || root.emote === "annoyed" || root.failing)
                        return 9;
                    return root.waiting ? 8 : root.working ? 6 : 10;
                }
                height: {
                    if (root.yawning)
                        return 11;
                    if (root.emote === "happy" || root.emote === "love" || root.emote === "dizzy")
                        return 6;
                    if (root.emote === "annoyed" || root.failing)
                        return 2.5;
                    return root.waiting ? 8 : root.working ? 6 : 3.5;
                }
                radius: Math.min(width, height) / 2
                color: ring ? "transparent" : root.eye
                border.width: ring ? 2 : 0
                border.color: root.eye
            }
        }

        MascotOutfit {
            outfit: root.outfit
            eyeY: face.y + 2
        }
    }

    // what the agent is doing right now
    MaterialIcon {
        id: badgeIcon

        visible: root.badge !== "" && root.emote === ""
        x: shape.x + shape.width - 8
        y: 0
        text: root.badge
        color: root.waiting || root.failing ? root.accent : root.body

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
        visible: root.mood === "sleep" && !root.hovering
        x: shape.x + shape.width - 6
        y: 2
        text: "z"
        color: root.eye === "#ffffff" ? "#aaaaaa" : root.body
        opacity: 0.8
        font.pixelSize: 12
        font.bold: true
    }

    // hearts drifting up while it feels loved
    Repeater {
        model: 3

        Text {
            id: heart

            required property int index
            property real t: 0

            visible: root.emote === "love"
            x: shape.x + 8 + index * 14 + Math.sin(t * 6 + index) * 3
            y: shape.y - 4 - t * 20
            opacity: 1 - t
            text: "\u2665"
            color: "#FF4D6D"
            font.pixelSize: 10 + index * 2

            SequentialAnimation on t {
                running: root.emote === "love"
                loops: Animation.Infinite
                PauseAnimation {
                    duration: heart.index * 380
                }
                NumberAnimation {
                    from: 0
                    to: 1
                    duration: 1100
                }
            }
        }
    }

    // sparkles bursting out when an agent finishes
    Repeater {
        model: 5

        Text {
            id: star

            required property int index
            readonly property real ang: (index * 72 - 90) * Math.PI / 180

            visible: root.spark > 0 && root.spark < 1
            x: shape.x + shape.width / 2 + Math.cos(ang) * (12 + root.spark * 22) - width / 2
            y: shape.y + shape.height / 2 + Math.sin(ang) * (12 + root.spark * 22) - height / 2
            opacity: root.spark < 0.15 ? root.spark / 0.15 : 1 - (root.spark - 0.15) / 0.85
            text: "\u2726"
            color: "#F7B32B"
            font.pixelSize: 11
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                root.secondaryClicked();
            } else {
                root.poke();
                root.primaryClicked();
            }
        }
        onDoubleClicked: root.primaryDoubleClicked()
        onEntered: loveTimer.restart()
        onPositionChanged: loveTimer.restart()
        onExited: loveTimer.stop()
    }
}
