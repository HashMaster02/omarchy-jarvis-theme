import QtQuick
import qs.Commons

// JARVIS bracket: a chamfered HUD bracket to frame a group of widgets.
// Use two entries with `side: "open"` and `side: "close"` around a group.
//
// Settings (shell.json entry):
//   side     "open" | "close"
//   accent   "#00d8ff"
//   opacity  0.8
//   gap      0                  extra space on the outer side, to separate groups
Item {
  id: root

  property var bar: null
  property string moduleName: ""
  property var settings: ({})

  function setting(name, fallback) {
    var value = settings ? settings[name] : undefined
    return value === undefined || value === null ? fallback : value
  }

  readonly property bool close: String(setting("side", "open")) === "close"
  readonly property color accent: setting("accent", "#00d8ff")
  readonly property real strength: Number(setting("opacity", 0.8))
  readonly property int gap: Math.max(0, Number(setting("gap", 0)))
  readonly property bool vertical: bar ? bar.vertical : false
  readonly property int barSize: bar ? bar.barSize : 26
  readonly property int arm: Style.space(6)
  readonly property int pad: Style.space(2)
  readonly property int inset: Style.space(7)

  implicitWidth: vertical ? barSize : arm + pad * 2 + gap
  implicitHeight: vertical ? arm + pad * 2 + gap : barSize

  onAccentChanged: shape.requestPaint()
  onCloseChanged: shape.requestPaint()
  onVerticalChanged: shape.requestPaint()
  onWidthChanged: shape.requestPaint()
  onHeightChanged: shape.requestPaint()

  Canvas {
    id: shape
    anchors.fill: parent
    opacity: root.strength

    onPaint: {
      var ctx = getContext("2d")
      ctx.reset()
      ctx.lineWidth = 1.5
      ctx.lineJoin = "miter"
      ctx.strokeStyle = root.accent
      var chamfer = 3
      ctx.beginPath()
      if (!root.vertical) {
        var x0 = root.pad + (root.close ? 0 : root.gap) + 0.5, x1 = x0 + root.arm
        var y0 = root.inset + 0.5, y1 = height - root.inset - 0.5
        if (!root.close) {
          ctx.moveTo(x1, y0); ctx.lineTo(x0 + chamfer, y0); ctx.lineTo(x0, y0 + chamfer)
          ctx.lineTo(x0, y1 - chamfer); ctx.lineTo(x0 + chamfer, y1); ctx.lineTo(x1, y1)
        } else {
          ctx.moveTo(x0, y0); ctx.lineTo(x1 - chamfer, y0); ctx.lineTo(x1, y0 + chamfer)
          ctx.lineTo(x1, y1 - chamfer); ctx.lineTo(x1 - chamfer, y1); ctx.lineTo(x0, y1)
        }
      } else {
        var vx0 = root.inset + 0.5, vx1 = width - root.inset - 0.5
        var vy0 = root.pad + (root.close ? 0 : root.gap) + 0.5, vy1 = vy0 + root.arm
        if (!root.close) {
          ctx.moveTo(vx0, vy1); ctx.lineTo(vx0, vy0 + chamfer); ctx.lineTo(vx0 + chamfer, vy0)
          ctx.lineTo(vx1 - chamfer, vy0); ctx.lineTo(vx1, vy0 + chamfer); ctx.lineTo(vx1, vy1)
        } else {
          ctx.moveTo(vx0, vy0); ctx.lineTo(vx0, vy1 - chamfer); ctx.lineTo(vx0 + chamfer, vy1)
          ctx.lineTo(vx1 - chamfer, vy1); ctx.lineTo(vx1, vy1 - chamfer); ctx.lineTo(vx1, vy0)
        }
      }
      ctx.stroke()
    }
  }
}
