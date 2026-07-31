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

    // 当输入为 need_most_value_char 时, 指定输入框应该被替换为最值, 最值由输入框的 placeholder 属性决定
    property string need_most_value_char: '-'

    property string default_start_time: "00:00:00,000"
    property string default_end_time: "00:00:04,000"

    // 用于判断输入的字幕时间是否发生重叠
    property list<string> already_use_start_times: []
    property list<string> already_use_end_times: []

    function check_input(text) {
        let l;
        if (text == "")
            return qsTr("输入不可为空!");
        else if (text.split(',') > 2)
            return qsTr("输入必须有且只有一个逗号!");
        else if ((l = check_limit(text, "1234567890,:" + need_most_value_char)) != "")
            return qsTr(`输入不应包含字符 '${l}'`);
        else if (text.indexOf(need_most_value_char) != -1 && text.length != 1)
            return qsTr(`如果希望选取最值, 请只填写 '${need_most_value_char}' 字符, 否则需要去掉 '${need_most_value_char}'`);
        else if (text != need_most_value_char && text.length < default_start_time.length)
            return qsTr(`输入长度过短! 正确长度应为 ${default_start_time.length}`);
        else if (text != need_most_value_char && text.length > default_start_time.length)
            return qsTr(`输入长度过长! 正确长度应为 ${default_start_time.length}`);
        else if ((l = check_time(text)) != "")
            return (`输入不应在 ${l} 之间`);
        return "";
    }

    function check_limit(text, limit_chars) {
        for (let i = 0; i < text.length; i++) {
            if (limit_chars.indexOf(text[i]) == -1)
                return text[i];
        }
        return "";
    }

    function check_time(t) {
        t = cvt_time_to_ms(t);
        for (let i = 0; i < already_use_start_times.length; i++) {
            if (t > cvt_time_to_ms(already_use_start_times[i]) && t < cvt_time_to_ms(already_use_end_times[i]))
                return `${already_use_start_times[i]} --> ${already_use_end_times[i]}`;
        }
        return "";
    }

    function get_end_subtitles_time() {
        // 获取 srt 时间格式的视频末尾时间
        let t = videoPlay.video_provider.get_total_time();
        // 毫秒
        let ms = (t % 100) * 10;
        t = parseInt(t / 100);
        // 秒
        let s = t % 60;
        t = parseInt(t / 60);
        // 分钟
        let m = t % 60;
        t = parseInt(t / 60);
        // 小时
        let h = t;

        return `${h.toString().padStart(2, 0)}:${m.toString().padStart(2, 0)}:${s.toString().padStart(2, 0)},${ms.toString().padStart(3, 0)}`;
    }

    function cvt_time_to_ms(t) {
        // 转换标准时间格式为毫秒数
        // 支持如下格式:
        // 4:11:40 or 4:11:40,560 or 11:11 or 11:11,700 or 12,560 or 4 (只输入一个数字默认为秒)
        let ms = 0;
        let i; // 计算到了第几位

        if (t.indexOf(',') != -1) {
            let t_and_ms = t.split(",");
            t = t_and_ms[0];
            ms = parseInt(t_and_ms[1]);
        }
        for (i = 0; (i <= 2 && t.indexOf(':') != -1); i++) {
            let t2_list = t.split(":");
            ms += parseInt(t2_list.pop()) * (60 ** i) * 1000;
            t = t2_list.join(':');
        }
        ms += parseInt(t) * (60 ** i) * 1000;
        return ms;
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

    ListModel {
        id: list_data
        onCountChanged: {
            while (true) {
                if (sort_data())
                    break;
            }
            sync_subtitles_file();
            if (count > 0) {
                videoPlay.video_provider.init_filters(`subtitles=${root.subtitles_file_path.replace(":", "\\\\:")}`);
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
                            root.already_use_start_times.remove(delegate_root.start_time);
                            root.already_use_end_times.remove(delegate_root.end_time);
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
                    placeholder: "00:00:00,000"
                    text: root.default_start_time
                }
                Com.LabelInput2 {
                    id: input_end
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    label: qsTr("结束时间")
                    placeholder: root.get_end_subtitles_time()
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
                    } else if (input_start.text == input_end.text && input_start.text != root.need_most_value_char) {
                        msg.text = qsTr("字幕的开始时间与结束时间不能相同!");
                        msg.open();
                    } else if (input_subtitles.text == "") {
                        msg.text = qsTr("添加的字幕不应为空!");
                        msg.open();
                    } else {
                        let start_time = input_start.text;
                        let end_time = input_end.text;

                        if (start_time === root.need_most_value_char)
                            start_time = input_start.placeholder;
                        if (end_time === root.need_most_value_char)
                            end_time = input_end.placeholder;

                        list_data.append({
                            "start_time": start_time,
                            "end_time": end_time,
                            "subtitles": input_subtitles.text
                        });

                        root.already_use_start_times.push(start_time);
                        root.already_use_end_times.push(end_time);

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
            // cmd.exec_ffmpeg(root.subtitles_file_path);
            cmd.clean_tmp_file("subtitles.srt", 10);
            cmd.exec_ffmpeg();
        }
    }

    Com.MsgDialog {
        id: msg
    }

    Ffmpeg_cmd {
        id: cmd
    }
}
