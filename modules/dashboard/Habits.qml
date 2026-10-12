pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services

Item {
    id: root

    implicitWidth: layout.implicitWidth
    implicitHeight: Math.min(layout.implicitHeight, 680)

    readonly property int dateColWidth: 210
    readonly property int progressColWidth: 220
    readonly property int habitColWidth: 56

    property string editingHabitId: ""
    property int weekOffset: 0

    readonly property date today: new Date()
    readonly property string todayIso: root.isoDate(root.today)

    function isoDate(d: date): string {
        const pad = n => String(n).padStart(2, "0");
        return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
    }

    function mondayOf(d: date): date {
        const day = d.getDay(); // 0 Sun .. 6 Sat
        const diff = day === 0 ? -6 : 1 - day;
        return new Date(d.getFullYear(), d.getMonth(), d.getDate() + diff);
    }

    readonly property list<string> weekDates: {
        const monday = root.mondayOf(root.today);
        monday.setDate(monday.getDate() + root.weekOffset * 7);
        const arr = [];
        for (let i = 0; i < 7; i++)
            arr.push(root.isoDate(new Date(monday.getFullYear(), monday.getMonth(), monday.getDate() + i)));
        return arr;
    }

    function formatShortDate(iso: string): string {
        const [y, m, d] = iso.split("-").map(Number);
        return new Date(y, m - 1, d).toLocaleDateString(Qt.locale(), "MMM d");
    }

    function formatLongDate(iso: string): string {
        const [y, m, d] = iso.split("-").map(Number);
        return new Date(y, m - 1, d).toLocaleDateString(Qt.locale(), "MMMM d, yyyy");
    }

    readonly property string weekLabel: `${root.formatShortDate(root.weekDates[0])} – ${root.formatShortDate(root.weekDates[6])}, ${root.weekDates[6].split("-")[0]}`

    // Last emoji in a habit's text (common "Sleep 7-8 hours 😴" style) or its first letter, for compact column headers
    function headerGlyph(text: string): string {
        const matches = text.match(/\p{Extended_Pictographic}/gu);
        if (matches && matches.length)
            return matches[matches.length - 1];
        return text.trim().charAt(0).toUpperCase();
    }

    function addHabit(): void {
        Habits.addHabit(habitInput.text);
        habitInput.text = "";
    }

    RowLayout {
        id: layout

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: Tokens.padding.large
        anchors.rightMargin: Tokens.padding.large
        spacing: Tokens.spacing.extraLarge

        ColumnLayout {
            Layout.preferredWidth: 340
            Layout.alignment: Qt.AlignTop
            spacing: Tokens.spacing.medium

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.medium

                StyledTextField {
                    id: habitInput

                    Layout.fillWidth: true
                    placeholderText: Tr.tr("Add a habit...")
                    onAccepted: root.addHabit()
                }

                IconButton {
                    icon: "add"
                    type: IconButton.Filled
                    onClicked: root.addHabit()
                }
            }

            StyledText {
                Layout.topMargin: Tokens.spacing.large
                Layout.alignment: Qt.AlignHCenter
                visible: Habits.habits.length === 0
                text: Tr.tr("No habits yet")
                color: Colours.palette.m3onSurfaceVariant
            }

            VerticalFadeListView {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(contentHeight, 560)
                visible: Habits.habits.length > 0
                spacing: Tokens.spacing.small
                model: Habits.habits

                delegate: HabitRow {}
            }
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignTop
            spacing: Tokens.spacing.large

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.medium

                IconButton {
                    icon: "chevron_left"
                    type: IconButton.Text
                    font: Tokens.font.icon.large
                    onClicked: root.weekOffset -= 1
                }

                StyledText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: root.weekLabel
                    font: Tokens.font.title.small
                    color: Colours.palette.m3onSurface
                }

                IconButton {
                    icon: "today"
                    type: IconButton.Text
                    font: Tokens.font.icon.large
                    visible: root.weekOffset !== 0
                    onClicked: root.weekOffset = 0
                }

                IconButton {
                    icon: "chevron_right"
                    type: IconButton.Text
                    font: Tokens.font.icon.large
                    onClicked: root.weekOffset += 1
                }
            }

            ColumnLayout {
                spacing: Tokens.spacing.small

                RowLayout {
                    Layout.leftMargin: Tokens.padding.medium
                    Layout.rightMargin: Tokens.padding.medium
                    spacing: Tokens.spacing.medium

                    StyledText {
                        Layout.preferredWidth: root.dateColWidth
                        text: Tr.tr("Date")
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.medium
                    }

                    StyledText {
                        Layout.preferredWidth: root.progressColWidth
                        text: Tr.tr("Progress")
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.medium
                    }

                    Repeater {
                        model: Habits.habits

                        delegate: Item {
                            id: headerCell

                            required property var modelData

                            Layout.preferredWidth: root.habitColWidth
                            implicitHeight: glyph.implicitHeight

                            StyledText {
                                id: glyph

                                anchors.centerIn: parent
                                text: root.headerGlyph(headerCell.modelData.text)
                                color: Colours.palette.m3onSurfaceVariant
                                font: Tokens.font.title.small
                            }
                        }
                    }
                }

                Repeater {
                    model: root.weekDates

                    delegate: WeekRow {}
                }

                RowLayout {
                    Layout.topMargin: Tokens.spacing.small
                    Layout.leftMargin: Tokens.padding.medium
                    Layout.rightMargin: Tokens.padding.medium
                    spacing: Tokens.spacing.medium

                    StyledText {
                        Layout.preferredWidth: root.dateColWidth
                        text: Tr.tr("Average")
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.medium
                    }

                    Item {
                        Layout.preferredWidth: root.progressColWidth
                    }

                    Repeater {
                        model: Habits.habits

                        delegate: Item {
                            id: avgCell

                            required property var modelData

                            Layout.preferredWidth: root.habitColWidth
                            implicitHeight: avgText.implicitHeight

                            StyledText {
                                id: avgText

                                anchors.centerIn: parent
                                text: Habits.doneCountForHabit(avgCell.modelData.id, root.weekDates)
                                color: Colours.palette.m3onSurfaceVariant
                                font: Tokens.font.body.medium
                            }
                        }
                    }
                }
            }

            StyledText {
                Layout.topMargin: Tokens.spacing.large
                Layout.alignment: Qt.AlignHCenter
                visible: Habits.habits.length === 0
                text: Tr.tr("Add a habit to start tracking")
                color: Colours.palette.m3onSurfaceVariant
            }
        }
    }

    component HabitRow: StyledRect {
        id: hrow

        required property var modelData
        required property int index

        readonly property bool editing: root.editingHabitId === modelData.id
        readonly property int streak: Habits.currentStreak(modelData.id)

        width: ListView.view.width
        implicitHeight: hrowLayout.implicitHeight + Tokens.padding.medium * 2
        radius: Tokens.rounding.large
        color: Colours.tPalette.m3surfaceContainer

        RowLayout {
            id: hrowLayout

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Tokens.padding.medium
            anchors.rightMargin: Tokens.padding.medium
            spacing: Tokens.spacing.medium

            Item {
                Layout.fillWidth: true
                implicitHeight: Math.max(habitText.implicitHeight, habitEdit.implicitHeight) + Tokens.spacing.small

                StyledText {
                    id: habitText

                    visible: !hrow.editing
                    width: parent.width
                    text: hrow.modelData.text
                    wrapMode: Text.Wrap
                    font: Tokens.font.body.large
                    color: Colours.palette.m3onSurface

                    TapHandler {
                        onTapped: root.editingHabitId = hrow.modelData.id
                    }
                }

                StyledTextField {
                    id: habitEdit

                    visible: hrow.editing
                    width: parent.width
                    text: hrow.modelData.text

                    onVisibleChanged: if (visible)
                        forceActiveFocus()
                    onAccepted: {
                        Habits.editHabit(hrow.modelData.id, text);
                        root.editingHabitId = "";
                    }
                    onActiveFocusChanged: if (!activeFocus && visible) {
                        Habits.editHabit(hrow.modelData.id, text);
                        root.editingHabitId = "";
                    }
                }
            }

            RowLayout {
                visible: hrow.streak > 0
                spacing: Tokens.spacing.extraSmall / 2

                MaterialIcon {
                    text: "local_fire_department"
                    fill: 1
                    fontStyle: Tokens.font.icon.medium
                    color: Colours.palette.m3error
                }

                StyledText {
                    text: hrow.streak
                    font: Tokens.font.body.medium
                    color: Colours.palette.m3error
                }
            }

            IconButton {
                icon: "arrow_upward"
                type: IconButton.Text
                font: Tokens.font.icon.large
                disabled: hrow.index === 0
                onClicked: Habits.moveHabit(hrow.modelData.id, -1)
            }

            IconButton {
                icon: "arrow_downward"
                type: IconButton.Text
                font: Tokens.font.icon.large
                disabled: hrow.index === Habits.habits.length - 1
                onClicked: Habits.moveHabit(hrow.modelData.id, 1)
            }

            IconButton {
                icon: "delete"
                type: IconButton.Text
                font: Tokens.font.icon.large
                onClicked: Habits.removeHabit(hrow.modelData.id)
            }
        }
    }

    component WeekRow: StyledRect {
        id: weekRow

        required property string modelData

        readonly property string dateStr: modelData
        readonly property int doneCount: Habits.doneCountForDate(dateStr)
        readonly property real pct: Habits.habits.length ? doneCount / Habits.habits.length : 0
        readonly property bool isToday: dateStr === root.todayIso

        // Bundle habitId + this row's date together: a delegate nested inside this
        // component can't reach back out to "weekRow" (only the file's root id crosses
        // a Component boundary under ComponentBehavior.Bound), so pass both via modelData.
        readonly property list<var> cells: Habits.habits.map(h => ({
                    habitId: h.id,
                    dateStr: weekRow.dateStr
                }))

        Layout.fillWidth: true
        implicitHeight: weekRowLayout.implicitHeight + Tokens.padding.medium * 2
        radius: Tokens.rounding.large
        color: weekRow.isToday ? Colours.tPalette.m3surfaceContainerHigh : Colours.tPalette.m3surfaceContainer

        RowLayout {
            id: weekRowLayout

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Tokens.padding.medium
            anchors.rightMargin: Tokens.padding.medium
            spacing: Tokens.spacing.medium

            StyledText {
                Layout.preferredWidth: root.dateColWidth
                text: root.formatLongDate(weekRow.dateStr)
                font: Tokens.font.body.large
                color: weekRow.isToday ? Colours.palette.m3primary : Colours.palette.m3onSurface
            }

            RowLayout {
                Layout.preferredWidth: root.progressColWidth
                spacing: Tokens.spacing.small

                StyledRect {
                    Layout.fillWidth: true
                    implicitHeight: 14
                    radius: Tokens.rounding.full
                    color: Colours.tPalette.m3surfaceContainerHighest

                    StyledRect {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        implicitWidth: parent.width * weekRow.pct
                        radius: Tokens.rounding.full
                        color: Colours.palette.m3primary
                    }
                }

                StyledText {
                    Layout.preferredWidth: 44
                    text: `${Math.round(weekRow.pct * 100)}%`
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.medium
                }
            }

            Repeater {
                model: weekRow.cells

                delegate: IconButton {
                    id: checkCell

                    required property var modelData

                    Layout.preferredWidth: root.habitColWidth
                    font: Tokens.font.icon.large

                    icon: Habits.isDone(modelData.habitId, modelData.dateStr) ? "check_box" : "check_box_outline_blank"
                    type: IconButton.Text
                    isToggle: true
                    checked: Habits.isDone(modelData.habitId, modelData.dateStr)
                    onClicked: Habits.toggleCompletion(modelData.habitId, modelData.dateStr)
                }
            }
        }
    }
}
