import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
  id: root
  property string label: qsTr("提示")
  property string placeholder: qsTr("输入...")


    property int    maxLength:   100         // 0 = 不限制
    property bool   showCounter: true
    property bool   readOnly:    false
    property bool   password:    false


    property color accentColor:        "#5B6AF5"
    property color errorColor:         "#E5534B"
    property color labelColor:         "#6B7280"
    property color textColor:          "#111827"
    property color borderColor:        "#D1D5DB"
    property color bgColor:            "#FFFFFF"


    readonly property bool atLimit:   maxLength > 0 && _field.length >= maxLength
    readonly property bool nearLimit: maxLength > 0 && _field.length >= maxLength * 0.85
    readonly property int  remaining: maxLength > 0 ? maxLength - _field.length : -1

    implicitWidth:  320
    implicitHeight: _col.implicitHeight

  ColumnLayout {
        id: _col
        anchors { left: parent.left; right: parent.right }
        spacing: 4

        // 前导提示标签
        Text {
            Layout.fillWidth: true
            text:  root.label
            font.pixelSize: 13
            font.weight: Font.Medium
            color: _field.activeFocus ? root.accentColor : root.labelColor
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 40
            radius: 8
            color:  root.bgColor

            border.width: _field.activeFocus ? 2 : 1
            border.color: {
                if (root.atLimit)        return root.errorColor
                if (_field.activeFocus)  return root.accentColor
                return root.borderColor
            }
            Behavior on border.color { ColorAnimation { duration: 150 } }

            TextField {
                id: _field
                anchors {
                    fill: parent
                    leftMargin: 12; rightMargin: 12
                    topMargin: 2;   bottomMargin: 2
                }

                placeholderText: root.placeholder
                color:           root.textColor
                readOnly:        root.readOnly
                echoMode:        root.password ? TextInput.Password : TextInput.Normal
                maximumLength:   root.maxLength > 0 ? root.maxLength : 32767
                font.pixelSize:  14
                wrapMode:        TextInput.NoWrap
                verticalAlignment: TextInput.AlignVCenter

                background:   Item {}   // 去掉默认背景
                leftPadding:  0
                rightPadding: 0

                // 内部 → root.text（用 Qt.callLater 打破可能的绑定循环）
                onTextChanged: Qt.callLater(function() {
                    if (root.text !== _field.text)
                        root.text = _field.text
                })

                // 自定义光标
                cursorDelegate: Rectangle {
                    width: 2
                    color: root.accentColor
                    visible: _field.cursorVisible
                    SequentialAnimation on opacity {
                        running: _field.cursorVisible
                        loops:   Animation.Infinite
                        NumberAnimation { to: 0; duration: 500 }
                        NumberAnimation { to: 1; duration: 500 }
                    }
                }
            }
        }
  }
}
