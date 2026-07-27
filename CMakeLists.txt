cmake_minimum_required(VERSION 3.16)

project(easyCut VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(QT_QML_GENERATE_QMLLS_INI ON)

find_package(Qt6 REQUIRED COMPONENTS Quick)
find_package(Qt6 REQUIRED COMPONENTS Multimedia)
find_package(PkgConfig REQUIRED)

pkg_check_modules(FFMPEG
    REQUIRED
    IMPORTED_TARGET
    libavformat
    libavcodec
    libswscale
    libavutil
    libswresample
    libavfilter
)

qt_standard_project_setup(REQUIRES 6.10)

qt_add_executable(appeasyCut
    main.cpp
)

qt_add_qml_module(appeasyCut
    URI easyCut
    QML_FILES
        Main.qml
        QML_FILES page/Welcome.qml
        QML_FILES common/Button.qml
        QML_FILES page/Function.qml
        QML_FILES common/VideoPlay.qml
        QML_FILES common/Myrect.qml
        QML_FILES common/LabelInput.qml
        QML_FILES common/LabelInput2.qml
        QML_FILES function/Cropping.qml
        SOURCES VideoProvider.h Ffmpeg_cmd.h
        SOURCES config.h
        QML_FILES function/TimeCrop.qml
        QML_FILES common/SavePathSelect.qml
        QML_FILES function/splicing.qml
        QML_FILES function/ExtractAudio.qml
        QML_FILES function/AddAudio.qml
        QML_FILES function/ExtractAllFrames.qml
        QML_FILES function/AddSubtitles.qml
        QML_FILES common/MsgDialog.qml
)

# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
set_target_properties(appeasyCut PROPERTIES
#    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.appeasyCut
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appeasyCut
    PRIVATE Qt6::Quick
)

target_link_libraries(appeasyCut PRIVATE Qt6::Multimedia)

target_link_libraries(appeasyCut
    PRIVATE
    PkgConfig::FFMPEG
)

add_subdirectory(exec_cmd)
add_subdirectory(exec_cmd_gui)

install(TARGETS appeasyCut
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
install(TARGETS exec_cmd
    RUNTIME DESTINATION ${CMAKE_INSTALL_LIBDIR}/easyCut
)
install(TARGETS appexec_cmd_gui
    RUNTIME DESTINATION ${CMAKE_INSTALL_LIBDIR}/easyCut
)
