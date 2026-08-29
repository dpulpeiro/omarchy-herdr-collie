import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "io.github.dpulpeiro.collie"

  property string status: "checking"
  property string detail: "Checking Collie…"
  readonly property string controlScript: decodeURIComponent(
    Qt.resolvedUrl("scripts/collie-control").toString().replace(/^file:\/\//, ""))
  readonly property bool active: status === "running"
  readonly property color statusColor: active ? Color.accent
    : status === "partial" ? bar.urgent
    : Qt.darker(bar.foreground, 1.55)
  readonly property bool opened: panelLoader.item
    ? panelLoader.item.opened === true
    : false
  readonly property bool popoutSwitchClosing: panelLoader.item
    ? panelLoader.item.popoutSwitchClosing === true
    : false

  function open() {
    if (panelLoader.item) panelLoader.item.open()
  }

  function close() {
    if (panelLoader.item) panelLoader.item.close()
  }

  function toggle() {
    if (panelLoader.item) panelLoader.item.toggle()
  }

  function closeForPopoutSwitch() {
    if (panelLoader.item) panelLoader.item.closeForPopoutSwitch()
  }

  function injectPanel() {
    if (!panelLoader.item) return
    panelLoader.item.bar = root.bar
    panelLoader.item.anchorItem = button
    panelLoader.item.hostWidget = root
  }

  function refresh() {
    if (!statusProcess.running) statusProcess.running = true
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight
  onBarChanged: injectPanel()

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  Timer {
    interval: 30000
    repeat: true
    triggeredOnStart: true
    running: true
    onTriggered: root.refresh()
  }

  Process {
    id: statusProcess
    command: ["bash", root.controlScript, "status"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var parts = String(text).trim().split("\t")
        root.status = parts[0] || "error"
        root.detail = parts[1] || "Collie status unavailable"
      }
    }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰩃"
    foreground: root.statusColor
    tooltipText: "Collie: " + root.detail
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.LeftButton) root.toggle()
    }
  }
}
