pragma ComponentBehavior: Bound

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: root
    property string label: qsTr("提示")
    property string placeholder: qsTr("输入...")
    property string text: ""

    property int maxLength: 800

    property color accentColor: "#5B6AF5"
    property color errorColor: "#E5534B"
    property color labelColor: "#6B7280"
    property color textColor: "#111827"
    property color borderColor: "#D1D5DB"
    property color bgColor: "#FFFFFF"

    implicitWidth: 320
    implicitHeight: row.implicitHeight

    property bool hasFocus: field.activeFocus

    RowLayout {
        id: row
        spacing: 8

        anchors.fill: parent

        // 前导提示标签
        Text {
            text: root.label
            font.pixelSize: 13
            color: field.activeFocus ? root.accentColor : root.labelColor
            Layout.alignment: Qt.AlignVCenter
            Behavior on color {
                ColorAnimation {
                    duration: 150
                }
            }
        }

        // 输入框
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: Math.max(40, field.implicitHeight + 4)
            radius: 8
            color: root.bgColor
            border.width: field.activeFocus ? 2 : 1
            border.color: {
                if (field.activeFocus)
                    return root.accentColor;
                return root.borderColor;
            }
            Behavior on border.color {
                ColorAnimation {
                    duration: 150
                }
            }

            TextArea {
                id: field
                text: root.text
                placeholderText: root.placeholder
                color: root.textColor
                font.pixelSize: 14
                wrapMode: TextArea.Wrap
                verticalAlignment: TextEdit.AlignTop
                background: Item {}
                selectByMouse: true

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        focus = false;
                    }
                }

                onTextChanged: Qt.callLater(function () {
                    if (root.maxLength > 0 && field.text.length > root.maxLength) {
                        field.text = field.text.substring(0, root.maxLength);
                        return;
                    }
                    if (root.text !== field.text)
                        root.text = field.text;
                })

                anchors {
                    fill: parent
                    leftMargin: 12
                    rightMargin: 12
                    topMargin: 2
                    bottomMargin: 2
                }

                cursorDelegate: Rectangle {
                    width: 2
                    color: root.accentColor
                    visible: field.cursorVisible
                    SequentialAnimation on opacity {
                        running: field.cursorVisible
                        loops: Animation.Infinite
                        NumberAnimation {
                            to: 0
                            duration: 500
                        }
                        NumberAnimation {
                            to: 1
                            duration: 500
                        }
                    }
                }
            }
        }
    }
}
