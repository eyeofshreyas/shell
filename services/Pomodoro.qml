pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property int focusSecs: 25 * 60
    readonly property int breakSecs: 5 * 60

    property bool focus: true
    property bool running: false
    property int secondsLeft: focusSecs
    property int sessionsToday: 0

    readonly property string label: `${String(Math.floor(secondsLeft / 60)).padStart(2, "0")}:${String(secondsLeft % 60).padStart(2, "0")}`

    // Wall-clock end time, so the countdown doesn't drift if a tick is delayed
    property double endsAt: 0

    function toggle(): void {
        if (running) {
            running = false;
        } else {
            endsAt = Date.now() + secondsLeft * 1000;
            running = true;
        }
    }

    function reset(): void {
        running = false;
        secondsLeft = focus ? focusSecs : breakSecs;
    }

    function skip(): void {
        focus = !focus;
        reset();
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.running
        onTriggered: {
            root.secondsLeft = Math.max(0, Math.round((root.endsAt - Date.now()) / 1000));
            if (root.secondsLeft > 0)
                return;

            if (root.focus)
                root.sessionsToday++;
            Quickshell.execDetached(["notify-send", "-a", "caelestia-shell", "-u", "normal", "-i", "timer", root.focus ? "Focus session done" : "Break over", root.focus ? "Take a 5 minute break." : "Time to focus."]);
            root.skip();
        }
    }
}
