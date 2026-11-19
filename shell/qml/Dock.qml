import QtQuick
import "." as Local

Rectangle {
    id: root
    radius: 14
    color: Local.Theme.bg
    border.width: 1
    border.color: Local.Theme.border

    // Placeholder pins. Replaced by a Rust-provided model (app id, icon, hwnd).
    Row {
        anchors.centerIn: parent
        spacing: 10

        Repeater {
            model: ["T", "B", "S", "M", "C", "G"]

            Item {
                width: 44
                height: 44

                Rectangle {
                    id: tile
                    anchors.fill: parent
                    radius: 11
                    color: hover.hovered ? Local.Theme.border : Local.Theme.bgRaised
                    border.width: hover.hovered ? 1 : 0
                    border.color: Local.Theme.accent

                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        color: Local.Theme.text
                        font.pixelSize: 16
                        font.bold: true
                    }

                    HoverHandler { id: hover }

                    // Scale on hover, not on click: this is a shell, not a website.
                    scale: hover.hovered ? 1.08 : 1.0

                    Behavior on scale {
                        NumberAnimation { duration: 90; easing.type: Easing.OutQuad }
                    }

                    TapHandler {
                        // TODO(M2): launch by app id via wf-core.
                        onTapped: console.log("dock: launch", modelData)
                    }
                }
            }
        }
    }
}
