import QtQuick 2.15
import QtQuick.Dialogs
import QtQuick.Layouts 1.15
import QtCore

import "../common" as Com

Item {
    id: root
    property string video_path: ""
    property var stackView

    function exec_ffmpeg() {
        let in_path = cmd.cvt_file_url_to_local(videoPlay.video_path);
        let save_path = cmd.cvt_file_url_to_local(out_dir_path_select.selectedFolder.toString()) + "/" + input_format.text;

        cmd.push_ffmpeg_cmd(`ffmpeg -y -i "${in_path}" "${save_path}"`);
        cmd.exec_ffmpeg();
    }

    ListModel {
        id: list_data
    }

    ColumnLayout {
        id: input
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left

        width: 320
        spacing: 5

        Item {
            Layout.preferredHeight: 10
        }
        RowLayout {
            Item {
                Layout.preferredWidth: 10
            }
            Com.Button {
                text_: qsTr("← 返回")
                onClicked: stackView.pop()
                Layout.preferredWidth: 80
                Layout.preferredHeight: 30
            }
        }
        Item {
            Layout.preferredHeight: 10
        }

        Com.LabelInput2 {
            id: input_format
            Layout.fillWidth: true
            label: qsTr("输出格式")

            text: "frame_%06d.png"
        }

        Com.Button {
            Layout.fillWidth: true
            text_: qsTr("确认")
            onClicked: {
                if (input_format.text.indexOf('/') != -1) {
                    msg.text = qsTr("输出格式中不应包含 '/'");
                } else if (input_format.text.indexOf('\\') != -1) {
                    msg.text = qsTr("输出格式中不应包含 '\\'");
                } else {
                    out_dir_path_select.open();
                }
            }
        }
        Item {
            Layout.fillHeight: true
        }  // 避免 ColumnLayout 自动设置间隔
    }

    Com.VideoPlay {
        id: videoPlay
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.left: input.right

        anchors.rightMargin: 10
        anchors.leftMargin: 30

        video_path: root.video_path
    }

    FolderDialog {
        id: out_dir_path_select
        title: qsTr("选择保存位置")
        currentFolder: StandardPaths.standardLocations(StandardPaths.PicturesLocation)[0]

        onAccepted: {
            let dir_path = cmd.cvt_file_url_to_local(out_dir_path_select.selectedFolder.toString());
            let llll = cmd.scan_dir(dir_path);
            console.log(llll);
            if (llll.length > 2) {
                msg_warning.text = dir_path + "\n" + msg_warning.text;
                msg_warning.open();
            } else {
                exec_ffmpeg();
            }
        }
    }

    Com.MsgDialog {
        id: msg
    }
    Com.MsgDialog {
        id: msg_warning
        title: qsTr("警告!")
        text: qsTr("选择的目录不为空! 确定要将所有帧的文件输出到该目录下吗?")
        buttons: MessageDialog.Ok | MessageDialog.Cancel
        onButtonClicked: function (button, role) {
            switch (button) {
            case MessageDialog.Ok:
                exec_ffmpeg();
                break;
            }
        }
    }

    Ffmpeg_cmd {
        id: cmd
    }
}
