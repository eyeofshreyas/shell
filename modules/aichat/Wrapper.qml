pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components

Item {
    id: root

    required property ScreenState screenState
    required property var panels

    visible: width > 0
    implicitWidth: 0

    states: State {
        name: "visible"
        when: root.screenState.aiChat

        PropertyChanges {
            root.implicitWidth: Tokens.sizes.sidebar.width
        }
    }

    transitions: [
        Transition {
            from: ""
            to: "visible"

            Anim {
                target: root
                property: "implicitWidth"
                type: Anim.DefaultSpatial
            }
        },
        Transition {
            from: "visible"
            to: ""

            Anim {
                target: root
                property: "implicitWidth"
                easing: root.panels.osd.width > 0 || root.panels.session.width > 0 ? Tokens.anim.expressiveDefaultSpatial : Tokens.anim.emphasized
            }
        }
    ]

    Loader {
        id: content

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.margins: Tokens.padding.large
        anchors.bottomMargin: 0

        active: true
        Component.onCompleted: active = Qt.binding(() => root.screenState.aiChat || root.visible)

        sourceComponent: StyledRect {
            implicitWidth: Tokens.sizes.sidebar.width - Tokens.padding.large * 2

            radius: Tokens.rounding.large
            color: Colours.tPalette.m3surfaceContainerLow

            AiChat {}
        }
    }
}
