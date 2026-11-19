/***************************************************************************
* Copyright (c) 2013 Abdurrahman AVCI <abdurrahmanavci@gmail.com>
* Copyright (c) 2024 Aleksei Bavshin <alebastr@fedoraproject.org>
*
* Baseado no tema 03-sway-fedora. Cores da waybar/swaylock:
*   fundo #14161c, texto #c8ccd4, apagado #6b7280, destaque #8ab4f8,
*   aviso #e5c07b, erro #e06c75, ok #98c379
*
* Permission is hereby granted, free of charge, to any person
* obtaining a copy of this software and associated documentation
* files (the "Software"), to deal in the Software without restriction,
* including without limitation the rights to use, copy, modify, merge,
* publish, distribute, sublicense, and/or sell copies of the Software,
* and to permit persons to whom the Software is furnished to do so,
* subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included
* in all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
* OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
* THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
* OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
* ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE
* OR OTHER DEALINGS IN THE SOFTWARE.
*
***************************************************************************/

import QtQuick 2.0
import SddmComponents 2.0

Rectangle {
    id: container
    width: 640
    height: 480

    readonly property color cBg:     config.backgroundColor || "#14161c"
    readonly property color cCard:   "#e614161c"
    readonly property color cField:  "#1c1f27"
    readonly property color cBorder: "#2a2e38"
    readonly property color cFg:     "#c8ccd4"
    readonly property color cDim:    "#6b7280"
    readonly property color cAccent: "#8ab4f8"
    readonly property color cWarn:   "#e5c07b"
    readonly property color cCrit:   "#e06c75"
    readonly property color cOk:     "#98c379"
    readonly property string fontFamily: config.font || "Noto Sans Mono"

    color: cBg

    LayoutMirroring.enabled: Qt.locale().textDirection == Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    property int sessionIndex: session.index

    TextConstants { id: textConstants }

    function doLogin() {
        errorMessage.color = cDim
        errorMessage.text = "…"
        sddm.login(name.text, password.text, sessionIndex)
    }

    Connections {
        target: sddm

        function onLoginSucceeded() {
            errorMessage.color = cOk
            errorMessage.text = textConstants.loginSucceeded
        }
        function onLoginFailed() {
            password.text = ""
            password.focus = true
            errorMessage.color = cCrit
            errorMessage.text = textConstants.loginFailed
        }
        function onInformationMessage(message) {
            errorMessage.color = cWarn
            errorMessage.text = message
        }
    }

    // Fundo: imagem (se existir) + véu escuro; sem imagem fica a cor sólida
    Image {
        anchors.fill: parent
        source: config.background ? Qt.resolvedUrl(config.background) : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        visible: status == Image.Ready
    }
    Rectangle {
        anchors.fill: parent
        color: cBg
        opacity: config.dim !== undefined && config.dim !== "" ? Number(config.dim) : 0.45
    }

    // Relógio
    Column {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 32
        spacing: 2

        Text {
            id: timeLabel
            anchors.right: parent.right
            color: cFg
            font.family: fontFamily
            font.pixelSize: 56
            text: Qt.formatTime(new Date(), "HH:mm")
        }
        Text {
            id: dateLabel
            anchors.right: parent.right
            color: cFg
            opacity: 0.85
            font.family: fontFamily
            font.pixelSize: 16
            text: Qt.formatDate(new Date(), "dddd, d MMMM yyyy")
        }
        Timer {
            interval: 1000; running: true; repeat: true
            onTriggered: {
                var now = new Date()
                timeLabel.text = Qt.formatTime(now, "HH:mm")
                dateLabel.text = Qt.formatDate(now, "dddd, d MMMM yyyy")
            }
        }
    }

    // Cartão de login
    Rectangle {
        id: card
        anchors.centerIn: parent
        width: 380
        height: mainColumn.implicitHeight + 56
        radius: 10
        color: cCard
        border.color: cBorder
        border.width: 1

        Column {
            id: mainColumn
            anchors.centerIn: parent
            width: parent.width - 56
            spacing: 14

            Text {
                width: parent.width
                color: cFg
                text: sddm.hostName
                font.family: fontFamily
                font.pixelSize: 22
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }

            Rectangle { width: parent.width; height: 1; color: cBorder }

            Column {
                width: parent.width
                spacing: 6
                Text {
                    text: textConstants.userName
                    color: cDim
                    font.family: fontFamily
                    font.pixelSize: 12
                }
                TextBox {
                    id: name
                    width: parent.width; height: 34
                    text: userModel.lastUser
                    font.family: fontFamily
                    font.pixelSize: 15
                    radius: 6
                    color: cField; textColor: cFg
                    borderColor: cBorder; hoverColor: cDim; focusColor: cAccent

                    KeyNavigation.backtab: shutdownButton; KeyNavigation.tab: password

                    Keys.onPressed: function (event) {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            doLogin()
                            event.accepted = true
                        }
                    }
                }
            }

            Column {
                width: parent.width
                spacing: 6
                Text {
                    text: textConstants.password
                    color: cDim
                    font.family: fontFamily
                    font.pixelSize: 12
                }
                PasswordBox {
                    id: password
                    width: parent.width; height: 34
                    font.family: fontFamily
                    font.pixelSize: 15
                    radius: 6
                    color: cField; textColor: cFg
                    borderColor: cBorder; hoverColor: cDim; focusColor: cAccent
                    tooltipBG: cField; tooltipFG: cWarn

                    KeyNavigation.backtab: name; KeyNavigation.tab: session

                    Keys.onPressed: function (event) {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            doLogin()
                            event.accepted = true
                        }
                    }
                }
                Text {
                    // Aviso de Caps Lock, como no swaylock
                    visible: keyboard.capsLock
                    text: "Caps Lock"
                    color: cWarn
                    font.family: fontFamily
                    font.pixelSize: 12
                }
            }

            Column {
                width: parent.width
                spacing: 6
                z: 100
                Text {
                    text: textConstants.session
                    color: cDim
                    font.family: fontFamily
                    font.pixelSize: 12
                }
                ComboBox {
                    id: session
                    width: parent.width; height: 34
                    font.family: fontFamily
                    font.pixelSize: 15
                    color: cField; menuColor: cField; textColor: cFg
                    borderColor: cBorder; hoverColor: cDim; focusColor: cAccent
                    arrowColor: cField
                    arrowIcon: Qt.resolvedUrl("angle-down.svg")

                    model: sessionModel
                    index: sessionModel.lastIndex

                    KeyNavigation.backtab: password; KeyNavigation.tab: loginButton
                }
            }

            Text {
                id: errorMessage
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: " "
                color: cDim
                font.family: fontFamily
                font.pixelSize: 12
            }

            Button {
                id: loginButton
                width: parent.width; height: 36
                text: textConstants.login
                font.family: fontFamily
                font.pixelSize: 15
                color: "#2b3a55"; textColor: cFg
                activeColor: "#3b5480"; pressedColor: cAccent

                onClicked: doLogin()

                KeyNavigation.backtab: session; KeyNavigation.tab: suspendButton
            }

            Row {
                id: powerRow
                width: parent.width
                spacing: 8
                property int btnWidth: (width - 2 * spacing) / 3

                Button {
                    id: suspendButton
                    width: powerRow.btnWidth; height: 30
                    text: textConstants.suspend
                    font.family: fontFamily; font.pixelSize: 12
                    color: cField; textColor: cDim
                    activeColor: cBorder; pressedColor: cDim
                    enabled: sddm.canSuspend
                    disabledColor: cField
                    opacity: enabled ? 1 : 0.4
                    onClicked: sddm.suspend()
                    KeyNavigation.backtab: loginButton; KeyNavigation.tab: rebootButton
                }
                Button {
                    id: rebootButton
                    width: powerRow.btnWidth; height: 30
                    text: textConstants.reboot
                    font.family: fontFamily; font.pixelSize: 12
                    color: cField; textColor: cDim
                    activeColor: cBorder; pressedColor: cDim
                    onClicked: sddm.reboot()
                    KeyNavigation.backtab: suspendButton; KeyNavigation.tab: shutdownButton
                }
                Button {
                    id: shutdownButton
                    width: powerRow.btnWidth; height: 30
                    text: textConstants.shutdown
                    font.family: fontFamily; font.pixelSize: 12
                    color: cField; textColor: cCrit
                    activeColor: cBorder; pressedColor: cCrit
                    onClicked: sddm.powerOff()
                    KeyNavigation.backtab: rebootButton; KeyNavigation.tab: name
                }
            }
        }
    }

    Component.onCompleted: {
        if (name.text == "")
            name.focus = true
        else
            password.focus = true
    }
}
