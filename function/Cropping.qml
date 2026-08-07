import QtQuick 2.15
import QtQuick.Layouts 1.15

import "../common" as Com

Item {
    id: root
    property string video_path: ""
    property var stackView

    // 当输入为 need_most_value_char 时, 指定输入框应该被替换为最值, 最值由输入框的 placeholder 属性决定
    property string need_most_value_char: '-'

    function check_input(text) {
        let l;
        if (text == "")
            return qsTr("输入不可为空!");
        else if (!(l = check_limit(text, "1234567890" + need_most_value_char))[0])
            return qsTr(`输入不应包含字符 '${l[1]}'`);
        else if (text.indexOf(need_most_value_char) != -1 && text.length != 1)
            return qsTr(`如果希望选取最值, 请只填写 '${need_most_value_char}' 字符, 否则需要去掉 '${need_most_value_char}'`);
        return "";
    }

    function check_limit(text, limit_chars) {
        for (let i = 0; i < text.length; i++) {
            if (limit_chars.indexOf(text[i]) == -1)
                return [false, text[i]];
        }
        return [true, ""];
    }

    function set_text_and_open_msgbox(text) {
        msg.text = text;
        msg.open();
    }

    function check_input_and_open_msgbox(text) {
        // 无问题返回 true
        // 有问题返回 false
        let m;
        if ((m = root.check_input(text)) != "")
            set_text_and_open_msgbox(m);
        return m == "" ? true : false;
    }

    function cvt_rect_to_input_with_w(num) {
        return Math.round(num * videoPlay.video_width / rect.width);
    }

    function cvt_input_to_rect_with_w(num) {
        return Math.round(num * rect.width / videoPlay.video_width);
    }

    function cvt_rect_to_input_with_h(num) {
        return Math.round(num * videoPlay.video_height / rect.height);
    }

    function cvt_input_to_rect_with_h(num) {
        return Math.round(num * rect.height / videoPlay.video_height);
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

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Com.LabelInput2 {
                id: input_x
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                label: "x"
                placeholder: "0"

                onTextChanged: Qt.callLater(function () {
                    if (!input_x.hasFocus)
                        return;
                    if (input_x.text == "")
                        return;
                    console.debug("change rect x:", input_x.text);
                    if (input_x.text === root.need_most_value_char)
                        rect.rect_X = root.cvt_input_to_rect_with_w(input_x.placeholder);
                    else if (root.cvt_input_to_rect_with_w(parseInt(input_x.text)) !== rect.rect_X)
                        rect.rect_X = root.cvt_input_to_rect_with_w(parseInt(input_x.text));
                })
            }
            Com.LabelInput2 {
                id: input_y
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                label: "y"
                placeholder: "0"

                onTextChanged: Qt.callLater(function () {
                    if (!input_y.hasFocus)
                        return;
                    if (input_y.text == "")
                        return;
                    console.debug("change rect y:", input_y.text);
                    if (input_y.text === root.need_most_value_char)
                        rect.rect_Y = root.cvt_input_to_rect_with_h(input_y.placeholder);
                    else if (root.cvt_input_to_rect_with_h(parseInt(input_y.text)) !== rect.rect_Y)
                        rect.rect_Y = root.cvt_input_to_rect_with_h(parseInt(input_y.text));
                })
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Com.LabelInput2 {
                id: input_w
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                label: qsTr("宽")
                placeholder: videoPlay.video_width

                onTextChanged: Qt.callLater(function () {
                    if (!input_w.hasFocus)
                        return;
                    if (input_w.text == "")
                        return;
                    console.debug("change rect width:", input_w.text);
                    if (input_w.text === root.need_most_value_char)
                        rect.rect_X1 = root.cvt_input_to_rect_with_w(input_w.placeholder);
                    else if (root.cvt_input_to_rect_with_w(parseInt(input_w.text)) !== rect.rect_X1 - rect.rect_X)
                        rect.rect_X1 = root.cvt_input_to_rect_with_w(rect.rect_X + parseInt(input_w.text));
                })
            }
            Com.LabelInput2 {
                id: input_h
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                label: qsTr("高")
                placeholder: videoPlay.video_height

                onTextChanged: Qt.callLater(function () {
                    if (!input_h.hasFocus)
                        return;
                    if (input_w.text == "")
                        return;
                    console.debug("change rect height:", input_h.text);
                    if (input_h.text === root.need_most_value_char)
                        rect.rect_Y1 = root.cvt_input_to_rect_with_h(input_h.placeholder);
                    else if (root.cvt_input_to_rect_with_h(parseInt(input_h.text)) !== rect.rect_Y1 - rect.rect_Y)
                        rect.rect_Y1 = root.cvt_input_to_rect_with_h(rect.rect_Y + parseInt(input_h.text));
                })
            }
        }

        Com.Button {
            Layout.fillWidth: true
            text_: qsTr("确认")
            onClicked: {
                if (!root.check_input_and_open_msgbox(input_x.text) || !root.check_input_and_open_msgbox(input_y.text) || !root.check_input_and_open_msgbox(input_w.text) || !root.check_input_and_open_msgbox(input_h.text))
                    return;
                else if (parseInt(input_x.text) > videoPlay.video_width)
                    root.set_text_and_open_msgbox(qsTr(`矩形 x 坐标过大! 视频宽度为: ${videoPlay.video_width}`));
                else if (parseInt(input_y.text) > videoPlay.video_height)
                    root.set_text_and_open_msgbox(qsTr(`矩形 y 坐标过大! 视频高度为: ${videoPlay.video_height}`));
                else if (parseInt(input_h.text) > videoPlay.video_height)
                    root.set_text_and_open_msgbox(qsTr(`矩形过高! 视频高度为: ${videoPlay.video_height}`));
                else if (parseInt(input_w.text) > videoPlay.video_width)
                    root.set_text_and_open_msgbox(qsTr(`矩形过宽! 视频宽度为: ${videoPlay.video_width}`));
                else
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

        video_path: video_path
        Com.Myrect {
            id: rect

            function updateRect() {
                var mapped = videoPlay.videooutput.mapToItem(videoPlay, videoPlay.videooutput.contentRect.x, videoPlay.videooutput.contentRect.y, videoPlay.videooutput.contentRect.width, videoPlay.videooutput.contentRect.height);

                console.log("contentRect:", videoPlay.videooutput.contentRect.x, videoPlay.videooutput.contentRect.y, videoPlay.videooutput.contentRect.width, videoPlay.videooutput.contentRect.height);
                console.log("mapped:", mapped.x, mapped.y, mapped.width, mapped.height);

                rect_X = 10;
                rect_Y = 10;
                rect_X1 = mapped.width - 10;
                rect_Y1 = mapped.height - 10;

                x = mapped.x;
                y = mapped.y;
                width = mapped.width;
                height = mapped.height;

                // 初始化输入框的数据
                input_x.text = root.cvt_rect_to_input_with_w(rect.rect_X);
                input_y.text = root.cvt_rect_to_input_with_h(rect.rect_Y);
                input_w.text = root.cvt_rect_to_input_with_w(rect.rect_X1 - rect.rect_X);
                input_h.text = root.cvt_rect_to_input_with_h(rect.rect_Y1 - rect.rect_Y);
            }

            Connections {
                target: videoPlay.videooutput
                function onContentRectChanged() {
                    rect.updateRect();
                }
            }
            onClickOutlined: {
                videoPlay.need_toggle_play_status = true;
            }

            onMouse_pressedChanged: {
                if (mouse_pressed)
                    focus_stealer.focus = true;
            }

            // 避免选框超出边界
            onRect_XChanged: {
                if (rect_X < 0)
                    rect_X = 0;
            }
            onRect_YChanged: {
                if (rect_Y < 0)
                    rect_Y = 0;
            }
            onRect_X1Changed: {
                if (rect_X1 > width)
                    rect_X1 = width;
            }
            onRect_Y1Changed: {
                if (rect_Y1 > height)
                    rect_Y1 = height;
            }
        }
    }

    Com.SavePathSelect {
        id: save_path_select
        input_video_path: videoPlay.video_path
        onSelected: function (in_path, out_path) {
            let file_path = cmd.cvt_file_url_to_local(videoPlay.video_path);
            let w = input_w.text;
            let h = input_h.text;
            let x = input_x.text;
            let y = input_y.text;

            if (w == root.need_most_value_char) {
                if (x == root.need_most_value_char)
                    w = input_w.placeholder - input_x.placeholder;
                else
                    w = input_w.placeholder - parseInt(input_x.text);
            }
            if (h == root.need_most_value_char) {
                if (y == root.need_most_value_char)
                    h = input_h.placeholder - input_y.placeholder;
                else
                    h = input_h.placeholder - parseInt(input_y.text);
            }
            if (x == root.need_most_value_char)
                x = input_x.placeholder;
            if (y == root.need_most_value_char)
                y = input_y.placeholder;

            let crop_str = `${w}:${h}:${x}:${y}`;

            let copy_audio_codec = "";
            if (cmd.can_copy(in_path, cmd.get_extension(out_path), "audio"))
                copy_audio_codec = "-c:a copy";

            cmd.push_ffmpeg_cmd(`ffmpeg -y -i "${in_path}" -vf "crop=${crop_str}" ${copy_audio_codec} "${out_path}"`);
            cmd.exec_ffmpeg();
        }
    }

    Timer {
        interval: 100
        repeat: true
        running: true

        onTriggered: {
            if (!input_x.hasFocus && parseInt(input_x.text) != rect.rect_X && rect.mouse_pressed && input_x.text != root.need_most_value_char)
                input_x.text = root.cvt_rect_to_input_with_w(rect.rect_X);
            if (!input_y.hasFocus && parseInt(input_y.text) != rect.rect_Y && rect.mouse_pressed && input_y.text != root.need_most_value_char)
                input_y.text = root.cvt_rect_to_input_with_h(rect.rect_Y);
            if (!input_w.hasFocus && parseInt(input_w.text) != rect.rect_X1 - rect.rect_X && rect.mouse_pressed && input_w.text != root.need_most_value_char)
                input_w.text = root.cvt_rect_to_input_with_w(rect.rect_X1 - rect.rect_X);
            if (!input_h.hasFocus && parseInt(input_h.text) != rect.rect_Y1 - rect.rect_Y && rect.mouse_pressed && input_h.text != root.need_most_value_char)
                input_h.text = root.cvt_rect_to_input_with_h(rect.rect_Y1 - rect.rect_Y);
        }
    }

    onVideo_pathChanged: videoPlay.video_path = video_path

    Com.MsgDialog {
        id: msg
    }

    Item {
        id: focus_stealer
        // 用于取消输入框的焦点
        // 当使用鼠标与矩形交互时,输入框如果有焦点,则具有焦点的输入框将无法通过矩形更新实际值
        focus: true
    }

    Ffmpeg_cmd {
        id: cmd
    }
}
