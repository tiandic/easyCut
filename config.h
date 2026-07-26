#ifndef CONFIG_H
#define CONFIG_H

#include "qcoreapplication.h"
#include "qdir.h"
#include "qfiledevice.h"
#include "qhashfunctions.h"
#include "qstandardpaths.h"
class Config_file_ffmpeg_cmd {
public:
  Config_file_ffmpeg_cmd(QString config_path = "") {
    m_config_path = config_path;
    init(m_config_path, true);
  }

  void push_ffmpeg_cmd(QString cmd) {
    sync_from_file();
    qDebug() << "push cmd:" << cmd;
    __push_ffmpeg_cmd(cmd);
    save_ffmpeg_cmd();
  }

  QString get_config_path() {
    return QDir(get_config_dir()).filePath("ffmpeg_cmd_list.txt");
  }

  QString pop_ffmpeg_cmd() {
    sync_from_file();
    if (!command_list.isEmpty())
      return command_list.takeFirst();
    return "";
  }

  ~Config_file_ffmpeg_cmd() { uninit(); }

private:
  QList<QString> command_list;
  QFile *file;
  QString m_config_path;

  void save_ffmpeg_cmd() {
    file->resize(0);
    file->seek(0);

    QTextStream out(file);
    for (const QString &item : command_list) {
      out << item << '\n';
    }
    file->close();
    file->open(QIODevice::ReadWrite | QIODevice::Text);
  }

  void init(QString config_path = "", bool is_print = false) {
    if (config_path == "")
      file = new QFile(get_config_path());
    else
      file = new QFile(config_path);

    file->open(QIODevice::ReadWrite | QIODevice::Text);

    QTextStream in(file);
    while (!in.atEnd()) {
      QString line = in.readLine();
      if (is_print)
        qDebug() << "found command:" << line;
      __push_ffmpeg_cmd(line);
    }
  }

  void uninit() {
    delete file;
    command_list = {};
  }

  void sync_from_file() {
    // 在任何与 command_list 相关的操作前都会调用它
    uninit();
    init(m_config_path);
  }

  void __push_ffmpeg_cmd(QString cmd) { command_list.prepend(cmd); }

  QString get_config_dir() {
    QString dir =
        QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(dir);
    return dir;
  }
};

#endif // CONFIG_H
