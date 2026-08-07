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
            Layout.preferredHeight: 10
        }

        RowLayout {
            Item {
                Layout.preferredWidth: 10
            }
            Com.Button {
                text_: qsTr("← 返回")
                onClicked: root.stackView.pop()
                Layout.preferredWidth: 80
                Layout.preferredHeight: 30
            }
        }

        Item {
            Layout.preferredHeight: 10
        }

        Com.Button {
            Layout.fillWidth: true
            text_: qsTr("确认")
            onClicked: {
                save_path_select.open();
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

    FileDialog {
        id: save_path_select
        title: qsTr("选择保存位置")
        fileMode: FileDialog.SaveFile
        currentFile: "out"
        currentFolder: StandardPaths.standardLocations(StandardPaths.MusicLocation)[0]
        nameFilters: [qsTr("音频文件 (*.mp3 *.wav *.aac *.flac *.ogg *.oga *.m4a *.wma *.opus *.ape *.ac3 *.eac3 *.dts *.amr *.aiff *.aif *.au *.ra *.mka *.tta *.wv *.caf *.dsf *.dff *.spx *.gsm *.voc *.mid *.midi *.pcm *.alac *.mp2 *.mp1 *.weba *.oga)"), qsTr("所有文件 (*)")]

        onAccepted: {
            let in_path = cmd.cvt_file_url_to_local(videoPlay.video_path);
            let save_path = cmd.cvt_file_url_to_local(save_path_select.selectedFile.toString());
            if (save_path.indexOf('.') === -1)
                save_path = save_path + '.' + cmd.get_most_suitable_out_audio_ext(in_path);

            let copy_codec = "";
            if (cmd.can_copy(in_path, cmd.get_extension(save_path), "audio"))
                copy_codec = "-c:a copy";

            cmd.push_ffmpeg_cmd(`ffmpeg -y -i "${in_path}" -vn ${copy_codec} "${save_path}"`);
            cmd.exec_ffmpeg();
        }
    }

    Ffmpeg_cmd {
        id: cmd
    }
}
