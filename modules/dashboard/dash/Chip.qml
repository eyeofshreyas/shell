import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

StyledRect {
    id: root

    required property string label
    property bool current
    property int badge

    signal clicked

    implicitWidth: row.implicitWidth + Tokens.padding.medium * 2
    implicitHeight: row.implicitHeight + Tokens.padding.small * 2
    radius: Tokens.rounding.full
    color: current ? Colours.palette.m3secondaryContainer : Colours.tPalette.m3surfaceContainerHigh

    StateLayer {
        color: root.current ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
        onClicked: root.clicked()
    }

    RowLayout {
        id: row

        anchors.centerIn: parent
        spacing: Tokens.spacing.small

        StyledText {
            text: root.label
            color: root.current ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
            font: Tokens.font.body.builders.small.weight(root.current ? Font.DemiBold : Font.Normal).build()
        }

        Rectangle {
            visible: root.badge > 0
            implicitWidth: Math.max(implicitHeight, badgeText.implicitWidth + Tokens.padding.small)
            implicitHeight: badgeText.implicitHeight
            radius: height / 2
            color: Colours.palette.m3primary

            StyledText {
                id: badgeText

                anchors.centerIn: parent
                text: root.badge
                color: Colours.palette.m3onPrimary
                font: Tokens.font.body.builders.small.scale(0.8).weight(Font.DemiBold).build()
            }
        }
    }
}
