pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // [{ id, project, state: "idle" | "working" | "waiting", tool, ts }], newest first
    property list<var> sessions: []

    readonly property string socketPath: `${Quickshell.env("XDG_RUNTIME_DIR") || `/run/user/${Quickshell.env("UID")}`}/caelestia-agents.sock`

    function upsert(id: string, patch: var): var {
        const old = sessions.find(s => s.id === id);
        const next = Object.assign({
            id,
            project: "",
            state: "idle",
            tool: "",
            detail: ""
        }, old ?? {}, patch, {
            ts: Date.now()
        });
        sessions = [next, ...sessions.filter(s => s.id !== id)];
        return next;
    }

    function handle(line: string): void {
        let ev;
        try {
            ev = JSON.parse(line);
        } catch (e) {
            return;
        }

        const id = ev.session_id;
        if (!id)
            return;

        const project = ev.cwd ? ev.cwd.split("/").filter(p => p).pop() : undefined;
        const base = project ? {
            project
        } : {};

        switch (ev.hook_event_name) {
        case "SessionEnd":
            sessions = sessions.filter(s => s.id !== id);
            break;
        case "UserPromptSubmit":
            upsert(id, Object.assign(base, {
                state: "working",
                tool: "",
                detail: ""
            }));
            break;
        case "PreToolUse": {
            const inp = ev.tool_input ?? {};
            const detail = inp.file_path ? inp.file_path.split("/").pop() : (inp.command ?? inp.pattern ?? inp.query ?? inp.url ?? inp.description ?? "");
            upsert(id, Object.assign(base, {
                state: ev.tool_name === "AskUserQuestion" ? "waiting" : "working",
                tool: ev.tool_name ?? "",
                detail: String(detail).split("\n")[0].slice(0, 60)
            }));
            break;
        }
        case "PostToolUse":
            upsert(id, Object.assign(base, {
                state: "working",
                tool: "",
                detail: ""
            }));
            break;
        case "PostToolUseFailure":
            upsert(id, Object.assign(base, {
                state: "error",
                tool: ev.tool_name ?? "",
                detail: String(ev.error ?? "").split("\n")[0].slice(0, 60)
            }));
            break;
        case "Notification": {
            const asking = sessions.find(x => x.id === id)?.tool === "AskUserQuestion";
            const s = upsert(id, Object.assign(base, {
                state: "waiting",
                tool: asking ? "AskUserQuestion" : "",
                detail: ""
            }));
            Quickshell.execDetached(["notify-send", "-a", "caelestia-shell", "-u", "normal", "-i", "dialog-question", `Claude needs you - ${s.project}`, ev.message ?? ""]);
            break;
        }
        case "Stop":
            upsert(id, Object.assign(base, {
                state: "idle",
                tool: "",
                detail: ""
            }));
            break;
        default:
            upsert(id, base);
        }
    }

    // A failed tool call is a brief reaction, not a lasting state
    Timer {
        interval: 1000
        repeat: true
        running: root.sessions.some(s => s.state === "error")
        onTriggered: {
            for (const s of root.sessions) {
                if (s.state === "error" && Date.now() - s.ts > 5000)
                    root.upsert(s.id, {
                        state: "working",
                        tool: "",
                        detail: ""
                    });
            }
        }
    }

    // Drop sessions whose SessionEnd never arrived (crashed terminal, killed agent)
    Timer {
        interval: 60000
        repeat: true
        running: root.sessions.length > 0
        onTriggered: root.sessions = root.sessions.filter(s => Date.now() - s.ts < 30 * 60000)
    }

    SocketServer {
        active: true
        path: root.socketPath

        handler: Socket {
            parser: SplitParser {
                onRead: line => root.handle(line)
            }
        }
    }
}
