import QtQuick 2.15
import QtQuick.Dialogs
import QtCore

Item {
    id: root
    property string input_video_path: ""
    property var dialog: save_path_select
    signal selected(string in_path, string out_path)

    function get_extension(filename) {
        if (!filename)
            return '';
        console.debug("get_extension():", filename);
        const idx = filename.lastIndexOf('.');
        if (idx === -1 || idx === 0)
            return '';
        return filename.slice(idx + 1);
    }

    function remove_pre(str, pre) {
        if (str.startsWith(pre)) {
            return str.slice(pre.length);
        }
        return str;
    }

    FileDialog {
        id: save_path_select
        title: qsTr("选择保存位置")
        fileMode: FileDialog.SaveFile
        currentFile: {
            let ext = get_extension(root.input_video_path);
            if (ext !== '')
                return "out." + ext;
            return "out.mp4";
        }
        currentFolder: StandardPaths.standardLocations(StandardPaths.MoviesLocation)[0]
        nameFilters: [qsTr("视频文件 (*.mp4 *.m4v *.mkv *.avi *.mov *.qt *.flv *.webm *.mpg *.mpeg *.m2v *.m1v *.mpv *.ts *.mts *.m2ts *.vob *.ogv *.3gp *.3g2 *.str *.4xm *.a64 *.amv *.dv *.yuv *.h264 *.264 *.hevc *.h265 *.vp8 *.vp9 *.prores *.mxf *.cineform *.huff *.ffv1 *.snow *.vp6 *.ogv)"), qsTr("所有文件 (*)")]

        onAccepted: {
            let file_path = remove_pre(root.input_video_path, "file://");
            let save_path = remove_pre(save_path_select.selectedFile.toString(), "file://");
            if (save_path.indexOf('.') === -1)
                save_path = save_path + '.' + get_extension(file_path);
            console.debug(get_extension(root.input_video_path));
            root.selected(file_path, save_path);
        }
    }
}
