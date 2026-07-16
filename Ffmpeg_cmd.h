#pragma once

#include "qcoreapplication.h"
#include "qdebug.h"
#include "qdir.h"
#include "qlist.h"
#include "qprocess.h"
#include "qtmetamacros.h"
#include <QCoreApplication>
#include <QDir>
#include <QObject>
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
    QString exec_path = QDir(QCoreApplication::applicationDirPath())
                            .filePath("exec_cmd/exec_cmd");
    QList<QString> argv = {config.get_config_path()};
    QProcess::startDetached(exec_path, argv);
  }

private:
  Config_file config;
};
