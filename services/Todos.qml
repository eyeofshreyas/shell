pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils

Singleton {
    id: root

    property list<var> items: []
    property bool loaded: false

    function add(text: string): void {
        const trimmed = text.trim();
        if (!trimmed)
            return;

        items = [...items, {
                id: `${Date.now()}-${Math.random().toString(36).slice(2)}`,
                text: trimmed,
                done: false
            }];
        saveTimer.restart();
    }

    function toggle(id: string): void {
        items = items.map(item => item.id === id ? {
                    id: item.id,
                    text: item.text,
                    done: !item.done
                } : item);
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
