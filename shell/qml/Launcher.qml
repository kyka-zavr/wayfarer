import QtQuick
import "." as Local

Rectangle {
    id: root
    radius: 14
    color: Local.Theme.bgRaised
    border.width: 1
    border.color: Local.Theme.border

    // Match the blur/acrylic look once DWM interop lands (M5).
    opacity: 0.98

    Column {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 12

        // --- query line ---------------------------------------------------
        Item {
            width: parent.width
            height: 30

            TextInput {
                id: query
                anchors.fill: parent
                color: Local.Theme.text
                font.pixelSize: 20
                font.family: Local.Theme.monoFont
                selectionColor: Local.Theme.accent
                focus: true

                // Matches Rofi: `> ` for commands, `/` for the Run dialog.
                onTextChanged: {
                    if (text.startsWith("/"))
                        hint.text = "run: " + text.substring(1)
                    else
                        hint.text = ""
                }
            }

            Text {
                anchors.fill: parent
                visible: query.text.length === 0
                color: Local.Theme.textDim
                font: query.font
                verticalAlignment: Text.AlignVCenter
                text: "Search apps and files — or type / for commands"
            }

            Text {
                id: hint
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                color: Local.Theme.accent
                font.pixelSize: 12
                font.family: Local.Theme.monoFont
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Local.Theme.border
        }

        // --- results ------------------------------------------------------
        ListView {
            id: results
            width: parent.width
            height: parent.height - 45
            clip: true
            spacing: 2
            currentIndex: 0

            model: ListModel {
                ListElement { title: "Settings";   subtitle: "wayfarer://settings" }
                ListElement { title: "Terminal";   subtitle: "wt.exe" }
                ListElement { title: "Explorer";   subtitle: "explorer.exe" }
                ListElement { title: "Task Manager"; subtitle: "taskmgr.exe" }
            }

            delegate: Rectangle {
                required property int index
                required property string title
                required property string subtitle

                width: results.width
                height: 40
                radius: 6
                color: ListView.isCurrentItem ? Local.Theme.border : "transparent"

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    spacing: 10

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: title
                        color: Local.Theme.text
                        font.pixelSize: 14
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: subtitle
                        color: Local.Theme.textDim
                        font.pixelSize: 11
                        font.family: Local.Theme.monoFont
                    }
                }
            }
        }
    }
}
