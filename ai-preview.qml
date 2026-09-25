// Standalone preview: just the AI chat panel, no bar, no wallpaper, no dashboard.
// Run with: quickshell -p ai-preview.qml
import qs.components
import qs.services
import qs.config
import qs.modules.aichat as AiChatModule
import Quickshell
import Quickshell.Wayland

ShellRoot {
    PanelWindow {
        anchors.top: true
        anchors.bottom: true
        anchors.right: true

        implicitWidth: Config.sidebar.sizes.width
        color: "transparent"

        WlrLayershell.namespace: "caelestia-aichat-preview"

        StyledRect {
            anchors.fill: parent
            anchors.margins: Appearance.padding.large

            radius: Appearance.rounding.normal
            color: Colours.tPalette.m3surfaceContainerLow

            AiChatModule.AiChat {}
        }
    }
}
