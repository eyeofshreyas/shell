pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils

Singleton {
    id: root

    property list<var> habits: []
    property var completions: ({})
    property bool loaded: false

    function key(habitId: string, dateStr: string): string {
        return `${habitId}_${dateStr}`;
    }

    function addHabit(text: string): void {
        const trimmed = text.trim();
        if (!trimmed)
            return;

        habits = [...habits, {
                id: `${Date.now()}-${Math.random().toString(36).slice(2)}`,
                text: trimmed
            }];
        saveTimer.restart();
    }

    function removeHabit(id: string): void {
        habits = habits.filter(h => h.id !== id);

        const pruned = {};
        for (const k in completions) {
            if (!k.startsWith(`${id}_`))
                pruned[k] = completions[k];
        }
        completions = pruned;
        saveTimer.restart();
    }

    function editHabit(id: string, text: string): void {
        const trimmed = text.trim();
        if (!trimmed)
            return;

        habits = habits.map(h => h.id === id ? Object.assign({}, h, {
            text: trimmed
        }) : h);
        saveTimer.restart();
    }

    function moveHabit(id: string, delta: int): void {
        const idx = habits.findIndex(h => h.id === id);
        const newIdx = idx + delta;
        if (idx === -1 || newIdx < 0 || newIdx >= habits.length)
            return;

        const arr = [...habits];
        [arr[idx], arr[newIdx]] = [arr[newIdx], arr[idx]];
        habits = arr;
        saveTimer.restart();
    }

    function isDone(habitId: string, dateStr: string): bool {
        return !!completions[key(habitId, dateStr)];
    }

    function toggleCompletion(habitId: string, dateStr: string): void {
        const k = key(habitId, dateStr);
        const next = Object.assign({}, completions);
        if (next[k])
            delete next[k];
        else
            next[k] = true;
        completions = next;
        saveTimer.restart();
    }

    // Count of done habits for a given date, over the given habit list
    function doneCountForDate(dateStr: string): int {
        return habits.reduce((n, h) => n + (isDone(h.id, dateStr) ? 1 : 0), 0);
    }

    // Count of dates (from the given list) a habit was completed on
    function doneCountForHabit(habitId: string, dateStrs: list<string>): int {
        return dateStrs.reduce((n, d) => n + (isDone(habitId, d) ? 1 : 0), 0);
    }

    function isoDate(d: date): string {
        const pad = n => String(n).padStart(2, "0");
        return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
    }

    // Consecutive done days up to and including today, walking backwards.
    // If today isn't done yet, it doesn't break the streak (the day isn't over).
    function currentStreak(habitId: string): int {
        const day = new Date();
        if (!isDone(habitId, isoDate(day)))
            day.setDate(day.getDate() - 1);

        let streak = 0;
        while (isDone(habitId, isoDate(day))) {
            streak++;
            day.setDate(day.getDate() - 1);
        }
        return streak;
    }

    Timer {
        id: saveTimer

        interval: 500
        onTriggered: {
            if (!root.loaded)
                return;
            storage.setText(JSON.stringify({
                habits: root.habits,
                completions: root.completions
            }));
        }
    }

    FileView {
        id: storage

        printErrors: false
        path: `${Paths.data}/habits.json`
        onLoaded: {
            try {
                const data = JSON.parse(text());
                if (Array.isArray(data.habits))
                    root.habits = data.habits;
                if (data.completions && typeof data.completions === "object")
                    root.completions = data.completions;
            } catch (error) {
                console.warn(lc, `Unable to parse habits: ${error}`);
            }
            root.loaded = true;
        }
        onLoadFailed: err => {
            root.loaded = true;
            if (err === FileViewError.FileNotFound)
                Qt.callLater(() => setText(JSON.stringify({
                    habits: [],
                    completions: {}
                })));
            else
                console.warn(lc, `Unable to load habits: ${err}`);
        }
    }

    LoggingCategory {
        id: lc

        name: "caelestia.qml.services.habits"
        defaultLogLevel: LoggingCategory.Info
    }
}
