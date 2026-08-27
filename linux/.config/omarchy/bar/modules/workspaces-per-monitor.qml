import QtQuick
import Quickshell
import Quickshell.Hyprland

// Custom bar module (see /usr/share/omarchy/shell/plugins/bar/README.md,
// "Custom user modules") that shows only the workspace range assigned to
// the monitor this bar surface is rendered on, instead of the same global
// 1-5(-10) range on every screen. Wired into ~/.config/omarchy/shell.json
// by linux/configure-monitors.sh, which also supplies the per-monitor
// ranges via this widget's `settings.ranges` (screen name -> workspace id
// array). Deliberately a bare Item rather than extending the first-party
// qs.Ui.BarWidget/qs.Commons.Style helpers those internal widgets use —
// only `bar`/`moduleName`/`settings` and the plain Quickshell APIs are
// documented as stable for user-supplied modules.

Item {
  id: root

  property var bar
  property string moduleName
  property var settings

  // QsWindow is a Quickshell attached property available on any Item once
  // it's parented into a window; each monitor gets its own bar surface, so
  // this reliably identifies which physical output this instance is on.
  readonly property string screenName: root.QsWindow && root.QsWindow.window && root.QsWindow.window.screen
    ? String(root.QsWindow.window.screen.name || "") : ""

  function workspaceIds() {
    var ranges = settings && settings.ranges ? settings.ranges : ({})
    var configured = ranges[root.screenName]
    if (configured && configured.length > 0) return configured

    // No range configured for this screen (single-monitor setups, or a
    // monitor added since the last configure-monitors.sh run): fall back
    // to the same behavior as the stock omarchy.workspaces widget.
    var ids = [1, 2, 3, 4, 5]
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      var id = values[i].id
      if (id > 0 && id <= 10 && ids.indexOf(id) === -1) ids.push(id)
    }
    ids.sort(function(left, right) { return left - right })
    return ids
  }

  function workspaceOccupied(id) {
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      if (values[i].id === id) return values[i].toplevels.values.length > 0
    }
    return false
  }

  implicitWidth: row.implicitWidth + 8
  implicitHeight: bar ? bar.barSize : 26

  Row {
    id: row
    anchors.centerIn: parent
    spacing: 6

    Repeater {
      model: root.workspaceIds()

      Rectangle {
        required property int modelData

        readonly property bool focused: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id === modelData
        readonly property bool occupied: root.workspaceOccupied(modelData)

        width: 20
        height: 20
        radius: 4
        color: focused ? (root.bar ? root.bar.foreground : "white") : "transparent"
        opacity: occupied || focused ? 1 : 0.5

        Text {
          anchors.centerIn: parent
          text: modelData === 10 ? "0" : String(modelData)
          color: focused ? (root.bar ? root.bar.background : "black") : (root.bar ? root.bar.foreground : "white")
          font.family: root.bar ? root.bar.fontFamily : "monospace"
          font.pixelSize: 12
        }

        MouseArea {
          anchors.fill: parent
          onClicked: if (root.bar) root.bar.run("hyprctl dispatch workspace " + modelData)
        }
      }
    }
  }
}
