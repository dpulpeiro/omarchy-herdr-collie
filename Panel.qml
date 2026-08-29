import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "io.github.dpulpeiro.collie"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  property string status: "checking"
  property string detail: "Checking Collie…"
  property string collieUrl: ""
  property string error: ""
  property bool busy: false
  readonly property string controlScript: decodeURIComponent(
    Qt.resolvedUrl("scripts/collie-control").toString().replace(/^file:\/\//, ""))
  readonly property bool active: status === "running"
  readonly property color statusColor: active ? Color.accent
    : status === "partial" ? Color.urgent
    : Qt.darker(root.barForeground, 1.55)

  function open() {
    root.controller.show()
    refresh()
  }

  function close() {
    root.controller.hide()
  }

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.hostWidget || root, direction)
    return false
  }

  function refresh() {
    if (!statusProcess.running) statusProcess.running = true
  }

  function toggleCollie() {
    if (busy) return
    busy = true
    error = ""
    actionProcess.command = ["bash", root.controlScript, active ? "disable" : "enable"]
    actionProcess.running = true
  }

  Timer {
    interval: 5000
    repeat: true
    triggeredOnStart: true
    running: root.opened
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
        root.collieUrl = parts[2] || ""
      }
    }
  }

  Timer {
    interval: 120000
    running: root.busy
    onTriggered: {
      actionProcess.running = false
      root.busy = false
      root.error = "Collie toggle timed out"
      root.refresh()
    }
  }

  Process {
    id: actionProcess
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.error = String(text).trim()
    }
    onExited: function(exitCode) {
      root.busy = false
      if (exitCode !== 0 && root.error === "") root.error = "Collie toggle failed"
      root.refresh()
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.hostWidget || root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(340))
    contentHeight: panel.fittedContentHeight(content.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: content
        width: parent.width
        spacing: Style.space(12)

        RowLayout {
          width: parent.width

          Text {
            text: "Collie"
            color: root.barForeground
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.subtitle
            font.bold: true
            Layout.fillWidth: true
          }

          Text {
            text: root.busy ? "CHANGING…" : root.status.toUpperCase()
            color: root.statusColor
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.caption
          }
        }

        Text {
          width: parent.width
          text: root.detail
          textFormat: Text.PlainText
          color: root.barForeground
          opacity: 0.7
          wrapMode: Text.Wrap
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.bodySmall
        }

        Column {
          visible: root.collieUrl !== ""
          width: parent.width
          spacing: Style.space(4)

          Text {
            width: parent.width
            text: "Collie URL"
            color: root.barForeground
            opacity: 0.65
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.caption
          }

          Text {
            width: parent.width
            text: root.collieUrl
            textFormat: Text.PlainText
            color: Color.accent
            wrapMode: Text.WrapAnywhere
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.bodySmall
            font.underline: urlMouse.containsMouse

            MouseArea {
              id: urlMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: Quickshell.execDetached(["xdg-open", root.collieUrl])
            }
          }
        }

        Text {
          visible: root.error !== ""
          width: parent.width
          text: root.error
          textFormat: Text.PlainText
          color: Color.urgent
          wrapMode: Text.Wrap
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.bodySmall
        }

        Button {
          width: parent.width
          text: root.active ? "Disable Collie" : "Enable Collie"
          enabled: !root.busy
          onClicked: root.toggleCollie()
        }
      }
    }
  }
}
