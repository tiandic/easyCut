import QtQuick 2.15
import QtCore
import QtQuick.Dialogs
import QtMultimedia
import "../common" as Com

Rectangle {
    id: welcome
    property var stackView

    FileDialog {
        id: file_select
        title: qsTr("选择一个视频文件")
        currentFolder: StandardPaths.standardLocations(StandardPaths.MoviesLocation)[0]
        nameFilters: [
            qsTr("视频文件 (*.mp4 *.m4v *.mkv *.avi *.mov *.qt *.flv *.webm *.mpg *.mpeg *.m2v *.m1v *.mpv *.ts *.mts *.m2ts *.vob *.ogv *.3gp *.3g2 *.str *.4xm *.a64 *.amv *.dv *.yuv *.h264 *.264 *.hevc *.h265 *.vp8 *.vp9 *.prores *.mxf *.cineform *.huff *.ffv1 *.snow *.vp6 *.ogv)"),
            qsTr("所有文件 (*)")
        ]
        onAccepted: {
            var comp=Qt.createComponent("Function.qml")
            if (comp.status==Component.Ready){
                var obj = comp.createObject(welcome.parent,{
                                      video_path: file_select.selectedFile,
                                      "stackView": welcome.stackView
                                  })
                if (obj==null)
                {
                    console.log("create failed!")
                    return
                }

                stackView.push(obj)

            }
            else if (comp.status==Component.Error)
                console.log(comp. errorString())
            console.log(file_select.selectedFile)
        }
    }

    Com.Button {
        text_: qsTr("选择一个视频文件")
        width: parent.width / 3
        height: parent.height / 6.9
        anchors.centerIn: parent
        onClicked: file_select.open()
    }

}
