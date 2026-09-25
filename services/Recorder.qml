pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property alias running: props.running
    readonly property alias paused: props.paused
    readonly property alias elapsed: props.elapsed
    property int refCount: 0
    property bool needsStart
    property list<string> startArgs
    property bool needsStop
    property bool needsPause

    // Fast polling for instant feedback on recording actions started outside
    // this service (e.g. area-picker region recordings, launched directly by
    // Picker.qml via Quickshell.execDetached rather than commandProc).
    property bool fastPolling: false
    property int fastPollCount: 0

    function start(extraArgs = []): void {
        needsStart = true;
        startArgs = extraArgs;
        checkProc.running = true;
    }

    function stop(): void {
        needsStop = true;
        checkProc.running = true;
    }

    function togglePause(): void {
        needsPause = true;
        checkProc.running = true;
    }

    // Start fast polling for instant feedback (called externally for area recordings)
    function startFastPolling(): void {
        fastPolling = true;
        fastPollCount = 0;
        checkProc.running = true;
    }

    PersistentProperties {
        id: props

        property bool running: false
        property bool paused: false
        property real elapsed: 0 // Might get too large for int

        reloadableId: "recorder"
    }

    Process {
        id: checkProc

        running: true
        command: ["pidof", "gpu-screen-recorder"]
        onExited: code => { // qmllint disable signal-handler-parameters
            const running = code === 0;

            if (running && root.needsStop) {
                commandProc.exec(["caelestia", "record"]);
                props.running = false;
                props.paused = false;
            } else if (running && root.needsPause) {
                commandProc.exec(["caelestia", "record", "-p"]);
                props.paused = !props.paused;
            } else if (!running && root.needsStart) {
                commandProc.exec(["caelestia", "record", ...root.startArgs]);
                props.running = true;
                props.paused = false;
                props.elapsed = 0;
            } else if (running !== props.running && !commandProc.running) {
                // The recording was started/stopped outside the shell (e.g. via
                // keybind, or an area-picker region recording), or our command
                // finished without reaching the optimistic state
                props.running = running;
                props.paused = false;
                props.elapsed = 0;
            }

            root.needsStart = false;
            root.needsStop = false;
            root.needsPause = false;

            // Manage fast polling burst - stop after 10 fast polls (2 seconds)
            if (root.fastPolling) {
                root.fastPollCount++;
                if (root.fastPollCount >= 10) {
                    root.fastPolling = false;
                    root.fastPollCount = 0;
                }
            }
        }
    }

    Process {
        id: commandProc

        // The command owns the transition: `caelestia record` blocks on slurp for
        // region captures, and waits for the recorder to finalise the file when
        // stopping. Reconcile once it has actually finished.
        onExited: checkProc.running = true // qmllint disable signal-handler-parameters
    }

    // Only poll while something is showing the state, i.e. the utilities drawer is
    // open. Polls faster while an action is pending or during a fast-poll burst.
    Timer {
        interval: {
            if (root.fastPolling || root.needsStart || root.needsStop || root.needsPause)
                return 200; // Very fast polling for instant feedback
            return 1000;
        }
        running: root.refCount > 0
        repeat: true
        triggeredOnStart: true

        onTriggered: checkProc.running = true
    }

    Connections {
        function onSecondsChanged(): void {
            props.elapsed++;
        }

        enabled: props.running && !props.paused
        target: Time // qmllint disable incompatible-type
    }
}
