import QtQuick
import Quickshell.Io
import qs.Commons

// JARVIS telemetry: CPU, memory, CPU temperature and GPU load as HUD
// readouts with segmented meters. Reads /proc and sysfs only, so it never
// wakes a sleeping discrete GPU. Left click opens btop; right click
// refreshes.
//
// Settings (shell.json entry):
//   items     ["cpu", "mem", "gpu"]   readouts, in order ("temp" also available)
//   interval  2                                seconds between samples
//   meters    true                             show the segmented meters
//   accent    "#00d8ff"
//   gold      "#ffc857"                        meter colour from 70%
//   warn      "#ff4b5c"                        meter colour from 90%
//   onClick   "omarchy-launch-or-focus-tui btop"
Item {
  id: root

  property var bar: null
  property string moduleName: ""
  property var settings: ({})

  function setting(name, fallback) {
    var value = settings ? settings[name] : undefined
    return value === undefined || value === null ? fallback : value
  }

  readonly property var items: {
    var value = setting("items", null)
    return Array.isArray(value) && value.length > 0 ? value : ["cpu", "mem", "gpu"]
  }
  readonly property int interval: Math.max(1, Number(setting("interval", 2)))
  readonly property bool meters: setting("meters", true) !== false
  readonly property color accent: setting("accent", "#00d8ff")
  readonly property color gold: setting("gold", "#ffc857")
  readonly property color warn: setting("warn", "#ff4b5c")
  readonly property string onClick: String(setting("onClick", "omarchy-launch-or-focus-tui btop"))
  readonly property bool vertical: bar ? bar.vertical : false
  readonly property int barSize: bar ? bar.barSize : 26
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property color fg: bar ? bar.barForeground : Color.foreground
  readonly property bool tooltipHovered: hover.containsMouse

  // Samples. -1 means "not available yet".
  property real cpu: -1
  property real mem: -1
  property real temp: -1
  property real gpu: -1
  property real memUsedGb: 0
  property real memTotalGb: 0
  property var lastCpu: null

  readonly property string tooltipText: {
    var parts = []
    if (cpu >= 0) parts.push("CPU " + Math.round(cpu) + "%")
    if (mem >= 0) parts.push("MEM " + memUsedGb.toFixed(1) + " / " + memTotalGb.toFixed(0) + " GB")
    if (temp >= 0) parts.push("CPU " + Math.round(temp) + "°C")
    if (gpu >= 0) parts.push("GPU " + Math.round(gpu) + "%")
    return parts.length ? parts.join("   ") : "Sampling…"
  }

  function parse(raw) {
    var p = String(raw || "").trim().split(/\s+/)
    if (p.length < 6) return
    var busy = Number(p[0]), total = Number(p[1])
    if (lastCpu && total > lastCpu[1])
      cpu = Math.max(0, Math.min(100, 100 * (busy - lastCpu[0]) / (total - lastCpu[1])))
    lastCpu = [busy, total]
    memTotalGb = Number(p[2]) / 1048576
    memUsedGb = Number(p[3]) / 1048576
    mem = memTotalGb > 0 ? 100 * memUsedGb / memTotalGb : -1
    temp = p[4] === "na" ? -1 : Number(p[4]) / 1000
    gpu = p[5] === "na" ? -1 : Number(p[5])
  }

  function value(kind) {
    switch (kind) {
      case "cpu": return cpu
      case "mem": return mem
      case "temp": return temp
      case "gpu": return gpu
    }
    return -1
  }

  // Meter fill, 0..100. Temperature maps 30..100 °C onto the meter.
  function level(kind) {
    var v = value(kind)
    if (v < 0) return 0
    if (kind === "temp") return Math.max(0, Math.min(100, (v - 30) / 70 * 100))
    return Math.max(0, Math.min(100, v))
  }

  function label(kind) {
    switch (kind) {
      case "cpu": return "CPU"
      case "mem": return "MEM"
      case "temp": return "TMP"
      case "gpu": return "GPU"
    }
    return String(kind).toUpperCase()
  }

  function text(kind) {
    var v = value(kind)
    if (v < 0) return "--"
    if (kind === "temp") return Math.round(v) + "°"
    return Math.round(v) + "%"
  }

  function tone(kind) {
    var l = level(kind)
    if (l >= 90) return warn
    if (l >= 70) return gold
    return accent
  }

  function refresh() {
    if (!probe.running) probe.running = true
  }

  function triggerPress(button) {
    if (bar) bar.hideTooltip(root)
    if (button === Qt.RightButton) {
      refresh()
      return
    }
    if (onClick && bar) bar.run(onClick)
  }

  Process {
    id: probe
    command: ["bash", "-c",
      "read -r _ u n s i w q sq st _ < /proc/stat; " +
      "busy=$((u+n+s+w+q+sq+st)); total=$((busy+i)); " +
      "mt=0; ma=0; while read -r k v _; do case $k in MemTotal:) mt=$v;; MemAvailable:) ma=$v;; esac; done < /proc/meminfo; " +
      "t=na; for d in /sys/class/hwmon/hwmon*; do n=$(cat \"$d/name\" 2>/dev/null); " +
      "case $n in k10temp|coretemp|zenpower|cpu_thermal) [[ -r $d/temp1_input ]] && { t=$(cat \"$d/temp1_input\"); break; };; esac; done; " +
      "[[ $t == na ]] && for z in /sys/class/thermal/thermal_zone*; do [[ -r $z/temp ]] && { t=$(cat \"$z/temp\"); break; }; done; " +
      "g=na; for f in /sys/class/drm/card*/device/gpu_busy_percent; do [[ -r $f ]] && { g=$(cat \"$f\"); break; }; done; " +
      "echo \"$busy $total $mt $((mt-ma)) $t $g\""]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.parse(text)
    }
  }

  Timer {
    interval: root.interval * 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  TextMetrics { id: pctMetrics; font.family: root.fontFamily; font.pixelSize: Style.font.bodySmall; text: "100%" }
  TextMetrics { id: tmpMetrics; font.family: root.fontFamily; font.pixelSize: Style.font.bodySmall; text: "100°" }

  implicitWidth: vertical ? barSize : readouts.implicitWidth + Style.space(6) * 2
  implicitHeight: vertical ? column.implicitHeight + Style.space(6) * 2 : barSize

  // Horizontal bars: label · meter · value for every readout.
  Row {
    id: readouts
    visible: !root.vertical
    anchors.centerIn: parent
    spacing: Style.space(7)

    Repeater {
      model: root.vertical ? [] : root.items

      Row {
        id: readout

        required property var modelData
        required property int index
        readonly property string kind: String(modelData)
        readonly property int filled: Math.round(root.level(kind) / 100 * 6)

        spacing: Style.space(4)
        anchors.verticalCenter: parent.verticalCenter

        Rectangle {
          visible: readout.index > 0
          width: 1
          height: root.barSize - Style.space(14)
          anchors.verticalCenter: parent.verticalCenter
          color: root.accent
          opacity: 0.35
          rotation: 18
        }

        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: root.label(readout.kind)
          textFormat: Text.PlainText
          color: root.accent
          opacity: 0.72
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          font.letterSpacing: 1
          renderType: Text.NativeRendering
        }

        Row {
          visible: root.meters
          spacing: 1
          anchors.verticalCenter: parent.verticalCenter

          Repeater {
            model: 6

            Rectangle {
              required property int index
              width: 4
              height: Style.space(6)
              color: root.tone(readout.kind)
              opacity: index < readout.filled ? 0.95 : 0.18
              Behavior on opacity { NumberAnimation { duration: 260 } }
            }
          }
        }

        Text {
          anchors.verticalCenter: parent.verticalCenter
          width: Math.ceil(readout.kind === "temp" ? tmpMetrics.advanceWidth : pctMetrics.advanceWidth)
          horizontalAlignment: Text.AlignLeft
          text: root.text(readout.kind)
          textFormat: Text.PlainText
          color: root.fg
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
          renderType: Text.NativeRendering
        }
      }
    }
  }

  // Vertical bars: just the values, stacked.
  Column {
    id: column
    visible: root.vertical
    anchors.centerIn: parent
    spacing: Style.space(2)

    Repeater {
      model: root.vertical ? root.items : []

      Text {
        required property var modelData
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.text(String(modelData))
        textFormat: Text.PlainText
        color: root.tone(String(modelData))
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        renderType: Text.NativeRendering
      }
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
