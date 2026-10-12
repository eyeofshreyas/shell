pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.components.effects
import qs.services

Item {
    id: root

    signal close

    implicitWidth: card.implicitWidth
    implicitHeight: card.implicitHeight

    Component.onCompleted: DisplayMode.refreshConnected()

    Elevation {
        anchors.fill: card
        radius: card.radius
        level: 2
    }

    StyledRect {
        id: card

        implicitWidth: column.implicitWidth + Tokens.padding.large * 2
        implicitHeight: column.implicitHeight + Tokens.padding.large * 2
        radius: Tokens.rounding.large
        color: Colours.palette.m3surfaceContainerLow

        ColumnLayout {
            id: column

            anchors.centerIn: parent
            spacing: Tokens.spacing.small

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: Tokens.spacing.small
                text: Tr.tr("Display Mode")
                font: Tokens.font.title.medium
            }

            ModeButton {
                id: pcOnlyBtn

                mode: DisplayMode.PcOnly
                icon: "laptop_mac"
                text: Tr.tr("PC screen only")
                modeEnabled: true

                KeyNavigation.down: mirrorBtn

                Component.onCompleted: forceActiveFocus()
            }

            ModeButton {
                id: mirrorBtn

                mode: DisplayMode.Mirror
                icon: "cast"
                text: Tr.tr("Duplicate / Mirror")
                modeEnabled: DisplayMode.externalConnected

                KeyNavigation.up: pcOnlyBtn
                KeyNavigation.down: extendBtn
            }

            ModeButton {
                id: extendBtn

                mode: DisplayMode.Extend
                icon: "aspect_ratio"
                text: Tr.tr("Extend")
                modeEnabled: DisplayMode.externalConnected

                KeyNavigation.up: mirrorBtn
                KeyNavigation.down: secondOnlyBtn
            }

            ModeButton {
                id: secondOnlyBtn

                mode: DisplayMode.SecondOnly
                icon: "desktop_windows"
                text: Tr.tr("Second screen only")
                modeEnabled: DisplayMode.externalConnected

                KeyNavigation.up: extendBtn
            }
        }
    }

    component ModeButton: IconTextButton {
        id: button

        required property int mode
        required property bool modeEnabled

        Layout.fillWidth: true
        horizontalPadding: Tokens.padding.large
        checked: DisplayMode.currentMode === mode
        disabled: !modeEnabled

        activeColour: Colours.palette.m3primaryContainer
        activeOnColour: Colours.palette.m3onPrimaryContainer
        inactiveColour: activeFocus ? Colours.palette.m3secondaryContainer : Colours.tPalette.m3surfaceContainer
        inactiveOnColour: activeFocus ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface

        function apply(): void {
            if (button.disabled)
                return;
            DisplayMode.apply(button.mode);
            root.close();
        }

        onClicked: apply()

        Keys.onEnterPressed: apply()
        Keys.onReturnPressed: apply()
        Keys.onEscapePressed: root.close()
    }
}
