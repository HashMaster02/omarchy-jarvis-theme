import QtQuick
import qs.Commons

// JARVIS reactor: an animated arc-reactor glyph with the J.A.R.V.I.S
// wordmark. Stands in for the Omarchy menu button: left click opens the
// Omarchy menu, right click opens a terminal.
//
// Settings (shell.json entry):
//   label        "J.A.R.V.I.S"   wordmark text ("" for the glyph alone)
//   accent       "#00d8ff"
//   gold         "#ffc857"
//   onClick      command for left click
//   onRightClick command for right click
//   tooltip      hover text
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
  readonly property string label: String(setting("label", "J.A.R.V.I.S"))
  readonly property string onClick: String(setting("onClick", "omarchy-shell shell toggle omarchy.menu '{\"menu\":\"root\"}'"))
  readonly property string onRightClick: String(setting("onRightClick", "xdg-terminal-exec"))
  readonly property string tooltipText: String(setting("tooltip", "Just A Rather Very Intelligent System"))
  readonly property bool vertical: bar ? bar.vertical : false
  readonly property int barSize: bar ? bar.barSize : 26
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property bool tooltipHovered: hover.containsMouse
  readonly property int glyphSize: Style.space(18)

  function triggerPress(button) {
    if (bar) bar.hideTooltip(root)
    var command = button === Qt.RightButton ? onRightClick : onClick
    if (command && bar) bar.run(command)
  }

  implicitWidth: vertical ? barSize : content.implicitWidth + Style.space(9) * 2
  implicitHeight: vertical ? content.implicitHeight + Style.space(6) * 2 : barSize

  onAccentChanged: core.requestPaint()
  onGoldChanged: core.requestPaint()

  Row {
    id: content
    anchors.centerIn: parent
    spacing: Style.space(6)

    Item {
      id: reactor
      width: root.glyphSize
      height: root.glyphSize
      anchors.verticalCenter: parent.verticalCenter

      // Breathing halo behind the reactor.
      Rectangle {
        id: halo
        anchors.centerIn: parent
        width: parent.width
        height: parent.height
        radius: width / 2
        color: root.accent
        opacity: 0.16

        SequentialAnimation on opacity {
          loops: Animation.Infinite
          NumberAnimation { to: 0.42; duration: 1500; easing.type: Easing.InOutSine }
          NumberAnimation { to: 0.12; duration: 1500; easing.type: Easing.InOutSine }
        }
      }

      Canvas {
        id: core
        anchors.fill: parent
        antialiasing: true

        RotationAnimation on rotation {
          from: 0
          to: 360
          duration: 30000
          loops: Animation.Infinite
        }

        onPaint: {
          var ctx = getContext("2d")
          ctx.reset()
          var c = width / 2
          var r = c - 1

          // Outer ring.
          ctx.lineWidth = 1.2
          ctx.strokeStyle = root.accent
          ctx.beginPath()
          ctx.arc(c, c, r, 0, Math.PI * 2)
          ctx.stroke()

          // Segmented coil ring.
          ctx.lineWidth = 2.4
          var segments = 8
          for (var i = 0; i < segments; i++) {
            var start = (i / segments) * Math.PI * 2 + 0.16
            var end = ((i + 1) / segments) * Math.PI * 2 - 0.16
            ctx.beginPath()
            ctx.arc(c, c, r - 3.2, start, end)
            ctx.stroke()
          }

          // Gold core.
          ctx.lineWidth = 1
          ctx.strokeStyle = root.gold
          ctx.beginPath()
          ctx.arc(c, c, r - 6, 0, Math.PI * 2)
          ctx.stroke()
          ctx.fillStyle = "#ffffff"
          ctx.beginPath()
          ctx.arc(c, c, 1.6, 0, Math.PI * 2)
          ctx.fill()
        }
      }
    }

    Text {
      visible: !root.vertical && root.label !== ""
      anchors.verticalCenter: parent.verticalCenter
      text: root.label
      textFormat: Text.PlainText
      color: root.accent
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      font.bold: true
      font.letterSpacing: 1.5
      renderType: Text.NativeRendering
    }
  }

  MouseArea {
    id: hover
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.RightButton | Qt.MiddleButton
    cursorShape: Qt.PointingHandCursor
    onEntered: if (root.bar) root.bar.showTooltip(root, root.tooltipText)
    onExited: if (root.bar) root.bar.hideTooltip(root)
    onClicked: function(mouse) { root.triggerPress(mouse.button) }
  }
}
