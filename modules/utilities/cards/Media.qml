pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.components.misc
import qs.services
import qs.utils

StyledRect {
    id: root

    required property var props
    required property ScreenState screenState
    readonly property real nonAnimHeight: btnLayout.implicitHeight + (tabIndex === 0 ? shotsBody.implicitHeight : recsBody.implicitHeight) + layout.spacing + layout.anchors.margins * 2

    implicitHeight: layout.implicitHeight + layout.anchors.margins * 2

    radius: Tokens.rounding.large
    color: Colours.tPalette.m3surfaceContainer

    Ref {
        service: Recorder
    }

    // 0 = Screenshots, 1 = Recordings
    property int tabIndex: props.utilitiesMediaTab
    onTabIndexChanged: tabSwitch.restart()

    property var screenshotMenuItems
    property var recordingMenuItems

    Component.onCompleted: {
        // Helper to create screenshot items that hold a stable reference to this card
        const mkShot = (icon, text, activeText, cmdArray) => {
            const qml = 'import qs.components.controls; MenuItem { property var mediaRoot; icon: "' + icon + '"; text: qsTr("' + text + '"); activeText: qsTr("' + activeText + '"); onClicked: { if (mediaRoot && mediaRoot.triggerShot) mediaRoot.triggerShot(' + JSON.stringify(cmdArray) + ') } }';
            const item = Qt.createQmlObject(qml, root);
            item.mediaRoot = root;
            return item;
        }
        screenshotMenuItems = [
            mkShot("fullscreen", "Fullscreen", "Fullscreen", ["caelestia", "screenshot"]),
            mkShot("crop_free", "Area (edit)", "Area", ["caelestia", "shell", "picker", "openFreeze"]),
            mkShot("web_asset", "Active window (edit)", "Window", ["caelestia", "shell", "picker", "open"])
        ]

        // Helper to create recording items that call Recorder directly (fullscreen variants)
        const mkRec = (icon, text, activeText, args) => {
            const call = args ? 'Recorder.start(' + JSON.stringify(args) + ')' : 'Recorder.start()';
            const qml = 'import qs.components.controls; import qs.services; MenuItem { icon: "' + icon + '"; text: qsTr("' + text + '"); activeText: qsTr("' + activeText + '"); onClicked: { ' + call + ' } }';
            return Qt.createQmlObject(qml, root);
        }
        // Helper to create region recording items that go through AreaPicker (scale-correct geometry)
        const mkRecRegion = (icon, text, activeText, withSound) => {
            const cmd = withSound ? ['caelestia', 'shell', 'picker', 'openRecordSound']
                                  : ['caelestia', 'shell', 'picker', 'openRecord'];
            const qml = 'import qs.components.controls; MenuItem { property var mediaRoot; icon: "' + icon + '"; text: qsTr("' + text + '"); activeText: qsTr("' + activeText + '"); onClicked: { if (mediaRoot && mediaRoot.triggerShot) mediaRoot.triggerShot(' + JSON.stringify(cmd) + ') } }';
            const item = Qt.createQmlObject(qml, root);
            item.mediaRoot = root;
            return item;
        }
        recordingMenuItems = [
            mkRec("fullscreen", "Record fullscreen", "Fullscreen", null),
            mkRecRegion("screenshot_region", "Record region", "Region", false),
            mkRec("select_to_speak", "Record fullscreen with sound", "Fullscreen", ["-s"]),
            mkRecRegion("volume_up", "Record region with sound", "Region", true)
        ]
    }

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.medium

        // Header: two icon chips (tabs) + contextual actions on the right
        RowLayout {
            id: btnLayout

            spacing: Tokens.spacing.medium

            // Screenshot chip (acts as tab toggle)
            StyledRect {
                implicitWidth: implicitHeight
                implicitHeight: {
                    const h = shotIcon.implicitHeight + Tokens.padding.small * 2;
                    return h - (h % 2);
                }
                radius: Tokens.rounding.full
                color: root.tabIndex === 0 ? Colours.palette.m3secondaryContainer : Colours.layer(Colours.palette.m3surfaceContainerHigh, 1)

                MaterialIcon {
                    id: shotIcon
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: 1
                    text: "screenshot_monitor"
                    color: root.tabIndex === 0 ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                    fontStyle: Tokens.font.icon.large
                }

                CustomMouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { root.tabIndex = 0; root.props.utilitiesMediaTab = 0 }
                }
            }

            // Recording chip (acts as tab toggle)
            StyledRect {
                implicitWidth: implicitHeight
                implicitHeight: {
                    const h = recIcon.implicitHeight + Tokens.padding.small * 2;
                    return h - (h % 2);
                }
                radius: Tokens.rounding.full
                color: root.tabIndex === 1
                       ? (Recorder.running ? Colours.palette.m3secondary : Colours.palette.m3secondaryContainer)
                       : Colours.layer(Colours.palette.m3surfaceContainerHigh, 1)

                MaterialIcon {
                    id: recIcon
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: 1
                    text: "screen_record"
                    color: root.tabIndex === 1
                           ? (Recorder.running ? Colours.palette.m3onSecondary : Colours.palette.m3onSecondaryContainer)
                           : Colours.palette.m3onSurfaceVariant
                    fontStyle: Tokens.font.icon.large
                }

                CustomMouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { root.tabIndex = 1; root.props.utilitiesMediaTab = 1 }
                }
            }

            Item { Layout.fillWidth: true }

            // Contextual action area (SplitButton)
            SplitButton {
                Layout.leftMargin: Tokens.spacing.medium
                z: 2
                disabled: root.tabIndex === 1 && Recorder.running
                active: root.tabIndex === 0 ? (screenshotMenuItems.find(m => root.props.screenshotMode === m.icon + m.text) ?? screenshotMenuItems[0]) : (recordingMenuItems.find(m => root.props.recordingMode === m.icon + m.text) ?? recordingMenuItems[0])
                menuItems: root.tabIndex === 0 ? screenshotMenuItems : recordingMenuItems
                menu.onItemSelected: item => root.tabIndex === 0 ? root.props.screenshotMode = item.icon + item.text : root.props.recordingMode = item.icon + item.text
                stateLayer.disabled: false
            }
        }

        // Body: cross-fade between bodies and animate height smoothly
        Item {
            id: body
            Layout.fillWidth: true
            // Start at the active body's height; animation sequence will adjust when switching
            Layout.preferredHeight: root.tabIndex === 0 ? shotsBody.implicitHeight : recsBody.implicitHeight

            // Screenshots
            Loader {
                id: shotsBody
                anchors.fill: parent
                asynchronous: true
                active: true
                visible: root.tabIndex === 0
                opacity: visible ? 1 : 0
                scale: visible ? 1 : 0.9
                transformOrigin: Item.Top
                sourceComponent: screenshotList

                Behavior on opacity { Anim { duration: 250; easing: Tokens.anim.expressiveDefaultSpatial } }
                Behavior on scale { Anim { duration: 250; easing: Tokens.anim.expressiveDefaultSpatial } }
            }

            // Recordings container: keep both sub-bodies alive and cross-fade
            Item {
                id: recsBody
                anchors.fill: parent
                visible: root.tabIndex === 1
                opacity: visible ? 1 : 0
                scale: visible ? 1 : 0.9
                transformOrigin: Item.Top
                implicitHeight: Math.max(recListLoader.implicitHeight || 0, recCtlLoader.implicitHeight || 0)

                // Recording list
                Loader {
                    id: recListLoader
                    anchors.fill: parent
                    asynchronous: true
                    active: true
                    visible: !Recorder.running
                    opacity: visible ? 1 : 0
                    scale: visible ? 1 : 0.9
                    transformOrigin: Item.Top
                    sourceComponent: recordingList

                    Behavior on opacity { Anim { duration: 250; easing: Tokens.anim.expressiveDefaultSpatial } }
                    Behavior on scale { Anim { duration: 250; easing: Tokens.anim.expressiveDefaultSpatial } }
                }

                // Recording controls
                Loader {
                    id: recCtlLoader
                    anchors.fill: parent
                    asynchronous: true
                    active: true
                    visible: Recorder.running
                    opacity: visible ? 1 : 0
                    scale: visible ? 1 : 0.9
                    transformOrigin: Item.Top
                    sourceComponent: recordingControls

                    Behavior on opacity { Anim { duration: 250; easing: Tokens.anim.expressiveDefaultSpatial } }
                    Behavior on scale { Anim { duration: 250; easing: Tokens.anim.expressiveDefaultSpatial } }
                }

                Behavior on opacity { Anim { duration: 250; easing: Tokens.anim.expressiveDefaultSpatial } }
                Behavior on scale { Anim { duration: 250; easing: Tokens.anim.expressiveDefaultSpatial } }
            }
            Behavior on Layout.preferredHeight {
                enabled: false // let inner list drive height; avoid damping overshoot
                Anim {}
            }
        }
    }

    // --- Bodies ---
    Component {
        id: screenshotList

        MediaList {
            props: root.props
            screenState: root.screenState
            title: "Screenshots"
            path: Paths.shotsdir
            nameFilters: ["screenshot_*.png"]
            firstIcon: "photo_library"
            firstApp: GlobalConfig.general.apps.image
            textPrefix: "Screenshot"
            expandedProp: "mediaListExpanded"
        }
    }

    Component {
        id: recordingList

        MediaList {
            props: root.props
            screenState: root.screenState
            title: "Recordings"
            path: Paths.recsdir
            nameFilters: ["recording_*.mp4"]
            firstIcon: "play_arrow"
            firstApp: GlobalConfig.general.apps.playback
            textPrefix: "Recording"
            expandedProp: "mediaListExpanded"
        }
    }

    Component {
        id: recordingControls

        RowLayout {
            spacing: Tokens.spacing.medium

            StyledRect {
                radius: Tokens.rounding.full
                color: Recorder.paused ? Colours.palette.m3tertiary : Colours.palette.m3error

                implicitWidth: recText.implicitWidth + Tokens.padding.medium * 2
                implicitHeight: recText.implicitHeight + Tokens.padding.large

                StyledText {
                    id: recText

                    anchors.centerIn: parent
                    animate: true
                    text: Recorder.paused ? Tr.trCtx("PAUSED", "recording status") : Tr.trCtx("REC", "recording status")
                    color: Recorder.paused ? Colours.palette.m3onTertiary : Colours.palette.m3onError
                    font: Tokens.font.mono.small
                }

                Behavior on implicitWidth { Anim {} }

                SequentialAnimation on opacity {
                    running: !Recorder.paused
                    alwaysRunToEnd: true
                    loops: Animation.Infinite

                    Anim { from: 1; to: 0 }
                    Anim { from: 0; to: 1 }
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: {
                    const elapsed = Recorder.elapsed;

                    const hours = Math.floor(elapsed / 3600);
                    const mins = Math.floor((elapsed % 3600) / 60);
                    const secs = Math.floor(elapsed % 60).toString().padStart(2, "0");

                    let time;
                    if (hours > 0)
                        time = `${hours}:${mins.toString().padStart(2, "0")}:${secs}`;
                    else
                        time = `${mins}:${secs}`;

                    // TRANSLATORS: %1 = elapsed recording duration, e.g. 01:23
                    return Tr.tr("Recording for %1").arg(time);
                }
                font: Tokens.font.body.medium
                elide: Text.ElideMiddle
            }

            ButtonRow {
                spacing: Tokens.spacing.extraSmall

                IconButton {
                    shapeMorph: true
                    isRound: true
                    label.animate: true
                    icon: Recorder.paused ? "play_arrow" : "pause"
                    isToggle: true
                    checked: Recorder.paused
                    type: IconButton.Tonal
                    font: Tokens.font.icon.medium
                    onClicked: {
                        Recorder.togglePause();
                        internalChecked = Recorder.paused;
                    }

                    implicitWidth: {
                        // Ensure even size so icon is centered properly
                        const h = label.implicitHeight + Tokens.padding.large * 2;
                        if (h % 2 !== 0)
                            return h + 1;
                        return h;
                    }
                }

                IconButton {
                    shapeMorph: true
                    isRound: true
                    icon: "stop"
                    inactiveColour: Colours.palette.m3error
                    inactiveOnColour: Colours.palette.m3onError
                    font: Tokens.font.icon.medium
                    onClicked: Recorder.stop()

                    implicitWidth: {
                        // Ensure even size so icon is centered properly
                        const h = label.implicitHeight + Tokens.padding.large * 2;
                        if (h % 2 !== 0)
                            return h + 1;
                        return h;
                    }
                }
            }
        }
    }

    // Delayed launch for screenshot tools
    property var pendingCommand: []

    // Helper so dynamically-created MenuItems can trigger with a delay
    function triggerShot(cmd) {
        root.screenState.utilities = false;
        root.screenState.sidebar = false;

        // Check if this is a recording command and start fast polling for instant feedback
        const isRecordingCmd = cmd.length >= 3 && cmd[0] === "caelestia" && cmd[1] === "shell" && cmd[2] === "picker" &&
                              (cmd[3] === "openRecord" || cmd[3] === "openRecordSound");
        if (isRecordingCmd) {
            Recorder.startFastPolling();
        }

        // Fullscreen screenshots don't need UI close delay - execute immediately
        if (cmd.length === 2 && cmd[0] === "caelestia" && cmd[1] === "screenshot") {
            Quickshell.execDetached(cmd);
        } else {
            // Area-based screenshots/recordings need delay for UI to close
            root.pendingCommand = cmd;
            delayTimer.restart();
        }
    }

    Timer {
        id: delayTimer
        interval: 300
        running: false
        repeat: false
        onTriggered: {
            if (root.pendingCommand.length > 0) {
                Quickshell.execDetached(root.pendingCommand);
                root.pendingCommand = [];
            }
        }
    }

    // Smooth switch: animate height, then change visibility to trigger opacity/scale animations.
    SequentialAnimation {
        id: tabSwitch
        running: false
        alwaysRunToEnd: true

        // Simple height animation for tab switch (no overshoot, let inner list handle its own bounce)
        Anim { target: body; property: "Layout.preferredHeight"; to: root.tabIndex === 0 ? shotsBody.implicitHeight : recsBody.implicitHeight; duration: 200; easing: Tokens.anim.expressiveDefaultSpatial }

        onStopped: {
            shotsBody.visible = root.tabIndex === 0;
            recsBody.visible = root.tabIndex === 1;
        }
    }
}
