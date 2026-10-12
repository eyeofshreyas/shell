import QtQuick
import "../dashboard/dash"
import qs.services

// Bit sitting on the desktop; drag it anywhere, the spot is remembered.
Item {
    id: root

    implicitWidth: 96
    implicitHeight: 96
    x: Bit.deskX >= 0 ? Math.min(Bit.deskX, parent.width - width) : parent.width - width - 80
    y: Bit.deskY >= 0 ? Math.min(Bit.deskY, parent.height - height) : parent.height - height - 140

    BitMascot {
        anchors.fill: parent
        scale: 1.5
    }

    DragHandler {
        id: drag

        target: root
        xAxis.minimum: 0
        xAxis.maximum: root.parent.width - root.width
        yAxis.minimum: 0
        yAxis.maximum: root.parent.height - root.height
        onActiveChanged: if (!active)
            Bit.moveDesktop(root.x, root.y)
    }
}
