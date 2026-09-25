import qs.components
import qs.services
import qs.config
import Quickshell
import QtQuick

Item {
    id: root

    required property PersistentProperties visibilities

    implicitWidth: icon.implicitHeight + Appearance.padding.small * 2
    implicitHeight: icon.implicitHeight

    StateLayer {
        // Cursed workaround to make the height larger than the parent
        anchors.fill: undefined
        anchors.centerIn: parent
        implicitWidth: implicitHeight
        implicitHeight: icon.implicitHeight + Appearance.padding.small * 2

        radius: Appearance.rounding.full

        function onClicked(): void {
            root.visibilities.sidebar = false;
            root.visibilities.aiChat = !root.visibilities.aiChat;
        }
    }

    MaterialIcon {
        id: icon

        anchors.centerIn: parent

        text: "smart_toy"
        color: Colours.palette.m3onSurface
        font.pointSize: Appearance.font.size.normal
    }
}
