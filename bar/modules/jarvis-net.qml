import QtQuick
import Quickshell.Io
import qs.Commons

// JARVIS uplink: Wi-Fi network name, signal meter and ping at a glance.
// Falls back to "LAN" on a wired link and "OFFLINE" with no link. Left
// click opens Omarchy's network panel; right click refreshes.
//
// Settings (shell.json entry):
//   interval  5           seconds between samples (each one pings once)
//   host      "1.1.1.1"   ping target
//   maxChars  14          network name is shortened past this
//   showName  true        show the network name
//   meters    true        show the signal meter
//   accent    "#00d8ff"
//   gold      "#ffc857"   ping colour from 80 ms / signal below 50%
//   warn      "#ff4b5c"   ping colour from 200 ms / signal below 25% / offline
//   onClick   "omarchy-shell shell toggle omarchy.network '{}'"
Item {
  id: root

  property var bar: null
  property string moduleName: ""
  property var settings: ({})

  function setting(name, fallback) {
    var value = settings ? settings[name] : undefined
    return value === undefined || value === null ? fallback : value
  }

  readonly property int interval: Math.max(2, Number(setting("interval", 5)))
  readonly property string host: String(setting("host", "1.1.1.1"))
  readonly property int maxChars: Math.max(4, Number(setting("maxChars", 14)))
  readonly property bool showName: setting("showName", true) !== false
  readonly property bool meters: setting("meters", true) !== false
  readonly property color accent: setting("accent", "#00d8ff")
  readonly property color gold: setting("gold", "#ffc857")
  readonly property color warn: setting("warn", "#ff4b5c")
  readonly property string onClick: String(setting("onClick", "omarchy-shell shell toggle omarchy.network '{}'"))
  readonly property bool vertical: bar ? bar.vertical : false
  readonly property int barSize: bar ? bar.barSize : 26
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property color fg: bar ? bar.barForeground : Color.foreground
  readonly property bool tooltipHovered: hover.containsMouse

  // Samples.
  property string state: ""        // "", "wifi", "lan", "off"
  property string device: ""
  property string ssid: ""
  property int signal: 0           // 0..100
  property int dbm: 0
  property real ping: -1           // ms, -1 when unreachable

  readonly property bool online: state === "wifi" || state === "lan"
  readonly property string label: state === "wifi" ? "WIFI" : (state === "lan" ? "LAN" : "NET")
  readonly property string name: {
    if (state === "") return "…"
    if (state === "off") return "OFFLINE"
    if (state === "lan") return "WIRED"
    var s = ssid || "wifi"
    return s.length > maxChars ? s.substring(0, maxChars - 1) + "…" : s
  }
  readonly property string pingText: !online ? "--" : (ping < 0 ? "--" : Math.round(ping) + "ms")
  readonly property color signalTone: signal < 25 ? warn : (signal < 50 ? gold : accent)
  readonly property color pingTone: !online || ping < 0 ? warn : (ping >= 200 ? warn : (ping >= 80 ? gold : accent))
  readonly property int filled: online ? Math.round(signal / 100 * 5) : 0

  readonly property string tooltipText: {
    if (state === "") return "Sampling…"
    if (state === "off") return "No network connection"
    var parts = []
    if (state === "wifi") parts.push(ssid + "  " + dbm + " dBm (" + signal + "%)")
    else parts.push("Wired connection")
    parts.push(ping < 0 ? "ping: no reply from " + host : "ping " + ping.toFixed(1) + " ms to " + host)
    if (device) parts.push(device)
    return parts.join("   ")
  }

  function parse(raw) {
    var p = String(raw || "").replace(/\n$/, "").split("\t")
    if (p.length < 5) return
    state = p[0] || "off"
    device = p[1]
    signal = Math.max(0, Math.min(100, Number(p[2]) || 0))
    dbm = Number(p[3]) || 0
    ping = p[4] === "na" ? -1 : Number(p[4])
    ssid = p.slice(5).join("\t")
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
      "host=" + JSON.stringify(root.host) + "; " +
      "state=off; dev=; ssid=; sig=0; dbm=0; " +
      "dev=$(nmcli -t -f DEVICE,TYPE,STATE dev status 2>/dev/null | awk -F: '$2==\"wifi\" && $3==\"connected\"{print $1; exit}'); " +
      "if [[ -n $dev ]]; then state=wifi; " +
      "  link=$(iw dev \"$dev\" link 2>/dev/null); " +
      "  ssid=$(sed -n 's/^[[:space:]]*SSID: //p' <<<\"$link\" | head -1); " +
      "  dbm=$(sed -n 's/^[[:space:]]*signal: \\(-\\?[0-9]*\\).*/\\1/p' <<<\"$link\" | head -1); " +
      "  if [[ -n $dbm ]]; then sig=$(( (dbm + 100) * 2 )); (( sig < 0 )) && sig=0; (( sig > 100 )) && sig=100; " +
      "  else dbm=0; line=$(nmcli -t -e no --rescan no -f IN-USE,SSID,SIGNAL dev wifi 2>/dev/null | awk -F: '$1==\"*\"{print; exit}'); " +
      "    sig=${line##*:}; rest=${line%:*}; ssid=${rest#*:}; fi; " +
      "elif nmcli -t -f DEVICE,TYPE,STATE dev status 2>/dev/null | grep -q ':ethernet:connected$'; then state=lan; sig=100; " +
      "  dev=$(nmcli -t -f DEVICE,TYPE,STATE dev status | awk -F: '$2==\"ethernet\" && $3==\"connected\"{print $1; exit}'); fi; " +
      "p=na; if [[ $state != off ]]; then out=$(ping -n -c1 -W1 \"$host\" 2>/dev/null); [[ $out =~ time=([0-9.]+) ]] && p=${BASH_REMATCH[1]}; fi; " +
      "printf '%s\\t%s\\t%s\\t%s\\t%s\\t%s\\n' \"$state\" \"$dev\" \"${sig:-0}\" \"${dbm:-0}\" \"$p\" \"$ssid\""]
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

  TextMetrics { id: pingMetrics; font.family: root.fontFamily; font.pixelSize: Style.font.bodySmall; text: "999ms" }

  implicitWidth: vertical ? barSize : readout.implicitWidth + Style.space(6) * 2
  implicitHeight: vertical ? column.implicitHeight + Style.space(6) * 2 : barSize

  Row {
    id: readout
    visible: !root.vertical
    anchors.centerIn: parent
    spacing: Style.space(4)

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: root.label
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
        model: 5

        Rectangle {
          required property int index
          width: 4
          height: Style.space(3) + index * 1
          anchors.bottom: parent.bottom
          color: root.online ? root.signalTone : root.warn
          opacity: index < root.filled ? 0.95 : 0.18
          Behavior on opacity { NumberAnimation { duration: 260 } }
        }
      }
    }

    Text {
      visible: root.showName
      anchors.verticalCenter: parent.verticalCenter
      text: root.name
      textFormat: Text.PlainText
      color: root.online ? root.fg : root.warn
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      renderType: Text.NativeRendering
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      width: Math.ceil(pingMetrics.advanceWidth)
      text: root.pingText
      textFormat: Text.PlainText
      color: root.pingTone
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      renderType: Text.NativeRendering
    }
  }

  Column {
    id: column
    visible: root.vertical
    anchors.centerIn: parent
    spacing: Style.space(2)

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: root.online ? root.signal + "%" : "--"
      textFormat: Text.PlainText
      color: root.online ? root.signalTone : root.warn
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      renderType: Text.NativeRendering
    }
    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: root.pingText
      textFormat: Text.PlainText
      color: root.pingTone
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
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
