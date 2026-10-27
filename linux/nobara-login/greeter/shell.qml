// Login screen: a Quickshell greeter for greetd, run inside cage (see remove-kde.sh). Colors, the
// user name and the wallpaper come from Theme.qml and wallpaper.jpg, which greeter-theme-sync writes.
import QtQuick
import QtQuick.Controls
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
  SystemClock { id: clock; precision: SystemClock.Minutes }

  function submit() {
    if (root.busy || field.text === "") return
    root.busy = true
    root.notice = ""
    root.pending = field.text
    field.text = ""
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
      root.notice = "Wrong password"
      field.forceActiveFocus()
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

    Image {
      anchors.fill: parent
      source: "wallpaper.jpg"
      fillMode: Image.PreserveAspectCrop
      asynchronous: true
    }

    Rectangle {
      anchors.fill: parent
      color: theme.background
      opacity: 0.55
    }

    Column {
      anchors.centerIn: parent
      spacing: 18

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Qt.formatDateTime(clock.date, "HH:mm")
        color: theme.foreground
        font.pixelSize: 88
        font.weight: Font.Light
      }

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
        color: theme.foreground
        opacity: 0.8
        font.pixelSize: 20
      }

      Item { width: 1; height: 24 }

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: theme.user
        color: theme.foreground
        font.pixelSize: 22
      }

      TextField {
        id: field
        width: 320
        anchors.horizontalCenter: parent.horizontalCenter
        echoMode: TextInput.Password
        placeholderText: root.busy ? "…" : "Password"
        enabled: !root.busy
        focus: true
        color: theme.foreground
        placeholderTextColor: Qt.rgba(theme.foreground.r, theme.foreground.g, theme.foreground.b, 0.5)
        font.pixelSize: 18
        horizontalAlignment: TextInput.AlignHCenter
        background: Rectangle {
          radius: 8
          color: Qt.rgba(theme.background.r, theme.background.g, theme.background.b, 0.7)
          border.width: 2
          border.color: root.failed ? theme.red : theme.accent
        }
        onAccepted: root.submit()
        Component.onCompleted: forceActiveFocus()
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
