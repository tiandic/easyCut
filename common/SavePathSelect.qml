import QtQuick 2.15
import QtQuick.Dialogs
import QtCore

Item {
    id: root
    property string input_video_path: ""
    property var dialog: save_path_select
    signal selected(string in_path, string out_path)

    FileDialog {
        id: save_path_select
        title: qsTr("选择保存位置")
        fileMode: FileDialog.SaveFile
        currentFile: {
            let ext = cmd.get_extension(root.input_video_path);
            if (ext !== '')
                return "out." + ext;
            return "out.mp4";
        }
        currentFolder: StandardPaths.standardLocations(StandardPaths.MoviesLocation)[0]
        nameFilters: [qsTr("视频文件 (*.mp4 *.m4v *.mkv *.avi *.mov *.qt *.flv *.webm *.mpg *.mpeg *.m2v *.m1v *.mpv *.ts *.mts *.m2ts *.vob *.ogv *.3gp *.3g2 *.str *.4xm *.a64 *.amv *.dv *.yuv *.h264 *.264 *.hevc *.h265 *.vp8 *.vp9 *.prores *.mxf *.cineform *.huff *.ffv1 *.snow *.vp6 *.ogv)"), qsTr("所有文件 (*)")]

        onAccepted: {
            let file_path = cmd.cvt_file_url_to_local(root.input_video_path);
            let save_path = cmd.cvt_file_url_to_local(save_path_select.selectedFile.toString());
            if (save_path.indexOf('.') === -1)
                save_path = save_path + '.' + cmd.get_extension(file_path);
            console.debug(cmd.get_extension(root.input_video_path));
            root.selected(file_path, save_path);
        }
    }

    Ffmpeg_cmd {
        id: cmd
    }
}
