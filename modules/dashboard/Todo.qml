pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
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

    implicitWidth: 640
    implicitHeight: Math.min(layout.implicitHeight, 520)

    property string pendingPriority: "none"

    readonly property var priorityColours: ({
            none: Colours.palette.m3onSurfaceVariant,
            low: Colours.palette.m3secondary,
            medium: Colours.palette.m3tertiary,
            high: Colours.palette.m3error
        })

    readonly property var priorityOrder: ({
            high: 0,
            medium: 1,
            low: 2,
            none: 3
        })

    readonly property var dateRegex: /^\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])$/
    readonly property var timeRegex: /^([01]\d|2[0-3]):[0-5]\d$/

    readonly property list<string> sortModes: ["added", "due", "priority"]
    property string sortMode: "added"
    readonly property var sortModeLabels: ({
            added: Tr.tr("Added"),
            due: Tr.tr("Due date"),
            priority: Tr.tr("Priority")
        })

    readonly property list<var> sortedItems: {
        const arr = [...Todos.items];
        if (sortMode === "due") {
            arr.sort((a, b) => (a.dueDate || "9999-99-99").localeCompare(b.dueDate || "9999-99-99"));
        } else if (sortMode === "priority") {
            arr.sort((a, b) => priorityOrder[a.priority ?? "none"] - priorityOrder[b.priority ?? "none"]);
        }
        return arr;
    }

    // "" targets the add-task row's date field; otherwise the id of the task row being edited
    property string editingDateId: ""
    property string editingTextId: ""
    property bool showDatePicker: false
    property date pickerDate: new Date()
    property string pendingDueTime: ""

    function isoDate(d: date): string {
        const pad = n => String(n).padStart(2, "0");
        return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
    }

    function openDatePicker(targetId: string, currentDate: string, currentTime: string): void {
        if (showDatePicker && editingDateId === targetId) {
            showDatePicker = false;
            return;
        }

        editingDateId = targetId;
        if (root.dateRegex.test(currentDate)) {
            const [y, m, d] = currentDate.split("-").map(Number);
            pickerDate = new Date(y, m - 1, d);
        } else {
            pickerDate = new Date();
        }
        timeInput.text = root.timeRegex.test(currentTime) ? currentTime : "";
        timeInput.isError = false;
        showDatePicker = true;
    }

    function pickDate(dateStr: string): void {
        if (!timeInput.valid) {
            timeInput.isError = true;
            return;
        }

        const timeVal = timeInput.text === ":" ? "" : timeInput.text;
        if (editingDateId === "") {
            dueDateInput.text = dateStr;
            dueDateInput.isError = false;
            pendingDueTime = timeVal;
        } else {
            Todos.editDueDate(editingDateId, dateStr, timeVal);
        }
        showDatePicker = false;
    }

    function clearDate(): void {
        timeInput.text = "";
        pickDate("");
    }

    function cycleSortMode(): void {
        sortMode = sortModes[(sortModes.indexOf(sortMode) + 1) % sortModes.length];
    }

    function submit(): void {
        if (!dueDateInput.valid) {
            dueDateInput.isError = true;
            return;
        }

        const dueDate = dueDateInput.text === "--" ? "" : dueDateInput.text;
        Todos.add(input.text, dueDate, pendingDueTime, pendingPriority);
        input.text = "";
        dueDateInput.text = "";
        dueDateInput.isError = false;
        pendingPriority = "none";
        pendingDueTime = "";
    }

    ColumnLayout {
        id: layout

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: Tokens.padding.large
        anchors.rightMargin: Tokens.padding.large
        spacing: Tokens.spacing.medium

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            StyledTextField {
                id: input

                Layout.fillWidth: true
                placeholderText: Tr.tr("Add a task...")
                onAccepted: root.submit()
            }

            StyledTextField {
                id: dueDateInput

                Layout.preferredWidth: 110
                placeholderText: Tr.tr("yyyy-mm-dd")
                inputMask: "9999-99-99;_"
                validate: text => text === "--" || root.dateRegex.test(text)
                onTextChanged: isError = false
                onAccepted: root.submit()
            }

            IconButton {
                icon: "calendar_month"
                type: IconButton.Text
                isToggle: true
                checked: root.showDatePicker && root.editingDateId === ""
                onClicked: root.openDatePicker("", dueDateInput.text, root.pendingDueTime)
            }

            IconButton {
                icon: "flag"
                type: IconButton.Text
                isToggle: true
                checked: root.pendingPriority !== "none"
                activeOnColour: root.priorityColours[root.pendingPriority]
                inactiveOnColour: Colours.palette.m3onSurfaceVariant
                onClicked: root.pendingPriority = Todos.priorities[(Todos.priorities.indexOf(root.pendingPriority) + 1) % Todos.priorities.length]
            }

            IconButton {
                icon: "add"
                type: IconButton.Filled
                onClicked: root.submit()
            }
        }

        StyledRect {
            Layout.fillWidth: true
            visible: root.showDatePicker
            implicitHeight: pickerLayout.implicitHeight + Tokens.padding.medium * 2
            radius: Tokens.rounding.large
            color: Colours.tPalette.m3surfaceContainer

            ColumnLayout {
                id: pickerLayout

                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                spacing: Tokens.spacing.extraSmall

                StyledText {
                    Layout.fillWidth: true
                    visible: root.editingDateId !== ""
                    elide: Text.ElideRight
                    text: Tr.tr("Due date for: %1").arg(Todos.items.find(i => i.id === root.editingDateId)?.text ?? "")
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.small
                }

                RowLayout {
                    Layout.fillWidth: true

                    IconButton {
                        icon: "chevron_left"
                        type: IconButton.Text
                        onClicked: root.pickerDate = new Date(root.pickerDate.getFullYear(), root.pickerDate.getMonth() - 1, 1)
                    }

                    StyledText {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: grid.title
                    }

                    IconButton {
                        icon: "chevron_right"
                        type: IconButton.Text
                        onClicked: root.pickerDate = new Date(root.pickerDate.getFullYear(), root.pickerDate.getMonth() + 1, 1)
                    }

                    IconButton {
                        icon: "close"
                        type: IconButton.Text
                        onClicked: root.clearDate()
                    }
                }

                DayOfWeekRow {
                    Layout.fillWidth: true
                    locale: grid.locale

                    delegate: StyledText {
                        required property var model

                        horizontalAlignment: Text.AlignHCenter
                        text: model.shortName
                        color: Colours.palette.m3onSurfaceVariant
                    }
                }

                MonthGrid {
                    id: grid

                    Layout.fillWidth: true
                    month: root.pickerDate.getMonth()
                    year: root.pickerDate.getFullYear()
                    locale: Qt.locale()
                    spacing: 2

                    delegate: StyledRect {
                        id: dayCell

                        required property var model

                        readonly property string currentValue: root.editingDateId === "" ? dueDateInput.text : (Todos.items.find(i => i.id === root.editingDateId)?.dueDate ?? "")
                        readonly property bool selected: root.dateRegex.test(currentValue) && root.isoDate(model.date) === currentValue

                        implicitWidth: implicitHeight
                        implicitHeight: dayText.implicitHeight + Tokens.padding.small
                        radius: Tokens.rounding.full
                        color: selected ? Colours.palette.m3primary : "transparent"

                        StyledText {
                            id: dayText

                            anchors.centerIn: parent
                            text: dayCell.model.day
                            opacity: dayCell.model.month === grid.month ? 1 : 0.4
                            color: dayCell.selected ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                        }

                        StateLayer {
                            onClicked: root.pickDate(root.isoDate(dayCell.model.date))
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: Tokens.spacing.extraSmall
                    spacing: Tokens.spacing.small

                    StyledText {
                        text: Tr.tr("Time (optional):")
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.small
                    }

                    StyledTextField {
                        id: timeInput

                        Layout.preferredWidth: 80
                        placeholderText: Tr.tr("HH:mm")
                        inputMask: "99:99;_"
                        validate: t => t === ":" || root.timeRegex.test(t)
                        onTextChanged: isError = false
                    }

                    Item {
                        Layout.fillWidth: true
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.extraSmall

            StyledText {
                text: Pomodoro.label
                color: Pomodoro.running ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.small
            }

            IconButton {
                icon: Pomodoro.running ? "pause" : (Pomodoro.focus ? "timer" : "coffee")
                type: IconButton.Text
                onClicked: Pomodoro.toggle()
            }

            IconButton {
                icon: "restart_alt"
                type: IconButton.Text
                onClicked: Pomodoro.reset()
            }

            StyledText {
                Layout.fillWidth: true
                Layout.leftMargin: Tokens.spacing.small
                elide: Text.ElideRight
                text: Pomodoro.taskText
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.small
            }

            StyledText {
                visible: list.count > 0
                text: Tr.tr("Sort: %1").arg(root.sortModeLabels[root.sortMode])
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.small
            }

            IconButton {
                visible: list.count > 0
                icon: "sort"
                type: IconButton.Text
                onClicked: root.cycleSortMode()
            }
        }

        StyledText {
            Layout.topMargin: Tokens.spacing.large
            Layout.alignment: Qt.AlignHCenter
            visible: list.count === 0
            text: Tr.tr("No tasks yet")
            color: Colours.palette.m3onSurfaceVariant
        }

        VerticalFadeListView {
            id: list

            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(contentHeight, 360)
            visible: count > 0
            spacing: Tokens.spacing.small
            model: ScriptModel {
                values: root.sortedItems
            }

            delegate: TodoRow {}
        }
    }

    component TodoRow: StyledRect {
        id: row

        required property var modelData
        required property int index

        readonly property bool overdue: {
            if (modelData.done || !modelData.dueDate)
                return false;
            const ts = Todos.dueTimestamp(modelData);
            return ts !== null && ts < Date.now();
        }
        readonly property bool editingText: root.editingTextId === modelData.id

        width: ListView.view.width
        implicitHeight: rowLayout.implicitHeight + Tokens.padding.medium * 2

        radius: Tokens.rounding.large
        color: Colours.tPalette.m3surfaceContainer

        RowLayout {
            id: rowLayout

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Tokens.padding.medium
            anchors.rightMargin: Tokens.padding.medium
            spacing: Tokens.spacing.medium

            IconButton {
                icon: row.modelData.done ? "check_circle" : "radio_button_unchecked"
                type: IconButton.Text
                isToggle: true
                checked: row.modelData.done
                onClicked: Todos.toggle(row.modelData.id)
            }

            IconButton {
                icon: "flag"
                type: IconButton.Text
                isToggle: true
                checked: (row.modelData.priority ?? "none") !== "none"
                activeOnColour: root.priorityColours[row.modelData.priority ?? "none"]
                inactiveOnColour: Colours.palette.m3onSurfaceVariant
                onClicked: Todos.cyclePriority(row.modelData.id)
            }

            Item {
                Layout.fillWidth: true
                implicitHeight: Math.max(taskText.implicitHeight, taskEdit.implicitHeight)

                StyledText {
                    id: taskText

                    visible: !row.editingText
                    width: parent.width
                    text: row.modelData.text
                    wrapMode: Text.Wrap
                    font.strikeout: row.modelData.done
                    color: row.modelData.done ? Colours.palette.m3onSurfaceVariant : Colours.palette.m3onSurface

                    TapHandler {
                        onTapped: root.editingTextId = row.modelData.id
                    }
                }

                StyledTextField {
                    id: taskEdit

                    visible: row.editingText
                    width: parent.width
                    text: row.modelData.text

                    onVisibleChanged: if (visible)
                        forceActiveFocus()
                    onAccepted: {
                        Todos.editText(row.modelData.id, text);
                        root.editingTextId = "";
                    }
                    onActiveFocusChanged: if (!activeFocus && visible) {
                        Todos.editText(row.modelData.id, text);
                        root.editingTextId = "";
                    }
                }
            }

            IconButton {
                icon: "calendar_month"
                type: IconButton.Text
                isToggle: true
                checked: !!row.modelData.dueDate
                onClicked: root.openDatePicker(row.modelData.id, row.modelData.dueDate ?? "", row.modelData.dueTime ?? "")
            }

            StyledText {
                visible: (row.modelData.pomodoros ?? 0) > 0
                text: `${row.modelData.pomodoros}x`
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.small
            }

            IconButton {
                icon: "target"
                type: IconButton.Text
                isToggle: true
                checked: Pomodoro.taskId === row.modelData.id
                onClicked: Pomodoro.toggleTask(row.modelData.id)
            }

            StyledText {
                visible: !!row.modelData.dueDate
                text: row.modelData.dueDate + (row.modelData.dueTime ? ` ${row.modelData.dueTime}` : "")
                color: row.overdue ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
            }

            IconButton {
                icon: "arrow_upward"
                type: IconButton.Text
                visible: root.sortMode === "added"
                disabled: row.index === 0
                onClicked: Todos.move(row.modelData.id, -1)
            }

            IconButton {
                icon: "arrow_downward"
                type: IconButton.Text
                visible: root.sortMode === "added"
                disabled: row.index === Todos.items.length - 1
                onClicked: Todos.move(row.modelData.id, 1)
            }

            IconButton {
                icon: "delete"
                type: IconButton.Text
                onClicked: Todos.remove(row.modelData.id)
            }
        }
    }
}
