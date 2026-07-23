import QtQuick 2.15
import QtQuick.Layouts 1.15

import "../common" as Com

Item {
    id: root
    property string video_path: ""
    property var stackView
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

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Com.LabelInput2 {
                id: input_start
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                label: qsTr("开始时间")
                placeholder: qsTr("00:10:54")
            }
            Com.LabelInput2 {
                id: input_end
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                label: qsTr("结束时间")
                placeholder: qsTr("00:15:04")
            }
        }

        Com.Button {
            Layout.fillWidth: true
            text_: qsTr("确认")
            onClicked: {
                save_path_select.dialog.open();
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

    Com.SavePathSelect {
        id: save_path_select
        input_video_path: videoPlay.video_path
        onSelected: {
            let file_path = remove_pre(videoPlay.video_path, "file://");
            cmd.push_ffmpeg_cmd(`ffmpeg -i ${in_path} -ss ${input_start.text} -to ${input_end.text} ${out_path}`);
            cmd.save_ffmpeg_cmd();
            cmd.exec_ffmpeg();
        }
    }

    Ffmpeg_cmd {
        id: cmd
    }
}
