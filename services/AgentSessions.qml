pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // [{ id, agent, pid, project, state: "idle" | "working" | "waiting" | "error", tool, detail, edits, ts }], newest first
    // edits: [{ file, path, add, del, ts }], newest first
    property list<var> sessions: []
    // Permission requests and questions waiting on a click, oldest first:
    // [{ id, sessionId, agent, project, tool, summary, questions, hasSuggestions, conn }]
    property list<var> approvals: []

    readonly property string socketPath: `${Quickshell.env("XDG_RUNTIME_DIR") || `/run/user/${Quickshell.env("UID")}`}/caelestia-agents.sock`
    readonly property var editTools: ["Edit", "MultiEdit", "Write", "replace", "write_file"]
    property int approvalSeq: 0

    function upsert(id: string, patch: var): var {
        const old = sessions.find(s => s.id === id);
        const next = Object.assign({
            id,
            agent: "",
            pid: 0,
            project: "",
            state: "idle",
            tool: "",
            detail: "",
            edits: []
        }, old ?? {}, patch, {
            ts: Date.now()
        });
        sessions = [next, ...sessions.filter(s => s.id !== id)];
        return next;
    }

    function lineCount(text: var): int {
        return text ? String(text).split("\n").length : 0;
    }

    // Lines added/removed by a finished edit tool call, or null if it isn't one.
    function editStat(ev: var): var {
        const inp = ev.tool_input ?? {};
        const path = inp.file_path ?? inp.path;
        if (!path || !editTools.includes(ev.tool_name))
            return null;

        const stat = {
            file: String(path).split("/").pop(),
            path,
            add: 0,
            del: 0,
            ts: Date.now()
        };

        const patch = ev.tool_response?.structuredPatch;
        if (Array.isArray(patch)) {
            for (const hunk of patch)
                for (const l of hunk.lines ?? []) {
                    if (l[0] === "+")
                        stat.add++;
                    else if (l[0] === "-")
                        stat.del++;
                }
        } else if (ev.tool_name === "MultiEdit") {
            for (const e of inp.edits ?? []) {
                stat.add += lineCount(e.new_string);
                stat.del += lineCount(e.old_string);
            }
        } else if (ev.tool_name === "Write" || ev.tool_name === "write_file") {
            stat.add = lineCount(inp.content);
        } else {
            stat.add = lineCount(inp.new_string);
            stat.del = lineCount(inp.old_string);
        }
        return stat;
    }

    function toolSummary(ev: var): string {
        const inp = ev.tool_input ?? {};
        const s = inp.command ?? inp.file_path ?? inp.path ?? inp.pattern ?? inp.url ?? inp.query ?? inp.description ?? JSON.stringify(inp);
        return String(s).split("\n")[0].slice(0, 160);
    }

    function handle(line: string, conn: var): void {
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
        const base = Object.assign(project ? {
            project
        } : {}, {
            agent: ev.agent ?? "",
            pid: ev.pid ?? 0
        });

        switch (ev.hook_event_name) {
        case "SessionEnd":
            sessions = sessions.filter(s => s.id !== id);
            approvals = approvals.filter(a => a.sessionId !== id);
            break;
        case "UserPromptSubmit":
            upsert(id, Object.assign(base, {
                state: "working",
                tool: "",
                detail: ""
            }));
            break;
        case "PermissionRequest": {
            if (!conn)
                break;
            const s = upsert(id, Object.assign(base, {
                state: "waiting",
                tool: ev.tool_name ?? "",
                detail: ""
            }));
            approvalSeq++;
            approvals = [...approvals, {
                id: approvalSeq,
                sessionId: id,
                agent: s.agent,
                project: s.project,
                tool: ev.tool_name ?? "",
                summary: toolSummary(ev),
                questions: ev.tool_name === "AskUserQuestion" ? (ev.tool_input?.questions ?? []) : [],
                hasSuggestions: (ev.permission_suggestions ?? []).length > 0,
                conn
            }];
            break;
        }
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
        case "PostToolUse": {
            const stat = editStat(ev);
            upsert(id, Object.assign(base, {
                state: "working",
                tool: "",
                detail: ""
            }, stat ? {
                edits: [stat, ...(sessions.find(x => x.id === id)?.edits ?? [])].slice(0, 6)
            } : {}));
            break;
        }
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
            Quickshell.execDetached(["notify-send", "-a", "caelestia-shell", "-u", "normal", "-i", "dialog-question", `${s.agent || "Claude"} needs you - ${s.project}`, ev.message ?? ""]);
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

    // decision: "allow" | "always" | "deny" | "answer" | "ask" (agent asks in its terminal) (answers: { questionText: label | [labels] })
    function decide(approvalId: int, decision: string, answers: var): void {
        const a = approvals.find(x => x.id === approvalId);
        if (!a)
            return;

        approvals = approvals.filter(x => x.id !== approvalId);
        if (a.conn) {
            a.conn.write(JSON.stringify({
                decision,
                answers: answers ?? {}
            }) + "\n");
            a.conn.flush();
        }
        upsert(a.sessionId, {
            state: decision === "ask" ? "waiting" : "working",
            tool: "",
            detail: ""
        });
    }

    // The agent answered in its own terminal (or timed out): the relay hung up
    function dropApproval(conn: var): void {
        if (approvals.some(a => a.conn === conn))
            approvals = approvals.filter(a => a.conn !== conn);
    }

    function focusTerminal(pid: int): void {
        if (pid > 0)
            Quickshell.execDetached([Quickshell.shellPath("scripts/focus-agent-window.py"), String(pid)]);
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
            id: conn

            parser: SplitParser {
                onRead: line => root.handle(line, conn)
            }

            onConnectedChanged: {
                if (!connected)
                    root.dropApproval(conn);
            }
        }
    }
}
