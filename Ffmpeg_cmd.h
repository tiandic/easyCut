#pragma once

#include "qcoreapplication.h"
#include "qdebug.h"
#include "qdir.h"
#include "qfileinfo.h"
#include "qlist.h"
#include "qlogging.h"
#include "qprocess.h"
#include "qtmetamacros.h"
#include <QCoreApplication>
#include <QDir>
#include <QObject>
#include <QStandardPaths>
#include <QtQml>

#include "config.h"

class Ffmpeg_cmd : public QObject {
  Q_OBJECT
  QML_ELEMENT

public:
  explicit Ffmpeg_cmd(QObject *parent = nullptr) : QObject(parent) {}

  Q_INVOKABLE void push_ffmpeg_cmd(QString cmd) { config.push_ffmpeg_cmd(cmd); }
  Q_INVOKABLE QString pop_ffmpeg_cmd() { return config.pop_ffmpeg_cmd(); }

  Q_INVOKABLE void save_ffmpeg_cmd() { config.save_ffmpeg_cmd(); }

  Q_INVOKABLE void exec_ffmpeg() {
    QString exec_path = get_exec_path();
    QString exec_gui_path = get_exec_gui_path();
    QList<QString> argv = {exec_path, config.get_config_path()};

    if (exec_path == "")
      qCritical() << "Couldn’t find executable file exec_cmd.";
    if (exec_gui_path == "")
      qCritical() << "Couldn’t find executable file exec_cmd_gui.";

    QProcess::startDetached(exec_gui_path, argv);
  }

private:
  Config_file_ffmpeg_cmd config;
  QList<QString> exec_paths = {"exec_cmd", "exec_cmd.exe", "exec_cmd/exec_cmd",
                               "exec_cmd/exec_cmd.exe"};
  QList<QString> exec_gui_paths = {"appexec_cmd_gui", "appexec_cmd_gui.exe",
                                   "exec_cmd_gui/appexec_cmd_gui",
                                   "exec_cmd_gui/appexec_cmd_gui.exe"};

  QString find_exists_from_paths(QList<QString> paths) {
    QString path;
    for (QString n : paths) {
      path = QDir(QCoreApplication::applicationDirPath()).filePath(n);
      QFileInfo file(path);
      if (file.exists() && file.isFile())
        return path;
    }

    return "";
  }

  QString get_exec_path() { return find_exists_from_paths(exec_paths); }

  QString get_exec_gui_path() { return find_exists_from_paths(exec_gui_paths); }
};
