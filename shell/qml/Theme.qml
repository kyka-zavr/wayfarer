pragma Singleton
import QtQuick

// Single source of visual truth. Everything else references `Theme.*`.
// Will move to a JSON file + live reload once settings exist.
QtObject {
    readonly property color bg:        "#0d1117"
    readonly property color bgRaised:  "#161b22"
    readonly property color border:    "#30363d"
    readonly property color text:      "#e6edf3"
    readonly property color textDim:   "#7d8590"
    readonly property color accent:    "#58a6ff"
    readonly property color accentAlt: "#3fb950"

    readonly property int radius: 6
    readonly property int barHeight: 34

    readonly property string monoFont: "Cascadia Mono"
}
