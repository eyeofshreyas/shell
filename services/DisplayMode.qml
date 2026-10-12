pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Caelestia
import Caelestia.I18n
import qs.services

Singleton {
    id: root

    enum Mode {
        PcOnly,
        Mirror,
        Extend,
        SecondOnly
    }

    // Internal laptop panel is always named eDP-*; external is whatever else is connected.
    // Resolved fresh on every refresh so renamed/replugged monitors just work.
    property string internalName: ""
    property string externalName: ""

    readonly property bool externalConnected: !!root.externalName

    // Only reflects currently enabled monitors (Hyprland excludes disabled ones from "monitors")
    readonly property int currentMode: {
        const mons = Hypr.monitors.values;
        const ext = root.externalName && mons.find(m => m.name === root.externalName);
        const lap = root.internalName && mons.find(m => m.name === root.internalName);
        if (ext && !lap)
            return DisplayMode.SecondOnly;
        if (lap && !ext)
            return DisplayMode.PcOnly;
        if (lap && ext)
            return ext.lastIpcObject?.mirrorOf && ext.lastIpcObject.mirrorOf !== "none" ? DisplayMode.Mirror : DisplayMode.Extend;
        return -1;
    }

    function refreshConnected(): void {
        checkProc.exec(["hyprctl", "monitors", "all", "-j"]);
    }

    // Hyprland's "keyword" command is rejected outright on Lua-config builds
    // ("keyword can't work with non-legacy parsers. Use eval."), so those need
    // "eval hl.monitor({...})" instead. hl.monitor() merges fields rather than
    // replacing, so mirror/disabled are always passed explicitly to avoid
    // leftover state from a previous mode.
    function monitorCmd(name: string, opts: var): string {
        if (Hypr.usingLua) {
            const fields = [`output = "${name}"`];
            if (opts.disabled !== undefined)
                fields.push(`disabled = ${opts.disabled}`);
            if (opts.mode !== undefined)
                fields.push(`mode = "${opts.mode}"`);
            if (opts.position !== undefined)
                fields.push(`position = "${opts.position}"`);
            if (opts.scale !== undefined)
                fields.push(`scale = ${opts.scale}`);
            if (opts.mirror !== undefined)
                fields.push(`mirror = "${opts.mirror}"`);
            return `eval hl.monitor({ ${fields.join(", ")} })`;
        }

        if (opts.disabled)
            return `keyword monitor ${name},disable`;
        const mirrorPart = opts.mirror && opts.mirror !== "none" ? `,mirror,${opts.mirror}` : "";
        return `keyword monitor ${name},${opts.mode},${opts.position},${opts.scale}${mirrorPart}`;
    }

    function apply(mode: int): void {
        if (mode !== DisplayMode.PcOnly && !root.externalConnected) {
            Toaster.toast(Tr.tr("Display unchanged"), Tr.tr("No external monitor connected"), "desktop_access_disabled", Toast.Warning);
            return;
        }

        const lap = root.internalName;
        const ext = root.externalName;

        let cmds;
        switch (mode) {
        case DisplayMode.PcOnly:
            cmds = [root.monitorCmd(ext, {
                    disabled: true
                }), root.monitorCmd(lap, {
                    mode: "preferred",
                    position: "0x0",
                    scale: 1,
                    mirror: "none",
                    disabled: false
                })];
            break;
        case DisplayMode.Mirror:
            cmds = [root.monitorCmd(lap, {
                    mode: "preferred",
                    position: "0x0",
                    scale: 1,
                    mirror: "none",
                    disabled: false
                }), root.monitorCmd(ext, {
                    mode: "preferred",
                    position: "auto",
                    scale: 1,
                    mirror: lap,
                    disabled: false
                })];
            break;
        case DisplayMode.Extend:
            cmds = [root.monitorCmd(lap, {
                    mode: "preferred",
                    position: "0x0",
                    scale: 1,
                    mirror: "none",
                    disabled: false
                }), root.monitorCmd(ext, {
                    mode: "preferred",
                    position: "auto-right",
                    scale: 1,
                    mirror: "none",
                    disabled: false
                })];
            break;
        case DisplayMode.SecondOnly:
            cmds = [root.monitorCmd(lap, {
                    disabled: true
                }), root.monitorCmd(ext, {
                    mode: "preferred",
                    position: "0x0",
                    scale: 1,
                    mirror: "none",
                    disabled: false
                })];
            break;
        default:
            return;
        }

        Hypr.extras.batchMessage(cmds);

        const labels = [Tr.tr("PC screen only"), Tr.tr("Duplicate / Mirror"), Tr.tr("Extend"), Tr.tr("Second screen only")];
        Toaster.toast(Tr.tr("Display mode changed"), labels[mode], "monitor", Toast.Success);
    }

    Component.onCompleted: refreshConnected()

    Connections {
        function onRawEvent(event: HyprlandEvent): void {
            if (event.name === "monitoradded" || event.name === "monitorremoved")
                root.refreshConnected();
        }

        target: Hyprland
    }

    Process {
        id: checkProc

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const mons = JSON.parse(text);
                    root.internalName = mons.find(m => m.name.startsWith("eDP"))?.name ?? mons[0]?.name ?? "";
                    root.externalName = mons.find(m => m.name !== root.internalName)?.name ?? "";
                } catch (e) {
                    console.warn("DisplayMode: failed to parse hyprctl monitors output", e);
                }
            }
        }
    }
}
