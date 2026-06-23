import QtQuick

Rectangle {
    property string text_: ""
    property int maxLength: 100
    radius: 10
    border.color: "gray"

    TextInput {
        anchors.fill: parent
        anchors.margins: 3
        anchors.leftMargin: 7
        anchors.rightMargin: 7
        text: text_
        maximumLength: maxLength
    }
}
