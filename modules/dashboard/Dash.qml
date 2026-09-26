pragma ComponentBehavior: Bound

import "dash"
import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.filedialog
import qs.services

GridLayout {
    id: root

    required property ScreenState screenState
    required property FileDialog facePicker

    rowSpacing: Tokens.spacing.medium
    columnSpacing: Tokens.spacing.medium

    Rect {
        Layout.column: 2
        Layout.columnSpan: 3
        Layout.preferredWidth: Tokens.sizes.dashboard.userWidth
        Layout.fillHeight: true

        radius: Tokens.rounding.extraLarge

        User {
            id: user

            screenState: root.screenState
            facePicker: root.facePicker
        }
    }

    Rect {
        Layout.row: 0
        Layout.columnSpan: 2
        Layout.preferredWidth: Tokens.sizes.dashboard.weatherWidth
        Layout.preferredHeight: weather.implicitHeight

        radius: Tokens.rounding.extraLarge * 1.5

        SmallWeather {
            id: weather
        }
    }

    Rect {
        Layout.row: 1
        Layout.preferredWidth: dateTime.implicitWidth
        Layout.fillHeight: true

        radius: Tokens.rounding.large

        DateTime {
            id: dateTime
        }
    }

    Rect {
        Layout.row: 1
        Layout.column: 1
        Layout.columnSpan: 3
        Layout.fillWidth: true
        Layout.preferredHeight: calendar.implicitHeight

        radius: Tokens.rounding.extraLarge

        Calendar {
            id: calendar

            screenState: root.screenState
        }
    }

    Rect {
        Layout.row: 1
        Layout.column: 4
        Layout.preferredWidth: resources.implicitWidth
        Layout.fillHeight: true

        radius: Tokens.rounding.large

        Resources {
            id: resources
        }
    }

    Rect {
        Layout.row: 0
        Layout.column: 5
        Layout.rowSpan: 2
        Layout.preferredWidth: media.implicitWidth
        Layout.fillHeight: true

        radius: Tokens.rounding.extraLarge * 2

        Media {
            id: media
        }
    }

    Rect {
        Layout.row: 2
        Layout.column: 0
        Layout.columnSpan: 4
        Layout.fillWidth: true
        Layout.preferredHeight: eventsCol.implicitHeight

        visible: GCalendar.upcoming.length > 0
        radius: Tokens.rounding.large

        ColumnLayout {
            id: eventsCol

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: Tokens.padding.large
            spacing: Tokens.spacing.small

            StyledText {
                Layout.topMargin: Tokens.padding.small
                text: Tr.tr("Upcoming")
                color: Colours.palette.m3primary
                font: Tokens.font.body.builders.small.weight(Font.DemiBold).build()
            }

            Repeater {
                model: GCalendar.upcoming

                RowLayout {
                    id: eventRow

                    required property var modelData

                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small

                    Rectangle {
                        Layout.preferredWidth: 3
                        Layout.fillHeight: true
                        radius: 1.5
                        color: Colours.palette.m3tertiary
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            Layout.fillWidth: true
                            text: eventRow.modelData.summary
                            color: Colours.palette.m3onSurface
                            font: Tokens.font.body.builders.small.weight(Font.Medium).build()
                            elide: Text.ElideRight
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: {
                                let line = GCalendar.formatEventTime(eventRow.modelData);
                                if (eventRow.modelData.location)
                                    line += ` · ${eventRow.modelData.location}`;
                                return line;
                            }
                            color: Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.body.builders.small.scale(0.9).build()
                            elide: Text.ElideRight
                        }
                    }
                }
            }

            Item {
                Layout.preferredHeight: Tokens.padding.small
            }
        }
    }

    Rect {
        Layout.row: 2
        Layout.column: 4
        Layout.columnSpan: 2
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredHeight: claudeUsage.implicitHeight

        visible: GlobalConfig.services.claudeUsage.enabled || GlobalConfig.services.aiCliUsage.enabled
        radius: Tokens.rounding.large

        ClaudeUsageCard {
            id: claudeUsage

            anchors.fill: parent
        }
    }

    component Rect: StyledRect {
        color: Colours.tPalette.m3surfaceContainer
    }
}
