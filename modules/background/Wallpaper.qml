pragma ComponentBehavior: Bound

import QtQuick
import QtMultimedia
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.filedialog
import qs.components.images
import qs.services
import qs.utils

Item {
    id: root

    // Current wallpaper path (managed by Caelestia)
    property string source: Wallpapers.current

    // Expose the currently visible image item (for visualiser/shaders)
    readonly property Item current: activeSlot?.activeChild

    // Track which slot is currently active
    property Item activeSlot: one

    anchors.fill: parent

    // When the source changes, update the "other" slot to enable a crossfade.
    onSourceChanged: {
        if (!source) {
            activeSlot = null;
        } else {
            // Update the inactive slot
            const nextSlot = (activeSlot === one) ? two : one;
            nextSlot.loadAndBecomeActive(source);
        }
    }

    // Empty-state UI (unchanged)
    Loader {
        asynchronous: true
        anchors.fill: parent

        active: !root.source

        sourceComponent: StyledRect {
            color: Colours.palette.m3surfaceContainer

            Row {
                anchors.centerIn: parent
                spacing: Tokens.spacing.largeIncreased

                MaterialIcon {
                    text: "sentiment_stressed"
                    color: Colours.palette.m3onSurfaceVariant
                    fontStyle: Tokens.font.icon.builders.extraLarge.scale(5).build()
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Tokens.spacing.small

                    StyledText {
                        text: Tr.tr("Wallpaper missing?")
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.builders.large.size(28 * 2).weight(Font.Bold).build()
                    }

                    StyledRect {
                        implicitWidth: selectWallText.implicitWidth + Tokens.padding.extraLargeIncreased
                        implicitHeight: selectWallText.implicitHeight + Tokens.padding.small

                        radius: Tokens.rounding.full
                        color: Colours.palette.m3primary

                        FileDialog {
                            id: dialog

                            title: Tr.tr("Select a wallpaper")
                            filterLabel: Tr.tr("Image files")
                            filters: Images.validImageExtensions
                            onAccepted: path => Wallpapers.setWallpaper(path)
                        }

                        StateLayer {
                            radius: parent.radius
                            color: Colours.palette.m3onPrimary
                            onClicked: dialog.open()
                        }

                        StyledText {
                            id: selectWallText
                            anchors.centerIn: parent

                            text: Tr.tr("Set it now!")
                            color: Colours.palette.m3onPrimary
                            font: Tokens.font.body.large
                        }
                    }
                }
            }
        }
    }

    // Two slots that we crossfade between
    Img { id: one }
    Img { id: two }

    // ----------------------------------------------------------------------
    // Img: persistent dual-renderer (static + gif), no Loader, no reparenting
    // ----------------------------------------------------------------------
    component Img: Item {
        id: img
        anchors.fill: parent

        // Path we want this slot to display
        property string path: ""

        // Determine renderer
        readonly property bool isGif: path && path.toLowerCase().endsWith(".gif")
        readonly property bool isVideo: path && Images.isValidVideoByName(path.toLowerCase())

        // The child that is currently visible (staticImg, gifImg or videoOut)
        readonly property Item activeChild: isVideo ? videoOut : isGif ? gifImg : staticImg

        // Load new wallpaper and become active when ready
        function loadAndBecomeActive(newPath: string): void {
            // Redundant reload of the target this slot is already loading/showing
            // (e.g. the wallpaper state file firing multiple change events for one
            // switch): don't reset the renderers - for video that would restart the
            // decoder mid-load and it would never reach Loaded/Buffered, so the
            // crossfade would never happen. Just check whether it's ready to activate.
            if (path === newPath) {
                checkAndActivate();
                return;
            }
            path = newPath;

            staticImg.visible = false;
            staticImg.path = "";

            gifImg.visible = false;
            gifImg.playing = false;
            gifImg.source = "";

            videoLoadTimer.stop();
            videoOut.visible = false;
            videoPlayer.stop();
            videoPlayer.source = "";

            if (isVideo) {
                videoOut.visible = true;
                // Debounced: rapid successive source reassignment (e.g. fast-scrolling
                // the wallpaper picker) races the FFmpeg backend's decoder teardown.
                videoLoadTimer.restart();
            } else if (isGif) {
                gifImg.source = newPath;
                gifImg.visible = true;
            } else {
                staticImg.path = newPath;
                staticImg.visible = true;
            }

            // Check if already ready (sync/cached load)
            checkAndActivate();
        }

        // Check if ready and activate this slot
        function checkAndActivate(): void {
            if (isVideo) {
                // Qt6's QMediaPlayer::MediaStatus enum exposes LoadedMedia/BufferedMedia
                // to QML, not Loaded/Buffered - the old names silently resolved to
                // undefined, so this guard never passed and a video slot could load
                // and buffer fully without ever becoming the active (visible) slot.
                if (videoPlayer.mediaStatus !== MediaPlayer.LoadedMedia && videoPlayer.mediaStatus !== MediaPlayer.BufferedMedia)
                    return;
            } else if (activeChild.status !== Image.Ready) {
                return;
            }

            // Start GIF playback
            if (isGif) {
                gifImg.currentFrame = 0;
                gifImg.playing = true;
            }

            // Make this slot active
            root.activeSlot = img;
        }

        // Crossfade/scale state lives on the slot wrapper
        opacity: 0
        scale: Wallpapers.showPreview ? 1 : 0.8

        // --- Static renderer (persistent) ---
        CachingImage {
            id: staticImg
            anchors.fill: parent
            visible: false

            onStatusChanged: {
                if (status === Image.Ready && visible) {
                    img.checkAndActivate();
                }
            }
        }

        // --- GIF renderer (persistent AnimatedImage) ---
        AnimatedImage {
            id: gifImg
            anchors.fill: parent
            visible: false
            cache: false
            asynchronous: false
            playing: false
            fillMode: Image.PreserveAspectCrop

            onStatusChanged: {
                if (status === Image.Ready && visible) {
                    img.checkAndActivate();
                }
            }

            onVisibleChanged: {
                if (!visible) playing = false;
            }
        }

        // --- Video renderer (persistent MediaPlayer + VideoOutput) ---
        Timer {
            id: videoLoadTimer
            interval: 150
            onTriggered: {
                videoPlayer.source = img.path;
                videoPlayer.play();
            }
        }

        VideoOutput {
            id: videoOut
            anchors.fill: parent
            visible: false
            fillMode: VideoOutput.PreserveAspectCrop

            onVisibleChanged: {
                if (!visible) videoPlayer.pause();
            }
        }

        MediaPlayer {
            id: videoPlayer
            loops: MediaPlayer.Infinite
            videoOutput: videoOut

            onMediaStatusChanged: {
                if ((mediaStatus === MediaPlayer.LoadedMedia || mediaStatus === MediaPlayer.BufferedMedia) && videoOut.visible)
                    img.checkAndActivate();
            }
        }

        // Animate *this slot* (not the child), to avoid touching decoder items
        states: State {
            name: "visible"
            when: root.activeSlot === img
            PropertyChanges { target: img; opacity: 1; scale: 1 }
        }

        transitions: [
            Transition {
                to: "visible"
                ParallelAnimation {
                    Anim {
                        target: img
                        property: "opacity"
                        type: Anim.StandardLarge
                    }
                    Anim {
                        target: img
                        property: "scale"
                        type: Anim.StandardLarge
                    }
                }
            },
            Transition {
                from: "visible"; to: ""
                ParallelAnimation {
                    Anim {
                        target: img
                        property: "opacity"
                        type: Anim.StandardLarge
                    }
                    Anim {
                        target: img
                        property: "scale"
                        type: Anim.StandardLarge
                    }
                }
            }
        ]

        // Initialize once at creation
        Component.onCompleted: {
            if (root.source && root.activeSlot === img) {
                loadAndBecomeActive(root.source);
            }
        }
    }
}
