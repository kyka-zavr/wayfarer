import QtQuick
import "." as Local

Rectangle {
    id: root
    color: Local.Theme.bg

    // Hairline instead of a drop shadow: overlays must not glow over windows.
    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: Local.Theme.border
    }

    // --- workspaces -------------------------------------------------------
    Row {
        id: workspaces
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 5

        Repeater {
            model: 5
            Rectangle {
                width: 18
                height: 18
                radius: 5
                color: index === 0 ? Local.Theme.accent : Local.Theme.bgRaised

                Text {
                    anchors.centerIn: parent
                    text: index + 1
                    font.pixelSize: 10
                    font.bold: true
                    color: index === 0 ? Local.Theme.bg : Local.Theme.textDim
                }
            }
        }
    }

    // --- focused window title ---------------------------------------------
    Text {
        id: title
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        color: Local.Theme.text
        font.pixelSize: 12
        elide: Text.ElideRight
        width: Math.min(implicitWidth, parent.width * 0.4)
        horizontalAlignment: Text.AlignHCenter
        text: "Wayfarer"
    }

    // --- clock ------------------------------------------------------------
    Text {
        id: clock
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        color: Local.Theme.text
        font.pixelSize: 12
        font.family: Local.Theme.monoFont
        text: Qt.formatDateTime(new Date(), "ddd HH:mm")

        Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: clock.text = Qt.formatDateTime(new Date(), "ddd HH:mm")
        }
    }
}
