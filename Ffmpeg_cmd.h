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
#include <ctime>

#include "config.h"
#include "qurl.h"

class Ffmpeg_cmd : public QObject {
  Q_OBJECT
  QML_ELEMENT

public:
  explicit Ffmpeg_cmd(QObject *parent = nullptr) : QObject(parent) {}

  Q_INVOKABLE void push_ffmpeg_cmd(QString cmd) { config.push_ffmpeg_cmd(cmd); }
  Q_INVOKABLE QString pop_ffmpeg_cmd() { return config.pop_ffmpeg_cmd(); }

  Q_INVOKABLE QString cvt_file_url_to_local(QUrl url) {
    return url.toLocalFile();
  }

  Q_INVOKABLE QString echo_tmp_file(QString file_name, QString text,
                                    bool durability = false) {
    // 创建一个临时文件,将输入参数的内容写进该文件
    // ret:
    //      file_path: 临时文件的路径
    QString tempPath;
    QString tempFileName =
        QString::number(QDateTime::currentMSecsSinceEpoch()) + "_" + file_name;
    if (durability)
      tempPath = QDir(get_durability_tmp_dir()).filePath(tempFileName);
    else
      tempPath = QDir(QDir::tempPath()).filePath(tempFileName);

    QFile file(tempPath);
    if (file.open(QIODevice::WriteOnly | QIODevice::Text)) {
      QTextStream out(&file);
      out.setEncoding(QStringConverter::Utf8);
      out << text;
      file.close();
      tmp_files.append(tempPath);
      return tempPath;
    }
    return QString();
  }

  Q_INVOKABLE void rm_tmp_file(QString path) {
    // 删除临时文件,根据路径删除
    // 只有通过 echo_tmp_file() 创建的文件才能通过该函数删除
    if (!tmp_files.contains(path))
      return;
    tmp_files.removeAll(path);
    QFile::remove(path);
  }

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
  QList<QString> tmp_files;
  QList<QString> exec_paths = {"exec_cmd", "exec_cmd.exe", "exec_cmd/exec_cmd",
                               "exec_cmd/exec_cmd.exe"};
  QList<QString> exec_gui_paths = {"appexec_cmd_gui", "appexec_cmd_gui.exe",
                                   "exec_cmd_gui/appexec_cmd_gui",
                                   "exec_cmd_gui/appexec_cmd_gui.exe"};

  QString find_exists_from_paths(QList<QString> paths) {
    QString path;
    for (QString n : paths) {
      // 构建后
      path = QDir(QCoreApplication::applicationDirPath()).filePath(n);
      QFileInfo file(path);
      if (file.exists() && file.isFile())
        return path;

      // 安装后
      path = QDir(QCoreApplication::applicationDirPath())
                 .filePath("../lib/easyCut/" + n);
      QFileInfo file2(path);
      if (file2.exists() && file2.isFile())
        return path;
    }

    return "";
  }

  QString get_exec_path() { return find_exists_from_paths(exec_paths); }

  QString get_exec_gui_path() { return find_exists_from_paths(exec_gui_paths); }

  QString get_durability_tmp_dir() {
    QString dir =
        QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(dir);
    return dir;
  }
};
