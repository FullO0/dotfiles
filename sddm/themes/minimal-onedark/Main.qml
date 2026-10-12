import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: config.bg || "#121212"

    property date currentTime: new Date()
    property int sessionIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
    property string currentUsername: userModel.lastUser || "user"
    property bool capsLockOn: false

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.currentTime = new Date()
    }

    // SDDM Event Connections
    Connections {
        target: sddm

        function onLoginSucceeded() {
            errorMessage.color = config.accent || "#87d787"
            errorMessage.text = "Logging in..."
        }

        function onLoginFailed() {
            passwordInput.text = ""
            errorMessage.color = config.error || "#ff8787"
            errorMessage.text = "Authentication failed"
            shakeAnimation.start()
            passwordInput.forceActiveFocus()
        }

        function onInformationMessage(message) {
            errorMessage.color = config.accentBlue || "#87d7ff"
            errorMessage.text = message
        }
    }

    // Background Image
    Image {
        id: bgImage
        anchors.fill: parent
        source: config.background || "assets/background.jpg"
        fillMode: Image.PreserveAspectCrop
        visible: status === Image.Ready
        asynchronous: true
    }

    // Dark Tint Overlay for OneDark aesthetic
    Rectangle {
        anchors.fill: parent
        color: config.bg || "#121212"
        opacity: parseFloat(config.dimBackground || "0.80")
    }

    // Top Bar (Session Selector)
    RowLayout {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 32
        spacing: 12
        z: 10

        ComboBox {
            id: sessionCombo
            model: sessionModel
            textRole: "name"
            currentIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
            onActivated: function(index) { root.sessionIndex = index }

            background: Rectangle {
                implicitWidth: 160
                implicitHeight: 38
                radius: 19
                color: sessionCombo.hovered ? (config.inputBg || "#262626") : (config.cardBg || "#1c1c1c")
                border.color: config.border || "#3a3a3a"
                border.width: 1
            }

            contentItem: Text {
                leftPadding: 16
                rightPadding: 16
                text: "󰌽  " + (sessionCombo.currentText || "Hyprland")
                font.family: config.font || "FiraCode Nerd Font"
                font.pixelSize: 13
                font.bold: true
                color: config.fgBright || "#cdd6f4"
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }

            indicator: Text {
                x: sessionCombo.width - width - 14
                y: (sessionCombo.height - height) / 2
                text: ""
                font.family: config.font || "FiraCode Nerd Font"
                font.pixelSize: 11
                color: config.fgMuted || "#808080"
            }

            delegate: ItemDelegate {
                width: sessionCombo.width
                highlighted: sessionCombo.highlightedIndex === index
                contentItem: Text {
                    text: model.name || ""
                    font.family: config.font || "FiraCode Nerd Font"
                    font.pixelSize: 13
                    color: highlighted ? (config.accent || "#87d787") : (config.fg || "#bcbcbc")
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: highlighted ? (config.inputBg || "#262626") : (config.cardBg || "#1c1c1c")
                }
            }

            popup: Popup {
                y: sessionCombo.height + 6
                width: sessionCombo.width
                implicitHeight: contentItem.implicitHeight + 12
                padding: 6
                background: Rectangle {
                    radius: 12
                    color: config.cardBg || "#1c1c1c"
                    border.color: config.border || "#3a3a3a"
                    border.width: 1
                }
                contentItem: ListView {
                    clip: true
                    implicitHeight: contentHeight
                    model: sessionCombo.popup.visible ? sessionCombo.delegateModel : null
                    currentIndex: sessionCombo.highlightedIndex
                }
            }
        }
    }

    // Center Content (Clock, Date, Login Card)
    ColumnLayout {
        anchors.centerIn: parent
        spacing: 28
        width: 360

        // Clock & Date
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 6

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatTime(root.currentTime, "HH:mm")
                font.family: config.font || "FiraCode Nerd Font"
                font.pixelSize: parseInt(config.clockFontSize || "64")
                font.bold: true
                color: config.fgBright || "#cdd6f4"
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatDate(root.currentTime, "dddd, MMMM d")
                font.family: config.font || "FiraCode Nerd Font"
                font.pixelSize: parseInt(config.dateFontSize || "16")
                color: config.fgMuted || "#808080"
            }
        }

        // Login Card
        Rectangle {
            id: loginCard
            Layout.fillWidth: true
            implicitHeight: cardContent.implicitHeight + 48
            radius: 16
            color: config.cardBg || "#1c1c1c"
            border.color: config.border || "#3a3a3a"
            border.width: 1

            // Shake Animation on Login Failure
            SequentialAnimation {
                id: shakeAnimation
                NumberAnimation { target: loginCard; property: "x"; from: loginCard.x; to: loginCard.x - 12; duration: 50 }
                NumberAnimation { target: loginCard; property: "x"; from: loginCard.x - 12; to: loginCard.x + 12; duration: 50 }
                NumberAnimation { target: loginCard; property: "x"; from: loginCard.x + 12; to: loginCard.x - 8; duration: 50 }
                NumberAnimation { target: loginCard; property: "x"; from: loginCard.x - 8; to: loginCard.x + 8; duration: 50 }
                NumberAnimation { target: loginCard; property: "x"; from: loginCard.x + 8; to: loginCard.x; duration: 50 }
            }

            ColumnLayout {
                id: cardContent
                anchors.fill: parent
                anchors.margins: 24
                spacing: 18

                // User Avatar and Name
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 12

                    Rectangle {
                        width: 44
                        height: 44
                        radius: 22
                        color: config.inputBg || "#262626"
                        border.color: config.borderFocused || "#87d787"
                        border.width: 1.5

                        Text {
                            anchors.centerIn: parent
                            text: ""
                            font.family: config.font || "FiraCode Nerd Font"
                            font.pixelSize: 18
                            color: config.accent || "#87d787"
                        }
                    }

                    Text {
                        text: root.currentUsername
                        font.family: config.font || "FiraCode Nerd Font"
                        font.pixelSize: 16
                        font.bold: true
                        color: config.fgBright || "#cdd6f4"
                    }
                }

                // Password Input Container
                Rectangle {
                    id: inputWrapper
                    Layout.fillWidth: true
                    height: 44
                    radius: 10
                    color: config.inputBg || "#262626"
                    border.color: passwordInput.activeFocus ? (config.borderFocused || "#87d787") : (config.border || "#3a3a3a")
                    border.width: passwordInput.activeFocus ? 1.5 : 1

                    Behavior on border.color {
                        ColorAnimation { duration: 150 }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 8
                        spacing: 8

                        Text {
                            text: ""
                            font.family: config.font || "FiraCode Nerd Font"
                            font.pixelSize: 14
                            color: passwordInput.activeFocus ? (config.accent || "#87d787") : (config.fgMuted || "#808080")
                        }

                        TextInput {
                            id: passwordInput
                            Layout.fillWidth: true
                            font.family: config.font || "FiraCode Nerd Font"
                            font.pixelSize: 13
                            color: config.fgBright || "#cdd6f4"
                            echoMode: TextInput.Password
                            passwordCharacter: "•"
                            selectionColor: config.accent || "#87d787"
                            selectedTextColor: config.bg || "#121212"
                            clip: true
                            focus: true

                            Text {
                                text: "Password"
                                visible: !passwordInput.text && !passwordInput.activeFocus
                                color: config.fgMuted || "#808080"
                                font: passwordInput.font
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Keys.onPressed: function(event) {
                                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    sddm.login(root.currentUsername, passwordInput.text, root.sessionIndex)
                                    event.accepted = true
                                }
                            }
                        }

                        // Submit Button
                        Rectangle {
                            width: 30
                            height: 30
                            radius: 15
                            color: submitMouse.containsMouse ? (config.accent || "#87d787") : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: "󰁔"
                                font.family: config.font || "FiraCode Nerd Font"
                                font.pixelSize: 15
                                color: submitMouse.containsMouse ? (config.bg || "#121212") : (config.accent || "#87d787")
                            }

                            MouseArea {
                                id: submitMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: sddm.login(root.currentUsername, passwordInput.text, root.sessionIndex)
                            }
                        }
                    }
                }

                // Caps Lock Indicator
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    visible: root.capsLockOn
                    spacing: 6

                    Text {
                        text: "󰪛"
                        font.family: config.font || "FiraCode Nerd Font"
                        font.pixelSize: 12
                        color: config.warning || "#ffaf5f"
                    }

                    Text {
                        text: "Caps Lock is on"
                        font.family: config.font || "FiraCode Nerd Font"
                        font.pixelSize: 12
                        color: config.warning || "#ffaf5f"
                    }
                }

                // Error Message
                Text {
                    id: errorMessage
                    Layout.alignment: Qt.AlignHCenter
                    font.family: config.font || "FiraCode Nerd Font"
                    font.pixelSize: 12
                    font.bold: true
                    color: config.error || "#ff8787"
                    visible: text.length > 0
                }
            }
        }
    }

    // Bottom Bar (Brand / Power Menu)
    RowLayout {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 28

        // Hostname / Distro Label
        Text {
            text: "Arch Linux"
            font.family: config.font || "FiraCode Nerd Font"
            font.pixelSize: 12
            color: config.fgMuted || "#808080"
        }

        Item { Layout.fillWidth: true }

        // Power Buttons
        RowLayout {
            spacing: 12

            // Suspend Button
            Rectangle {
                width: 38
                height: 38
                radius: 19
                color: suspendMouse.containsMouse ? (config.inputBg || "#262626") : (config.cardBg || "#1c1c1c")
                border.color: config.border || "#3a3a3a"
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "󰒲"
                    font.family: config.font || "FiraCode Nerd Font"
                    font.pixelSize: 15
                    color: suspendMouse.containsMouse ? (config.accentBlue || "#87d7ff") : (config.fg || "#bcbcbc")
                }

                MouseArea {
                    id: suspendMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: sddm.suspend()
                }
            }

            // Reboot Button
            Rectangle {
                width: 38
                height: 38
                radius: 19
                color: rebootMouse.containsMouse ? (config.inputBg || "#262626") : (config.cardBg || "#1c1c1c")
                border.color: config.border || "#3a3a3a"
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "󰜉"
                    font.family: config.font || "FiraCode Nerd Font"
                    font.pixelSize: 15
                    color: rebootMouse.containsMouse ? (config.warning || "#ffaf5f") : (config.fg || "#bcbcbc")
                }

                MouseArea {
                    id: rebootMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: sddm.reboot()
                }
            }

            // Shutdown Button
            Rectangle {
                width: 38
                height: 38
                radius: 19
                color: shutdownMouse.containsMouse ? (config.inputBg || "#262626") : (config.cardBg || "#1c1c1c")
                border.color: config.border || "#3a3a3a"
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "⏻"
                    font.family: config.font || "FiraCode Nerd Font"
                    font.pixelSize: 15
                    color: shutdownMouse.containsMouse ? (config.error || "#ff8787") : (config.fg || "#bcbcbc")
                }

                MouseArea {
                    id: shutdownMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: sddm.powerOff()
                }
            }
        }
    }
}
