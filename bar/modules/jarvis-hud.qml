import QtQuick
import Quickshell

// JARVIS HUD frame.
//
// A zero-width bar module that mounts a decorative overlay onto the bar
// window it lives in: a cyan-to-gold edge line with a soft glow, ruler
// ticks, and a slow light sweep. Put it anywhere in the layout; it takes
// no space. Horizontal bars only (top / bottom).
//
// Settings (shell.json entry):
//   accent  "#00d8ff"   line and tick colour
//   gold    "#ffc857"   centre of the edge line
//   ticks   true        ruler ticks along the edge
//   sweep   true        light sweep along the edge line
Item {
  id: root

  property var bar: null
  property string moduleName: ""
  property var settings: ({})

  function setting(name, fallback) {
    var value = settings ? settings[name] : undefined
    return value === undefined || value === null ? fallback : value
  }

  readonly property color accent: setting("accent", "#00d8ff")
  readonly property color gold: setting("gold", "#ffc857")
  readonly property bool ticks: setting("ticks", true) !== false
  readonly property bool sweep: setting("sweep", true) !== false
  readonly property bool horizontal: bar ? !bar.vertical : true
  readonly property string position: bar ? bar.position : "top"

  implicitWidth: 0
  implicitHeight: bar ? bar.barSize : 26

  property var overlay: null

  function mount() {
    if (overlay) return
    var window = root.QsWindow.window
    var host = window ? window.contentItem : null
    if (!host) return
    overlay = frame.createObject(host, { hud: root })
  }

  Component.onCompleted: mount()
  Component.onDestruction: {
    if (overlay) overlay.destroy()
    overlay = null
  }

  // The window may not be attached yet when the module is created.
  Timer {
    interval: 300
    repeat: true
    running: root.overlay === null
    onTriggered: root.mount()
  }

  Component {
    id: frame

    Item {
      id: f

      property var hud: null

      anchors.fill: parent
      z: -1
      visible: hud !== null && hud.horizontal

      readonly property bool atTop: hud ? hud.position !== "bottom" : true
      readonly property color accent: hud ? hud.accent : "#00d8ff"
      readonly property color gold: hud ? hud.gold : "#ffc857"
      readonly property color glow: Qt.rgba(accent.r, accent.g, accent.b, 0.30)

      // Soft glow fading toward the desktop edge.
      Rectangle {
        x: 0
        width: parent.width
        height: 7
        y: f.atTop ? parent.height - height : 0
        gradient: Gradient {
          orientation: Gradient.Vertical
          GradientStop { position: 0.0; color: f.atTop ? "transparent" : f.glow }
          GradientStop { position: 1.0; color: f.atTop ? f.glow : "transparent" }
        }
      }

      // Edge line: cyan at the ends, gold at the centre.
      Rectangle {
        x: 0
        width: parent.width
        height: 1
        y: f.atTop ? parent.height - 1 : 0
        gradient: Gradient {
          orientation: Gradient.Horizontal
          GradientStop { position: 0.00; color: "transparent" }
          GradientStop { position: 0.06; color: f.accent }
          GradientStop { position: 0.50; color: f.gold }
          GradientStop { position: 0.94; color: f.accent }
          GradientStop { position: 1.00; color: "transparent" }
        }
      }

      // Ruler ticks.
      Repeater {
        model: f.hud && f.hud.ticks ? Math.max(0, Math.floor(f.width / 40)) : 0

        Rectangle {
          required property int index
          readonly property bool major: index % 5 === 0

          x: index * 40
          width: 1
          height: major ? 6 : 3
          y: f.atTop ? f.height - 1 - height : 1
          color: f.accent
          opacity: major ? 0.38 : 0.18
        }
      }

      // Light sweep along the edge.
      Rectangle {
        id: sweepLight

        visible: f.hud && f.hud.sweep
        width: 180
        height: 2
        y: f.atTop ? f.height - 2 : 0
        gradient: Gradient {
          orientation: Gradient.Horizontal
          GradientStop { position: 0.0; color: "transparent" }
          GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.55) }
          GradientStop { position: 1.0; color: "transparent" }
        }

        SequentialAnimation on x {
          running: sweepLight.visible
          loops: Animation.Infinite
          NumberAnimation { from: -180; to: f.width; duration: 6500; easing.type: Easing.InOutSine }
          PauseAnimation { duration: 9000 }
        }
      }
    }
  }
}
