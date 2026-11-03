pragma Singleton
import QtQuick
import Quickshell

// All panel colors/fonts in one place
Singleton {
    readonly property color bg:     "#0e0e0e"
    readonly property color bgAlt:  "#1a1a1a"
    readonly property color hover:  "#202020"
    readonly property color border: "#2a2a2a"
    readonly property color fg:     "#e6e6e6"
    readonly property color dim:    "#7a7a7a"
    readonly property color red:    "#e06c6c"
    readonly property string font:  "JetBrainsMono Nerd Font"
    function icon(cp) { return String.fromCodePoint(cp) }
}
