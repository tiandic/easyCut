import QtQuick 2.15
import QtQuick.Dialogs
import QtQuick.Layouts 1.15
import QtCore

import "../common" as Com

Item {
    id: root
    property string video_path: ""
    property var stackView

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
            Layout.preferredHeight: 20
        }
        Com.LabelInput2 {
            id: input_format
            Layout.fillWidth: true
            label: "输出格式"

            text: "frame_%06d.png"
        }

        Com.Button {
            Layout.fillWidth: true
            text_: qsTr("确认")
            onClicked: {
                out_dir_path_select.open();
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
            let in_path = cmd.cvt_file_url_to_local(videoPlay.video_path);
            let save_path = cmd.cvt_file_url_to_local(out_dir_path_select.selectedFolder.toString()) + "/" + input_format.text;

            cmd.push_ffmpeg_cmd(`ffmpeg -y -i "${in_path}" "${save_path}"`);
            cmd.save_ffmpeg_cmd();
            cmd.exec_ffmpeg();
        }
    }

    Ffmpeg_cmd {
        id: cmd
    }
}
