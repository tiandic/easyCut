pragma ComponentBehavior: Bound

import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls

import "../common" as Com

Item {
    id: root
    property string video_path: ""
    property string subtitles_file_path: "" // 临时字幕文件路径
    property var stackView

    property string default_start_time: "00:00:00,000"
    property string default_end_time: "00:00:04,000"

    function check_input(text) {
        let l;
        if (text == "")
            return qsTr("输入不可为空!");
        else if (text.split(',') > 2)
            return qsTr("输入必须有且只有一个逗号!");
        else if (!(l = check_limit(text, "1234567890,:"))[0])
            return qsTr(`输入不应包含字符 '${l[1]}'`);
        else if (text.length < default_start_time.length)
            return qsTr(`输入长度过短! 正确长度应为 ${default_start_time.length}`);
        else if (text.length > default_start_time.length)
            return qsTr(`输入长度过长! 正确长度应为 ${default_start_time.length}`);
        return "";
    }

    function check_limit(text, limit_chars) {
        for (let i = 0; i < text.length; i++) {
            if (limit_chars.indexOf(text[i]) == -1)
                return [false, text[i]];
        }
        return [true, ""];
    }

    ListModel {
        id: list_data
        onCountChanged: {
            while (true) {
                if (sort_data())
                    break;
            }
            sync_subtitles_file();
            if (count > 0) {
                videoPlay.video_provider.init_filters(`subtitles=${root.subtitles_file_path}`);
                videoPlay.video_provider.seek(Math.max(0, videoPlay.video_provider.progressTime - 3));
                videoPlay.video_provider.show_a_frame();
            } else {
                videoPlay.video_provider.remove_filters();
                videoPlay.video_provider.seek(Math.max(0, videoPlay.video_provider.progressTime - 3));
                videoPlay.video_provider.show_a_frame();
            }
        }

        function sync_subtitles_file() {
            let subtitles_text = "";

            for (let i = 0; i < list_data.count; i++)
                subtitles_text += `${i + 1}\n${list_data.get(i).start_time} --> ${list_data.get(i).end_time}\n${list_data.get(i).subtitles}\n\n`;

            if (subtitles_file_path == "") {
                root.subtitles_file_path = cmd.echo_tmp_file("subtitles.srt", subtitles_text, true);
                console.log(qsTr("创建了临时字幕文件:"), root.subtitles_file_path);
            } else {
                cmd.over_write_file(root.subtitles_file_path, subtitles_text);
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
                onClicked: root.stackView.pop()
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
                required property string start_time
                required property string end_time
                required property string subtitles
                required property int index

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
                            text: delegate_root.start_time + " → " + delegate_root.end_time
                        }

                        ScrollView {
                            Layout.fillWidth: true
                            Text {
                                text: delegate_root.subtitles
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
                        Layout.preferredHeight: 26.66
                        Layout.preferredWidth: Layout.preferredHeight + 5
                        Layout.alignment: Qt.AlignRight
                        text_: qsTr("X")
                        onClicked: {
                            list_data.remove(delegate_root.index);
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
                    let m;
                    if ((m = root.check_input(input_start.text)) != "") {
                        msg.text = qsTr("字幕的开始时间格式错误: ") + m;
                        msg.open();
                    } else if ((m = root.check_input(input_end.text)) != "") {
                        msg.text = qsTr("字幕的结束时间格式错误: ") + m;
                        msg.open();
                    } else if (input_start.text == input_end.text) {
                        msg.text = qsTr("字幕的开始时间与结束时间不能相同!");
                        msg.open();
                    } else if (input_subtitles.text == "") {
                        msg.text = qsTr("添加的字幕不应为空!");
                        msg.open();
                    } else {
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
            }
            Item {
                Layout.preferredHeight: 20
            }
            Com.Button {
                Layout.fillWidth: true
                text_: qsTr("添加完成")
                onClicked: {
                    if (list_data.count == 0) {
                        msg.text = qsTr("至少应添加一条字幕!");
                        msg.open();
                    } else {
                        save_path_select.dialog.open();
                    }
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
            let subtitle_codec = root.get_subtitle_codec(root.get_extension(out_path));
            if (subtitle_codec)
                cmd.push_ffmpeg_cmd(`ffmpeg -y -i "${in_path}" -i "${root.subtitles_file_path}" -c:s ${subtitle_codec} ${out_path}`);
            else
                cmd.push_ffmpeg_cmd(`ffmpeg -y -i "${in_path}" -vf "subtitles=${root.subtitles_file_path}" ${out_path}`);
            cmd.exec_ffmpeg(root.subtitles_file_path);
        }
    }

    Com.MsgDialog {
        id: msg
    }

    Ffmpeg_cmd {
        id: cmd
    }
}
