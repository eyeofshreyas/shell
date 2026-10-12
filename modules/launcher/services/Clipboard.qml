pragma Singleton

import ".."
import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.utils

Searcher {
    id: root

    function transformSearch(search: string): string {
        return search.slice(`${GlobalConfig.launcher.actionPrefix}clip `.length);
    }

    function reload(): void {
        getEntries.running = true;
    }

    list: entries.instances
    key: "preview"

    Variants {
        id: entries

        Entry {}
    }

    // Watches the system clipboard and feeds it into cliphist for the lifetime of the shell.
    Process {
        running: true
        command: ["wl-paste", "--watch", "cliphist", "store", "-max-items", "100"]
    }

    Process {
        id: getEntries

        running: true
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                entries.model = text.trim().split("\n").filter(l => l.length > 0).map(line => {
                    const tab = line.indexOf("\t");
                    return {
                        id: line.slice(0, tab),
                        preview: line.slice(tab + 1)
                    };
                });
            }
        }
    }

    component Entry: QtObject {
        required property var modelData
        readonly property string id: modelData.id
        readonly property string preview: modelData.preview

        function onClicked(list: AppList): void {
            list.screenState.launcher = false;
            // $1 keeps the id out of the shell string, even though cliphist ids are always numeric
            Quickshell.execDetached(["sh", "-c", "cliphist decode \"$1\" | wl-copy", "sh", id]);
        }
    }
}
