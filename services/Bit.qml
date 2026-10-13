pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils

// Bit's state (mirrors the agents) and the user's choices for it: outfit, desktop Bit, sounds.
Singleton {
    id: root

    readonly property string name: "Coco"

    // "auto" = seasonal outfit, "none" = bare, otherwise an outfit id
    property string outfitPref: "auto"
    property bool desktop: false
    property bool sounds: true
    property bool walk: true
    property bool talk: true
    property real deskX: -1
    property real deskY: -1
    property bool loaded: false

    readonly property var sessions: AgentSessions.sessions
    readonly property var lead: sessions.find(x => x.state === "waiting") ?? sessions.find(x => x.state === "error") ?? sessions.find(x => x.state === "working")
    readonly property string tool: lead?.tool ?? ""
    readonly property string mood: sessions.some(x => x.state === "waiting") ? "waiting" : sessions.some(x => x.state === "error") ? "error" : sessions.some(x => x.state === "working") ? "working" : sessions.length > 0 ? "idle" : "sleep"
    readonly property bool dancing: Players.active?.isPlaying ?? false
    readonly property bool tired: ClaudeUsage.enabled && Math.max(ClaudeUsage.sessionUtilization, ClaudeUsage.weeklyUtilization) >= 0.95
    readonly property bool alarmed: mood === "waiting" || mood === "error"
    readonly property color body: alarmed ? Colours.palette.m3errorContainer : Colours.palette.m3primary
    readonly property color eye: alarmed ? Colours.palette.m3onErrorContainer : Colours.palette.m3onPrimary
    readonly property color accent: Colours.palette.m3error

    readonly property string seasonal: {
        const d = new Date();
        const md = (d.getMonth() + 1) * 100 + d.getDate();
        if (md >= 1020 && md <= 1101)
            return "pumpkin";
        if (md >= 1215 && md <= 1226)
            return "santa";
        if (md >= 1231 || md <= 102)
            return "party";
        return "";
    }
    readonly property string outfit: outfitPref === "auto" ? seasonal : outfitPref === "none" ? "" : outfitPref

    property string prevMood: mood
    readonly property int pending: AgentSessions.approvals.length
    property int prevPending: 0

    function play(name: string): void {
        if (sounds)
            Quickshell.execDetached(["pw-play", "--volume=0.6", Quickshell.shellPath(`assets/sounds/${name}.wav`)]);
    }

    function save(): void {
        saveTimer.restart();
    }

    function setOutfit(id: string): void {
        outfitPref = id;
        save();
    }

    function setDesktop(on: bool): void {
        desktop = on;
        save();
    }

    function setWalk(on: bool): void {
        walk = on;
        save();
    }

    function setTalk(on: bool): void {
        talk = on;
        save();
    }

    function setSounds(on: bool): void {
        sounds = on;
        save();
    }

    function moveDesktop(x: real, y: real): void {
        deskX = x;
        deskY = y;
        save();
    }

    // Approve or refuse the oldest plain permission request from the keyboard (questions are answered on the card)
    function decideFirst(decision: string): void {
        const a = AgentSessions.approvals.find(x => x.questions.length === 0);
        if (a)
            AgentSessions.decide(a.id, decision, {});
    }

    function jumpToWaiting(): void {
        const s = sessions.find(x => x.state === "waiting") ?? sessions[0];
        if (s)
            AgentSessions.focusTerminal(s.pid);
    }

    onMoodChanged: {
        if (mood === "error")
            play("oops");
        else if (mood === "idle" && (prevMood === "working" || prevMood === "waiting"))
            play("done");
        prevMood = mood;
    }

    onPendingChanged: {
        if (pending > prevPending)
            play("ask");
        prevPending = pending;
    }

    Timer {
        id: saveTimer

        interval: 500
        onTriggered: {
            if (root.loaded)
                file.setText(JSON.stringify({
                    outfit: root.outfitPref,
                    desktop: root.desktop,
                    sounds: root.sounds,
                    walk: root.walk,
                    talk: root.talk,
                    deskX: root.deskX,
                    deskY: root.deskY
                }));
        }
    }

    FileView {
        id: file

        printErrors: false
        path: `${Paths.data}/bit.json`
        onLoaded: {
            try {
                const d = JSON.parse(text());
                root.outfitPref = String(d.outfit ?? "auto");
                root.desktop = !!d.desktop;
                root.sounds = d.sounds !== false;
                root.walk = d.walk !== false;
                root.talk = d.talk !== false;
                root.deskX = Number(d.deskX ?? -1);
                root.deskY = Number(d.deskY ?? -1);
            } catch (e) {
                console.warn("bit.json unreadable, using defaults");
            }
            root.loaded = true;
        }
        onLoadFailed: root.loaded = true
    }
}
