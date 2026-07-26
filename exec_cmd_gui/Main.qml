import QtQuick
import QtQuick.Controls

ApplicationWindow {
    visible: true
    width: 800
    height: 500

    ExecRunner {
        id: runner
    }

    ScrollView {
        anchors.fill: parent

        TextArea {
            readOnly: true
            wrapMode: TextArea.Wrap
            text: runner.output
            font.family: "Consolas, Monaco, monospace"
            color: "#00ff00"
            background: Rectangle {
                color: "black"
            }

            onTextChanged: {
                cursorPosition = length;
            }
        }
    }
    Component.onCompleted: {
        if (Qt.application.arguments[1] != "")
            runner.set_rm_file_path(Qt.application.arguments[1]);
        runner.run(Qt.application.arguments[2], Qt.application.arguments.slice(3));
    }
}
