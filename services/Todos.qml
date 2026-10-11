pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils

Singleton {
    id: root

    property list<var> items: []
    property bool loaded: false

    readonly property var priorities: ["none", "low", "medium", "high"]

    function add(text: string, dueDate: string, dueTime: string, priority: string): void {
        const trimmed = text.trim();
        if (!trimmed)
            return;

        items = [...items, {
                id: `${Date.now()}-${Math.random().toString(36).slice(2)}`,
                text: trimmed,
                done: false,
                dueDate: dueDate ?? "",
                dueTime: dueDate ? (dueTime ?? "") : "",
                priority: priorities.includes(priority) ? priority : "none"
            }];
        saveTimer.restart();
    }

    function move(id: string, delta: int): void {
        const idx = items.findIndex(i => i.id === id);
        const newIdx = idx + delta;
        if (idx === -1 || newIdx < 0 || newIdx >= items.length)
            return;

        const arr = [...items];
        [arr[idx], arr[newIdx]] = [arr[newIdx], arr[idx]];
        items = arr;
        saveTimer.restart();
    }

    // Local midnight (or local due time, if set) as a timestamp, or null if no due date
    function dueTimestamp(item: var): var {
        if (!item.dueDate)
            return null;

        const [y, mo, d] = item.dueDate.split("-").map(Number);
        if (item.dueTime) {
            const [h, mi] = item.dueTime.split(":").map(Number);
            return new Date(y, mo - 1, d, h, mi).getTime();
        }
        return new Date(y, mo - 1, d).getTime();
    }

    function toggle(id: string): void {
        items = items.map(item => item.id === id ? Object.assign({}, item, {
            done: !item.done
        }) : item);
        saveTimer.restart();
    }

    function cyclePriority(id: string): void {
        items = items.map(item => {
            if (item.id !== id)
                return item;
            const next = priorities[(priorities.indexOf(item.priority ?? "none") + 1) % priorities.length];
            return Object.assign({}, item, {
                priority: next
            });
        });
        saveTimer.restart();
    }

    function editText(id: string, text: string): void {
        const trimmed = text.trim();
        if (!trimmed)
            return;

        items = items.map(item => item.id === id ? Object.assign({}, item, {
            text: trimmed
        }) : item);
        saveTimer.restart();
    }

    function editDueDate(id: string, dueDate: string, dueTime: string): void {
        items = items.map(item => item.id === id ? Object.assign({}, item, {
            dueDate: dueDate ?? "",
            dueTime: dueDate ? (dueTime ?? "") : ""
        }) : item);
        saveTimer.restart();
    }

    function addPomodoro(id: string): void {
        items = items.map(item => item.id === id ? Object.assign({}, item, {
            pomodoros: (item.pomodoros ?? 0) + 1
        }) : item);
        saveTimer.restart();
    }

    function remove(id: string): void {
        items = items.filter(item => item.id !== id);
        saveTimer.restart();
    }

    Timer {
        id: saveTimer

        interval: 500
        onTriggered: {
            if (!root.loaded)
                return;
            storage.setText(JSON.stringify(root.items));
        }
    }

    property var remindedSet: new Set()

    // Remind once when a task's due date/time arrives, same pattern as GCalendar's reminder timer
    Timer {
        interval: 60000
        running: root.loaded
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            const now = Date.now();
            for (const item of root.items) {
                if (item.done || root.remindedSet.has(item.id))
                    continue;
                const ts = root.dueTimestamp(item);
                if (ts === null || ts > now)
                    continue;
                root.remindedSet.add(item.id);
                Quickshell.execDetached(["notify-send", "-a", "caelestia-shell", "-u", "normal", "-i", "calendar", now - ts > 86400000 ? "Overdue task" : "Task due", item.text]);
            }
        }
    }

    FileView {
        id: storage

        printErrors: false
        path: `${Paths.data}/todos.json`
        onLoaded: {
            try {
                const data = JSON.parse(text());
                if (Array.isArray(data))
                    root.items = data;
            } catch (error) {
                console.warn(lc, `Unable to parse todos: ${error}`);
            }
            root.loaded = true;
        }
        onLoadFailed: err => {
            root.loaded = true;
            if (err === FileViewError.FileNotFound)
                Qt.callLater(() => setText("[]"));
            else
                console.warn(lc, `Unable to load todos: ${err}`);
        }
    }

    LoggingCategory {
        id: lc

        name: "caelestia.qml.services.todos"
        defaultLogLevel: LoggingCategory.Info
    }
}
