import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components.containers
import qs.services

StyledFlickable {
    id: root

    property string openId

    implicitHeight: Math.min(col.implicitHeight, 340)
    contentHeight: col.implicitHeight
    contentWidth: width
    clip: true

    Component.onCompleted: Integrations.refreshAll(60000)

    ColumnLayout {
        id: col

        width: root.width
        spacing: 0

        Repeater {
            model: Integrations.defs

            ServiceCard {
                required property var modelData

                Layout.fillWidth: true
                def: modelData
                open: root.openId === modelData.id
                onToggled: root.openId = open ? "" : modelData.id
            }
        }
    }
}
