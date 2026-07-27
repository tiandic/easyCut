// VideoProvider.h
#ifndef VIDEOPROVIDER_H
#define VIDEOPROVIDER_H

#include "qhashfunctions.h"
#include "qlogging.h"
#include "qtmetamacros.h"
#include <QImage>
#include <QObject>
#include <QPainter>
#include <QTimer>
#include <QtMultimedia/QAudioSink>
#include <QtMultimedia/QVideoFrame>
#include <QtMultimedia/QVideoSink>
#include <QtQml>

#include <cerrno>
#include <limits>
#include <stdint.h>

extern "C" {
#include <libavcodec/avcodec.h>
#include <libavcodec/codec.h>
#include <libavcodec/codec_par.h>
#include <libavcodec/packet.h>
#include <libavfilter/avfilter.h>
#include <libavfilter/buffersink.h>
#include <libavfilter/buffersrc.h>
#include <libavformat/avformat.h>
#include <libavutil/avutil.h>
#include <libavutil/channel_layout.h>
#include <libavutil/frame.h>
#include <libavutil/mem.h>
#include <libavutil/opt.h>
#include <libavutil/rational.h>
#include <libavutil/samplefmt.h>
#include <libswresample/swresample.h>
#include <libswscale/swscale.h>
}

class Ffmpeg_frame {
public:
  bool has_error = false;
  double fps;
  int width;
  int height;
  AVFormatContext *fmt_ctx = nullptr;
  int video_stream_index;
  int audio_stream_index;
  AVCodecContext *codec_ctx_video;
  AVCodecContext *codec_ctx_audio;
  int sample_rate;
  int nb_channels;
  double progress_time;

  explicit Ffmpeg_frame(QString local_video_path) {
    QByteArray ba = local_video_path.toLocal8Bit();
    const char *c_str2 = ba.data();
    if (avformat_open_input(&fmt_ctx, c_str2, nullptr, nullptr) < 0) {
      qWarning() << "Failed to open the '" << local_video_path << "' file!";
      has_error = true;
      return;
    }
    if (avformat_find_stream_info(fmt_ctx, nullptr) < 0) {
      qWarning() << "Unable to obtain stream information";
      has_error = true;
      return;
    }

    video_stream_index = -1;
    for (uint i = 0; i < fmt_ctx->nb_streams; i++) {
      if (fmt_ctx->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_VIDEO) {
        video_stream_index = i;
        break;
      }
    }

    if (video_stream_index == -1) {
      qWarning() << "No video stream";
      has_error = true;
      return;
    }

    audio_stream_index = -1;
    for (uint i = 0; i < fmt_ctx->nb_streams; i++) {
      if (fmt_ctx->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_AUDIO) {
        audio_stream_index = i;
        break;
      }
    }

    if (audio_stream_index == -1) {
      qWarning() << "No audio stream";
      has_error = true;
      return;
    }

    fps = av_q2d(fmt_ctx->streams[video_stream_index]->avg_frame_rate);
    width = fmt_ctx->streams[video_stream_index]->codecpar->width;
    height = fmt_ctx->streams[video_stream_index]->codecpar->height;

    qDebug() << "video fps:" << fps;
    qDebug() << "video width:" << width;
    qDebug() << "video height:" << height;

    AVCodecParameters *codecpar_video =
        fmt_ctx->streams[video_stream_index]->codecpar;
    AVCodecParameters *codecpar_audio =
        fmt_ctx->streams[audio_stream_index]->codecpar;
    codec_video = avcodec_find_decoder(codecpar_video->codec_id);
    codec_audio = avcodec_find_decoder(codecpar_audio->codec_id);

    if (!codec_video) {
      qWarning() << "video Decoder not found";
      has_error = true;
      return;
    }
    if (!codec_audio) {
      qWarning() << "audio Decoder not found";
      has_error = true;
      return;
    }

    codec_ctx_video = avcodec_alloc_context3(codec_video);
    codec_ctx_audio = avcodec_alloc_context3(codec_audio);
    avcodec_parameters_to_context(codec_ctx_video, codecpar_video);
    avcodec_parameters_to_context(codec_ctx_audio, codecpar_audio);

    if (avcodec_open2(codec_ctx_video, codec_video, nullptr) < 0) {
      qWarning() << "video: Unable to open decoder";
      has_error = true;
      return;
    }
    if (avcodec_open2(codec_ctx_audio, codec_audio, nullptr) < 0) {
      qWarning() << "audio: Unable to open decoder";
      has_error = true;
      return;
    }

    sample_rate = codec_ctx_audio->sample_rate;
    nb_channels = codec_ctx_audio->ch_layout.nb_channels;

    frame_video = av_frame_alloc();
    frame_audio = av_frame_alloc();
  }

  AVPacket *demux() {
    AVPacket *pkt = av_packet_alloc();

    if (av_read_frame(fmt_ctx, pkt) < 0) {
      av_packet_free(&pkt);
      return nullptr;
    }

    QMutexLocker locker(&queue_mutex);
    if (pkt->stream_index == video_stream_index)
      video_packets_queue.enqueue(pkt);
    else if (pkt->stream_index == audio_stream_index)
      audio_packets_queue.enqueue(pkt);
    else
      av_packet_free(&pkt);

    return pkt;
  }

  AVFrame *get_a_frame_video() {
    AVPacket *pack;
    AVFrame *buffersink_frame;

    if (filter_graph != nullptr &&
        (buffersink_frame = get_a_frame_from_buffersink()) != nullptr)
      return buffersink_frame;

    while (avcodec_receive_frame(codec_ctx_video, frame_video) != 0) {
      while (video_packets_queue.isEmpty()) {
        if (demux() == nullptr)
          return nullptr;
      }

      pack = video_packets_queue.dequeue();

      if (pack->data == NULL || pack->size <= 0) {
        qDebug() << "apck error in pts: " << pack->pts;
      }

      avcodec_send_packet(codec_ctx_video, pack);
      av_packet_free(&pack);
    }

    progress_time = av_rescale_q(
        frame_video->best_effort_timestamp,
        fmt_ctx->streams[video_stream_index]->time_base, (AVRational){1, 100});

    // dumpAVFrame(frame_video);
    if (filter_graph != nullptr) {
      int ret = av_buffersrc_add_frame_flags(buffersrc_ctx, frame_video,
                                             AV_BUFFERSRC_FLAG_KEEP_REF);
      if (ret < 0) {
        return nullptr;
      }
      AVFrame *tmp_frame = get_a_frame_from_buffersink();
      av_frame_unref(frame_video);
      return tmp_frame;
    }

    return frame_video;
  }

  AVFrame *get_a_frame_audio() {
    AVPacket *pack;
    while (avcodec_receive_frame(codec_ctx_audio, frame_audio) != 0) {

      while (audio_packets_queue.isEmpty()) {
        if (demux() == nullptr)
          return nullptr;
      }

      pack = audio_packets_queue.dequeue();
      avcodec_send_packet(codec_ctx_audio, pack);

      av_packet_free(&pack);
    }

    return frame_audio;
  }

  void seek(int64_t target_time) {

    qDebug() << "video seek:  " << target_time / 100 << "s ; "
             << "total time: " << get_total_time() / 100 << 's';

    bool is_tail = target_time / 100 == get_total_time() / 100;
    qDebug() << "is tail: " << is_tail;
    AVPacket *pack;

    while (!video_packets_queue.isEmpty()) {
      pack = video_packets_queue.dequeue();
      av_packet_free(&pack);
    }

    int64_t ts =
        av_rescale_q(target_time, (AVRational){1, 100}, AV_TIME_BASE_Q);
    avformat_seek_file(fmt_ctx, -1, INT64_MIN, ts, ts, 0);

    avcodec_flush_buffers(codec_ctx_video);
    avcodec_flush_buffers(codec_ctx_audio);

    double frame_interval = 1 / fps;
    double avbase_time =
        av_q2d(fmt_ctx->streams[video_stream_index]->time_base);
    AVFrame *fr;

    int64_t now_frame_time = -1;

    while ((fr = get_a_frame_video()) != nullptr) {
      int64_t now_frame_time = (fr->pts * avbase_time + frame_interval) * 100;
      if (now_frame_time >= target_time)
        break;
      av_frame_unref(fr);
    }
    if (fr != nullptr)
      av_frame_unref(fr);

    while (!audio_packets_queue.isEmpty()) {
      pack = audio_packets_queue.dequeue();
      av_packet_free(&pack);
    }
  }

  int64_t get_total_time() {
    // 返回的数量单位为 秒*100
    if (fmt_ctx->duration == AV_NOPTS_VALUE)
      return 0;

    return av_rescale_q(fmt_ctx->duration, AV_TIME_BASE_Q,
                        (AVRational){1, 100});
  }

  QImage cvtQImageFromFrame(const AVFrame *pFrame) const {
    // first convert the input AVFrame to the desired format

    SwsContext *img_convert_ctx = sws_getContext(
        pFrame->width, pFrame->height, (AVPixelFormat)pFrame->format,
        pFrame->width, pFrame->height, AV_PIX_FMT_RGB24, SWS_BICUBIC, NULL,
        NULL, NULL);
    if (!img_convert_ctx) {
      qDebug() << "Failed to create sws context";
      return QImage();
    }

    // prepare line sizes structure as sws_scale expects
    int rgb_linesizes[8] = {0};
    rgb_linesizes[0] = 3 * pFrame->width;

    // prepare char buffer in array, as sws_scale expects
    unsigned char *rgbData[8];
    int imgBytesSyze = 3 * pFrame->height * pFrame->width;
    // as explained above, we need to alloc extra 64 bytes
    rgbData[0] = (unsigned char *)malloc(imgBytesSyze + 64);
    if (!rgbData[0]) {
      qDebug() << "Error allocating buffer for frame conversion";
      free(rgbData[0]);
      sws_freeContext(img_convert_ctx);
      return QImage();
    }
    if (sws_scale(img_convert_ctx, pFrame->data, pFrame->linesize, 0,
                  pFrame->height, rgbData, rgb_linesizes) != pFrame->height) {
      qDebug() << "Error changing frame color range";
      free(rgbData[0]);
      sws_freeContext(img_convert_ctx);
      return QImage();
    }

    // then create QImage and copy converted frame data into it

    QImage image(pFrame->width, pFrame->height, QImage::Format_RGB888);

    for (int y = 0; y < pFrame->height; y++) {
      memcpy(image.scanLine(y), rgbData[0] + y * 3 * pFrame->width,
             3 * pFrame->width);
    }

    free(rgbData[0]);
    sws_freeContext(img_convert_ctx);
    return image;
  }

  int init_filters(const char *filters_descr) {
    if (filter_graph != nullptr)
      uninit_filters();

    int ret = 0;

    filter_graph = avfilter_graph_alloc();
    AVFilterInOut *outputs = avfilter_inout_alloc();
    AVFilterInOut *inputs = avfilter_inout_alloc();
    const AVFilter *buffersrc = avfilter_get_by_name("buffer");
    const AVFilter *buffersink = avfilter_get_by_name("buffersink");

    AVRational time_base = fmt_ctx->streams[video_stream_index]->time_base;

    QString args =
        QString(
            "video_size=%1x%2:pix_fmt=%3:time_base=%4/%5:pixel_aspect=%6/%7")
            .arg(codec_ctx_video->width)
            .arg(codec_ctx_video->height)
            .arg(codec_ctx_video->pix_fmt)
            .arg(time_base.num)
            .arg(time_base.den)
            .arg(codec_ctx_video->sample_aspect_ratio.num)
            .arg(codec_ctx_video->sample_aspect_ratio.den);

    avfilter_graph_create_filter(&buffersrc_ctx, buffersrc, "in",
                                 args.toStdString().c_str(), NULL,
                                 filter_graph);
    avfilter_graph_create_filter(&buffersink_ctx, buffersink, "out", NULL, NULL,
                                 filter_graph);
    outputs->name = av_strdup("in");
    outputs->filter_ctx = buffersrc_ctx;
    outputs->pad_idx = 0;
    outputs->next = NULL;
    inputs->name = av_strdup("out");
    inputs->filter_ctx = buffersink_ctx;
    inputs->pad_idx = 0;
    inputs->next = NULL;

    if ((ret = avfilter_graph_parse_ptr(filter_graph, filters_descr, &inputs,
                                        &outputs, NULL)) < 0) {
      avfilter_inout_free(&inputs);
      avfilter_inout_free(&outputs);
      return ret;
    }
    if ((ret = avfilter_graph_config(filter_graph, NULL)) < 0) {
      avfilter_inout_free(&inputs);
      avfilter_inout_free(&outputs);
      return ret;
    }

    return ret;
  }

  void uninit_filters() {
    avfilter_graph_free(&filter_graph);
    filter_graph = nullptr;
    buffersrc_ctx = nullptr;
    buffersink_ctx = nullptr;
  }

  ~Ffmpeg_frame() {
    avcodec_send_packet(codec_ctx_video, nullptr);
    avcodec_receive_frame(codec_ctx_video, frame_video);
    avcodec_send_packet(codec_ctx_audio, nullptr);
    avcodec_receive_frame(codec_ctx_audio, frame_audio);

    av_frame_free(&frame_video);
    avcodec_free_context(&codec_ctx_video);
    av_frame_free(&frame_audio);
    avcodec_free_context(&codec_ctx_audio);

    avformat_close_input(&fmt_ctx);
  }

private:
  const AVCodec *codec_video;
  const AVCodec *codec_audio;
  AVFrame *frame_video;
  AVFrame *frame_audio;
  uint64_t current_play_time;
  QQueue<AVPacket *> video_packets_queue;
  QQueue<AVPacket *> audio_packets_queue;
  QMutex queue_mutex;

  AVFilterGraph *filter_graph = nullptr;
  AVFilterContext *buffersrc_ctx = nullptr;
  AVFilterContext *buffersink_ctx = nullptr;

  AVFrame *get_a_frame_from_buffersink() {
    AVFrame *ret_frame = av_frame_alloc();
    int ret = av_buffersink_get_frame(buffersink_ctx, ret_frame);
    if (ret == AVERROR(EAGAIN) || ret == AVERROR_EOF)
      return nullptr;
    return ret_frame;
  }

  void dumpAVFrame(AVFrame *frame) {
    if (!frame) {
      qDebug() << "AVFrame is null";
      return;
    }

    qDebug() << "===== AVFrame Info =====";

    // 基本信息
    qDebug() << "pts:" << frame->pts;
    qDebug() << "pkt_dts:" << frame->pkt_dts;
    qDebug() << "best_effort_timestamp:" << frame->best_effort_timestamp;
    qDebug() << "time_base:" << av_q2d(frame->time_base);

    // 尺寸 & 格式
    qDebug() << "width:" << frame->width;
    qDebug() << "height:" << frame->height;
    qDebug() << "format:" << frame->format;

    // 关键帧
    // qDebug() << "key_frame:" << frame->key_frame;
    qDebug() << "pict_type:" << av_get_picture_type_char(frame->pict_type);

    // 行大小（stride）
    qDebug() << "linesize:";
    for (int i = 0; i < AV_NUM_DATA_POINTERS; ++i) {
      if (frame->linesize[i] > 0)
        qDebug() << "  [" << i << "] =" << frame->linesize[i];
    }

    // 数据指针
    qDebug() << "data pointers:";
    for (int i = 0; i < AV_NUM_DATA_POINTERS; ++i) {
      if (frame->data[i])
        qDebug() << "  [" << i << "] =" << frame->data[i];
    }

    // 色彩信息
    qDebug() << "color_range:" << frame->color_range;
    qDebug() << "color_primaries:" << frame->color_primaries;
    qDebug() << "color_trc:" << frame->color_trc;
    qDebug() << "colorspace:" << frame->colorspace;

    // 其他
    qDebug() << "sample_aspect_ratio:" << frame->sample_aspect_ratio.num << "/"
             << frame->sample_aspect_ratio.den;

    qDebug() << "nb_samples (audio):" << frame->nb_samples;
    qDebug() << "channels:" << frame->ch_layout.nb_channels;

    qDebug() << "========================";
  }
};

class AudioWave : public QIODevice {
public:
  qint64 pos;
  explicit AudioWave(Ffmpeg_frame *ff, qint64 *audio_pts,
                     QObject *parent = nullptr)
      : QIODevice(parent), m_ff(ff), m_audio_pts(audio_pts), pos(0) {
    buf.resize(buf_size);
    // 输入参数
    const AVChannelLayout *in_chlayout = &m_ff->codec_ctx_audio->ch_layout;
    AVSampleFormat in_fmt = m_ff->codec_ctx_audio->sample_fmt;
    int in_rate = m_ff->codec_ctx_audio->sample_rate;

    // 输出参数
    AVChannelLayout out_chlayout;
    av_channel_layout_default(&out_chlayout, 2);

    AVSampleFormat out_fmt = AV_SAMPLE_FMT_S16;
    int out_rate = m_ff->codec_ctx_audio->sample_rate;

    // 创建 SwrContext
    int ret = swr_alloc_set_opts2(&swrCtx, &out_chlayout, out_fmt, out_rate,
                                  in_chlayout, in_fmt, in_rate, 0, nullptr);
    swr_init(swrCtx);
    get_ffmpeg_audio_data();
    qDebug() << "real_data_size: " << buf_real_size;
  }

  ~AudioWave() { swr_free(&swrCtx); }

  void start() { open(QIODevice::ReadOnly); }

  void set_format(QAudioFormat &format) {
    format.setSampleRate(m_ff->sample_rate);
    format.setChannelCount(2);
    format.setSampleFormat(QAudioFormat::Int16);
  }

protected:
  qint64 readData(char *data, qint64 maxlen) override {
    // qDebug() << "Requesting " << maxlen << " bytes.";
    qint64 total = 0;
    qint64 remain;
    qint64 need;
    qint64 chunk;

    if (pos >= buf_real_size) {
      pos = 0;
      get_ffmpeg_audio_data();
    }

    while (total < maxlen) {
      remain = buf_real_size - pos;
      need = maxlen - total;
      chunk = std::min(remain, need);

      memcpy(data + total, buf.data() + pos, chunk);

      pos += chunk;
      total += chunk;

      if (pos >= buf_real_size) {
        pos = 0;
        get_ffmpeg_audio_data();
      }
    }

    return total;
  }

  qint64 writeData(const char *, qint64) override { return -1; }

  qint64 bytesAvailable() const override {
    return buf_real_size + QIODevice::bytesAvailable();
  }

private:
  Ffmpeg_frame *m_ff;
  qint64 *m_audio_pts;
  int buf_size;
  qint64 buf_real_size;
  std::vector<char> buf;
  SwrContext *swrCtx = nullptr;

  int get_ffmpeg_audio_data() {
    AVFrame *frame = m_ff->get_a_frame_audio();
    if (frame != nullptr)
      *m_audio_pts = frame->best_effort_timestamp;
    else {
      *m_audio_pts = std::numeric_limits<qint64>::max();
      return 0;
    }

    int out_samples = av_rescale_rnd(
        swr_get_delay(swrCtx, frame->sample_rate) + frame->nb_samples,
        frame->sample_rate, frame->sample_rate, AV_ROUND_UP);

    int channels = frame->ch_layout.nb_channels;

    int out_bytes = av_samples_get_buffer_size(nullptr, channels, out_samples,
                                               AV_SAMPLE_FMT_S16, 1);
    buf.resize(out_bytes);
    uint8_t *out[1] = {reinterpret_cast<uint8_t *>(buf.data())};

    int converted =
        swr_convert(swrCtx, out, out_samples, (const uint8_t **)frame->data,
                    frame->nb_samples);

    buf_real_size = av_samples_get_buffer_size(nullptr, channels, converted,
                                               AV_SAMPLE_FMT_S16, 1);
    av_frame_unref(frame);
    return buf_real_size;
  }
};

class VideoProvider : public QObject {
  Q_OBJECT
  QML_ELEMENT
  Q_PROPERTY(QVideoSink *videoSink READ videoSink WRITE setVideoSink NOTIFY
                 videoSinkChanged)
  Q_PROPERTY(QString videoPath READ videoPath WRITE setVideoPath NOTIFY
                 videoPathChanged)
  Q_PROPERTY(bool videoPlaying READ videoPlaying)
  Q_PROPERTY(int videoWidth READ videoWidth)
  Q_PROPERTY(int videoHeight READ videoHeight)
  Q_PROPERTY(int progressTime READ progressTime)

public:
  AVRational video_steam_base_time;
  AVRational audio_steam_base_time;
  explicit VideoProvider(QObject *parent = nullptr) : QObject(parent) {}

  ~VideoProvider() { delete ffmpeg_frame; }

  QVideoSink *videoSink() const { return m_sink; }
  QString videoPath() const { return m_videoPath; }
  bool videoPlaying() const { return m_videoPlaying; }
  int videoWidth() const { return ffmpeg_frame->width; }
  int videoHeight() const {
    qDebug() << "get ffmpeg_frame->height = " << ffmpeg_frame->height;
    return ffmpeg_frame->height;
  }
  int progressTime() const { return ffmpeg_frame->progress_time; }

  void setVideoSink(QVideoSink *sink) {
    if (m_sink != sink) {
      m_sink = sink;
      emit videoSinkChanged();
    }
  }

  void setVideoPath(QString p) {
    if (m_videoPath != p) {
      m_videoPath = p;
      emit videoPathChanged();
    }
  }

  Q_INVOKABLE int init_filters(QString filter_descr) {
    return ffmpeg_frame->init_filters(filter_descr.toStdString().c_str());
  }

  Q_INVOKABLE bool init_video() {
    if (m_videoPath != nullptr && ffmpeg_frame == nullptr) {
      qDebug() << "new Ffmpeg_frame(\"" << m_videoPath << "\")";
      ffmpeg_frame = new Ffmpeg_frame(m_videoPath);

      video_steam_base_time =
          ffmpeg_frame->fmt_ctx->streams[ffmpeg_frame->video_stream_index]
              ->time_base;
      audio_steam_base_time =
          ffmpeg_frame->fmt_ctx->streams[ffmpeg_frame->audio_stream_index]
              ->time_base;

      QAudioFormat format;
      wave = new AudioWave(ffmpeg_frame, &audio_pts);
      wave->set_format(format);

      m_audio_sink = new QAudioSink(format, nullptr);
      wave->start();
      m_audio_sink->start(wave);
      m_audio_sink->suspend();
      return true;
    }
    return false;
  }

  Q_INVOKABLE void start() {
    // qDebug() << "enter func \"start()\"\n"
    // << "m_videoPath=" << m_videoPath << "\n"
    // << "ffmpeg_frame==nullptr = " << (ffmpeg_frame == nullptr) << "\n";

    if (ffmpeg_frame != nullptr) {
      qDebug() << "start video";
      m_videoPlaying = true;
      m_audio_sink->resume();
      show_video();
    }
  }

  Q_INVOKABLE void stop() {
    qDebug() << "enter func stop()";
    m_videoPlaying = false;
    QMutexLocker locker(&video_play_mutex); // 确保视频暂停完成
    m_audio_sink->suspend();
  }

  Q_INVOKABLE int64_t get_total_time() {
    return ffmpeg_frame->get_total_time();
  }

  Q_INVOKABLE void seek(int64_t target_time) {
    ffmpeg_frame->seek(target_time);
  }

  Q_INVOKABLE void show_a_frame() {
    // 移动进度条时显示第一帧
    AVFrame *frn = ffmpeg_frame->get_a_frame_video();
    if (frn == nullptr)
      return;
    generateFrame(frn);
    av_frame_unref(frn);
  }

  Q_INVOKABLE void init_and_show() {
    init_video();
    // show_a_frame();
    start();
    QTimer::singleShot(40, this, [this]() { this->stop(); });
  }

signals:
  void videoSinkChanged();
  void videoPathChanged();
  void videoOKed();

public slots:
  void show_video_thread() {
    QMutexLocker locker(&video_play_mutex);
    AVFrame *frn = ffmpeg_frame->get_a_frame_video();
    if (frn == nullptr)
      return;
    qint64 video_pts =
        av_rescale_q(frn->best_effort_timestamp, video_steam_base_time,
                     audio_steam_base_time);
    int64_t total_time = get_total_time();
    while (total_time >
               av_rescale_q(video_pts, audio_steam_base_time, {1, 100}) &&
           m_videoPlaying) {
      // qDebug() << "show frame pts: " << video_pts;
      // qDebug() << "show audio_pts: " << audio_pts;
      if (video_pts > audio_pts) {
        QThread::msleep(1);
        continue;
      }
      generateFrame(frn);
      av_frame_unref(frn);
      frn = ffmpeg_frame->get_a_frame_video();
      video_pts = av_rescale_q(frn->best_effort_timestamp,
                               video_steam_base_time, audio_steam_base_time);
    }
  }

private:
  QPointer<QVideoSink> m_sink;
  QPointer<QAudioSink> m_audio_sink;
  AudioWave *wave;
  QString m_videoPath = nullptr;
  bool m_videoPlaying = false;
  Ffmpeg_frame *ffmpeg_frame = nullptr;
  qint64 audio_pts;
  QMutex video_play_mutex;

  void show_video() {
    QThread *thread = QThread::create([this]() { this->show_video_thread(); });
    thread->start();
  }

  void generateFrame(AVFrame *frn) {
    if (!m_sink)
      return;

    QVideoFrame video_frame(
        QVideoFrameFormat(QSize(640, 480), QVideoFrameFormat::Format_BGRA8888));
    if (!video_frame.isValid()) {
      qWarning() << "VideoFrame is invalid!";
      return;
    }

    if (!video_frame.map(QVideoFrame::WriteOnly)) {
      qWarning() << "Cannot map VideoFrame for writing!";
      return;
    }
    QImage::Format image_format = QVideoFrameFormat::imageFormatFromPixelFormat(
        video_frame.pixelFormat());
    if (image_format == QImage::Format_Invalid) {
      qWarning() << "Invalid image format from video frame pixel format!";
      video_frame.unmap();
      return;
    }

    int plane = 0;
    QImage image(video_frame.bits(plane), video_frame.width(),
                 video_frame.height(), image_format);
    QImage img = ffmpeg_frame->cvtQImageFromFrame(frn);

    if (img.size() != image.size()) {
      img = img.scaled(image.size(), Qt::IgnoreAspectRatio,
                       Qt::SmoothTransformation);
    }

    if (img.format() != image.format())
      img = img.convertToFormat(image.format());

    QPainter painter(&image);
    painter.drawImage(0, 0, img);
    painter.end();
    video_frame.unmap();

    m_sink->setVideoFrame(video_frame);
  }
};
#endif // VIDEOPROVIDER_H
