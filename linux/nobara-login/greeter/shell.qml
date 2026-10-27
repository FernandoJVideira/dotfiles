// Login screen: a Quickshell greeter for greetd, run inside cage (see remove-kde.sh), styled after
// Omarchy's: a plain background, the logo and a lock next to an outlined entry box that fills with bullets.
// Theme.qml (colors, user, logo, primary monitor) is written by greeter-theme-sync.
import QtQuick
import Quickshell
import Quickshell.Services.Greetd

ShellRoot {
  id: root

  // the Omadora session, same command as /usr/share/wayland-sessions/omadora.desktop
  readonly property var sessionCommand: ["uwsm", "start", "-e", "-D", "Hyprland", "-N", "Hyprland", "--", "/usr/bin/start-hyprland"]

  property string notice: ""
  property bool failed: false
  property bool busy: false
  property bool sessionOpen: false
  property string pending: ""

  Theme { id: theme }

  // cage stretches one window over every monitor, so the screens are laid out inside it by hand: the
  // form goes on the primary monitor and the others just get the background
  readonly property real originX: {
    var m = Infinity
    for (var i = 0; i < Quickshell.screens.length; i++) m = Math.min(m, Quickshell.screens[i].x)
    return m
  }
  readonly property real originY: {
    var m = Infinity
    for (var i = 0; i < Quickshell.screens.length; i++) m = Math.min(m, Quickshell.screens[i].y)
    return m
  }
  readonly property var primaryScreen: {
    var best = null
    for (var i = 0; i < Quickshell.screens.length; i++) {
      var s = Quickshell.screens[i]
      if (s.name === theme.primary) return s
      if (best === null || s.x < best.x) best = s
    }
    return best
  }

  Component.onCompleted: {
    // shows up in `journalctl -b -u greetd`: which monitor the form went to, and why
    for (var i = 0; i < Quickshell.screens.length; i++) {
      var s = Quickshell.screens[i]
      console.log("greeter screen", s.name, s.x, s.y, s.width, s.height)
    }
    console.log("greeter primary wanted:", theme.primary, "using:", root.primaryScreen ? root.primaryScreen.name : "none")
  }

  function submit() {
    if (root.busy || entry.text === "") return
    root.busy = true
    root.notice = ""
    root.pending = entry.text
    entry.text = ""
    if (root.sessionOpen) {
      Greetd.respond(root.pending)
      root.pending = ""
    } else {
      root.sessionOpen = true
      Greetd.createSession(theme.user)
    }
  }

  Connections {
    target: Greetd

    function onAuthMessage(message, error, responseRequired, echoResponse) {
      if (responseRequired && root.pending !== "") {
        Greetd.respond(root.pending)
        root.pending = ""
        return
      }
      root.notice = message
      root.failed = error
      if (responseRequired) root.busy = false
    }

    function onAuthFailure(message) {
      root.sessionOpen = false
      root.busy = false
      root.failed = true
      entry.forceActiveFocus()
    }

    function onReadyToLaunch() {
      Greetd.launch(root.sessionCommand, ["XDG_SESSION_TYPE=wayland"])
    }

    function onError(error) {
      root.sessionOpen = false
      root.busy = false
      root.failed = true
      root.notice = error
    }
  }

  FloatingWindow {
    visible: true
    color: theme.background

    Rectangle {
      anchors.fill: parent
      color: theme.background
    }

    Item {
      x: root.primaryScreen ? root.primaryScreen.x - root.originX : 0
      y: root.primaryScreen ? root.primaryScreen.y - root.originY : 0
      width: root.primaryScreen ? root.primaryScreen.width : parent.width
      height: root.primaryScreen ? root.primaryScreen.height : parent.height

      Column {
        anchors.centerIn: parent
        spacing: 40

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: theme.logo
          color: theme.accent
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 14
          horizontalAlignment: Text.AlignHCenter
        }

        Row {
          anchors.horizontalCenter: parent.horizontalCenter
          spacing: 15

          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: ""
            color: root.failed ? theme.red : theme.foreground
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 40
          }

          Rectangle {
            width: 360
            height: 56
            color: "transparent"
            border.width: 2
            border.color: root.failed ? theme.red : theme.foreground

            Row {
              anchors.left: parent.left
              anchors.leftMargin: 20
              anchors.verticalCenter: parent.verticalCenter
              spacing: 5

              Repeater {
                model: Math.min(entry.text.length, 21)

                Rectangle {
                  width: 9
                  height: 9
                  radius: 4.5
                  color: root.failed ? theme.red : theme.foreground
                }
              }
            }

            // takes the typing; the bullets above stand in for its text
            TextInput {
              id: entry
              anchors.fill: parent
              echoMode: TextInput.Password
              color: "transparent"
              selectionColor: "transparent"
              selectedTextColor: "transparent"
              cursorDelegate: Item {}
              enabled: !root.busy
              focus: true
              onTextChanged: root.failed = false
              onEnabledChanged: if (enabled) forceActiveFocus()
              onAccepted: root.submit()
              Component.onCompleted: forceActiveFocus()
            }
          }
        }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: root.notice
          color: root.failed ? theme.red : theme.foreground
          font.pixelSize: 15
          visible: root.notice !== ""
        }
      }
    }
  }
}
