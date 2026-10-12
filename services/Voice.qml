pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils

// Push-to-talk for Bit: toggle to record, toggle again to transcribe and send the text to the AI chat.
// Needs pw-record (PipeWire) and whisper-cli (whisper.cpp) with a model at ~/.local/share/caelestia/whisper-model.bin.
Singleton {
    id: root

    readonly property string wav: "/tmp/quickshell/voice.wav"
    readonly property string model: `${Paths.data}/whisper-model.bin`
    // "idle" | "listening" | "thinking"
    property string state: "idle"

    function toggle(): void {
        if (state === "idle") {
            state = "listening";
            recorder.running = true;
        } else if (state === "listening") {
            state = "thinking";
            recorder.signal(2); // SIGINT lets pw-record finish the wav header
        }
    }

    function notify(text: string): void {
        notifier.exec(["notify-send", "-a", "Bit", "Bit", text]);
    }

    function send(text: string): void {
        Ai.sendUserMessage(text);
        ShellState.forActive().aiChat = true;
    }

    Process {
        id: recorder

        command: ["sh", "-c", `mkdir -p /tmp/quickshell && exec pw-record --rate 16000 --channels 1 ${root.wav}`]
        onExited: if (root.state === "thinking")
            transcriber.running = true
        else if (root.state === "listening") {
            root.state = "idle";
            root.notify("Could not record (is pw-record working?)");
        }
    }

    Process {
        id: transcriber

        command: ["sh", "-c", `command -v whisper-cli >/dev/null || exit 127; [ -f "${root.model}" ] || exit 126; whisper-cli -m "${root.model}" -f ${root.wav} -nt -np`]
        stdout: StdioCollector {
            id: heard
        }
        onExited: code => {
            root.state = "idle";
            const text = heard.text.trim();
            if (code === 127)
                root.notify("Install whisper.cpp (whisper-cli) to talk to Bit");
            else if (code === 126)
                root.notify("Put a whisper model at ~/.local/share/caelestia/whisper-model.bin");
            else if (code !== 0 || text.length === 0 || /^[\[(].*[\])]$/.test(text))
                root.notify("Did not catch that");
            else
                root.send(text);
        }
    }

    Process {
        id: notifier
    }
}
