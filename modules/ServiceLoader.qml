import QtQuick
import Quickshell
import Caelestia.Config
import qs.services
import qs.modules.launcher.services

Scope {
    Component.onCompleted: {
        // Force certain singletons to load on shell init instead of lazily

        IdleInhibitor;
        GameMode;
        Notifs;
        Players;
        Brightness;
        Weather.reload();
        Clipboard;
        AgentSessions;

        if (GlobalConfig.utilities.vpn.enabled)
            VPN;
    }
}
