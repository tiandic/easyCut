import QtQuick 2.15
import QtQuick.Dialogs
import QtQuick.Layouts 1.15
import QtQuick.Controls
import QtCore

import "../common" as Com

Item {
    id: root
    property string video_path: ""
    property string subtitles_file_path: "" // 临时字幕文件路径
    property var stackView

    property string default_start_time: "00:00:00,000"
    property string default_end_time: "00:00:04,000"

    ListModel {
        id: list_data
        onCountChanged: {
            while (true) {
                if (sort_data())
                    break;
            }
        }

        function sort_data() {
            for (let i = 1; i < list_data.count; i++) {
                if (list_data.get(i - 1).start_time > list_data.get(i).start_time) {
                    list_data.move(i - 1, i, 1);
                    return false;
                }
            }
            return true;
        }
    }

    function get_extension(filename) {
        if (!filename)
            return '';
        console.debug("get_extension():", filename);
        const idx = filename.lastIndexOf('.');
        if (idx === -1 || idx === 0)
            return '';
        return filename.slice(idx + 1);
    }

    function get_subtitle_codec(ext) {
        const extension = ext.toLowerCase().replace(/^\./, '');

        const movTextContainers = ['mp4', 'm4v', 'mov', 'qt', '3gp', '3g2'];

        const copyContainers = ['mkv', 'mka'];

        const webvttContainers = ['webm'];

        if (movTextContainers.includes(extension)) {
            return 'mov_text';
        }
        if (copyContainers.includes(extension)) {
            return 'copy';
        }
        if (webvttContainers.includes(extension)) {
            return 'webvtt';
        }

        return null;
    }

    ColumnLayout {
        id: input
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left

        width: 360
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
        ListView {
            id: listview
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10

            width: parent.width / 5

            model: list_data

            add: Transition {
                NumberAnimation {
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 300
                }
                NumberAnimation {
                    property: "y"
                    from: -20
                    duration: 300
                }
            }

            remove: Transition {
                NumberAnimation {
                    property: "opacity"
                    to: 0
                    duration: 200
                }
            }

            delegate: Rectangle {
                id: delegate_root
                width: listview.width
                height: 40 * ((subtitles.match(/\n/g) || []).length + 1)
                border.width: 1
                radius: 5
                border.color: "gray"
                clip: true

                RowLayout {
                    anchors.fill: parent

                    Item {
                        Layout.preferredWidth: 3
                        Layout.alignment: Qt.AlignLeft
                    }

                    ColumnLayout {
                        Layout.preferredHeight: parent.height / 3
                        Layout.alignment: Qt.AlignLeft
                        Text {
                            text: start_time + " → " + end_time
                        }

                        ScrollView {
                            Layout.fillWidth: true
                            Text {
                                text: subtitles
                            }
                        }
                    }

                    ListView.onRemove: removeAnim.start()
                    ListView.delayRemove: removeAnim.running
                    SequentialAnimation {
                        id: removeAnim
                        PropertyAction {
                            target: delegate_root
                            property: "ListView.delayRemove"
                            value: true
                        }
                        NumberAnimation {
                            target: delegate_root
                            property: "opacity"
                            to: 0
                            duration: 200
                        }
                        PropertyAction {
                            target: delegate_root
                            property: "ListView.delayRemove"
                            value: false
                        }
                    }

                    Com.Button {
                        Layout.preferredHeight: parent.height / 1.5
                        Layout.preferredWidth: Layout.preferredHeight + 5
                        Layout.alignment: Qt.AlignRight
                        text_: qsTr("X")
                        onClicked: {
                            list_data.remove(index);
                        }
                    }
                    Item {
                        Layout.preferredWidth: 3
                        Layout.alignment: Qt.AlignRight
                    }
                }
            }

            anchors {
                leftMargin: width / 9
                topMargin: width / 12
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 150
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Com.LabelInput2 {
                    id: input_start
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    label: qsTr("开始时间")
                    placeholder: qsTr("00:00:00,000")
                    text: root.default_start_time
                }
                Com.LabelInput2 {
                    id: input_end
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    label: qsTr("结束时间")
                    placeholder: qsTr("00:00:04,000")
                    text: root.default_end_time
                }
            }
            Com.LabelInput {
                id: input_subtitles
                Layout.fillWidth: true
                label: qsTr("字幕")
                placeholder: qsTr("欢迎观看本视频")
            }
            Com.Button {
                Layout.fillWidth: true
                text_: qsTr("确认添加")
                onClicked: {
                    list_data.append({
                        "start_time": input_start.text,
                        "end_time": input_end.text,
                        "subtitles": input_subtitles.text
                    });
                    input_start.text = input_end.text;
                    input_end.text = input_start.text;
                    input_subtitles.text = "";
                }
            }
            Item {
                Layout.preferredHeight: 20
            }
            Com.Button {
                Layout.fillWidth: true
                text_: qsTr("添加完成")
                onClicked: {
                    let subtitles_text = "";

                    for (let i = 0; i < list_data.count; i++)
                        subtitles_text += `${i + 1}\n${list_data.get(i).start_time} --> ${list_data.get(i).end_time}\n${list_data.get(i).subtitles}\n\n`;

                    root.subtitles_file_path = cmd.echo_tmp_file("subtitles.srt", subtitles_text, true);
                    console.log(qsTr("创建了临时字幕文件:"), root.subtitles_file_path);
                    save_path_select.dialog.open();
                }
            }
        }
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
        onSelected: function (in_path, out_path) {
            let subtitle_codec = get_subtitle_codec(get_extension(out_path));
            if (subtitle_codec)
                cmd.push_ffmpeg_cmd(`ffmpeg -y -i "${in_path}" -i "${root.subtitles_file_path}" -c:s ${subtitle_codec} ${out_path}`);
            else
                cmd.push_ffmpeg_cmd(`ffmpeg -y -i "${in_path}" -vf "subtitles=${root.subtitles_file_path}" ${out_path}`);
            cmd.exec_ffmpeg(root.subtitles_file_path);
        }
    }

    Ffmpeg_cmd {
        id: cmd
    }
}
