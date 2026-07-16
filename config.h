#ifndef CONFIG_H
#define CONFIG_H

#include "qcoreapplication.h"
#include "qdir.h"
#include "qfiledevice.h"
class Config_file {
public:
  Config_file(QString config_path = "") {
    if (config_path == "")
      file = new QFile(get_config_path());
    else
      file = new QFile(config_path);

    file->open(QIODevice::ReadWrite | QIODevice::Text);

    QTextStream in(file);
    while (!in.atEnd()) {
      QString line = in.readLine();
      qDebug() << "found command:" << line;
      push_ffmpeg_cmd(line);
    }
  }

  void push_ffmpeg_cmd(QString cmd) { command_list.prepend(cmd); }

  QString get_config_path() {
    return QDir(get_config_dir()).filePath("ffmpeg_cmd_list.txt");
  }

  QString pop_ffmpeg_cmd() {
    if (!command_list.isEmpty())
      return command_list.takeFirst();
    return "";
  }

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

private:
  QList<QString> command_list;
  QFile *file;

  QString get_config_dir() { return QCoreApplication::applicationDirPath(); }
};

#endif // CONFIG_H
