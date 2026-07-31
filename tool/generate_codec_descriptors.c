// gcc codec_descriptors.c -g $(pkg-config --cflags --libs libavformat \
// libavcodec libavutil) -o generate_codec_descriptors.c
// ./generate_codec_descriptors.c > ../codec_descriptors.h

#include <libavcodec/avcodec.h>
#include <libavcodec/codec_desc.h>
#include <libavcodec/codec_id.h>
#include <libavformat/avformat.h>
#include <libavutil/error.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct _List {
  char name[128];
  struct _List *next;
} List;

void add_item(const char *name, List *list_head) {
  while (list_head->next != NULL)
    list_head = list_head->next;
  strcpy(list_head->name, name);
  list_head->next = malloc(sizeof(List));
  list_head->next->next = NULL;
}

void free_List(List *list_head) {
  if (list_head->next != NULL)
    free_List(list_head->next);
  free(list_head);
}

int is_exists(const char *name, List *list_head) {
  while (list_head->next != NULL) {
    if (strlen(name) == strlen(list_head->name) &&
        strcmp(name, list_head->name) == 0)
      return 1;
    list_head = list_head->next;
  }
  return 0;
}

void print_list(List *list_head) {
  while (list_head->next != NULL) {
    puts(list_head->name);
    list_head = list_head->next;
  }
}

char *print_cpp_QMap(char *ext, List *list_head_video, List *list_head_audio) {
  char *out = malloc(10240);
  char video_codec_str[1024];
  char audio_codec_str[1024];

  char buf[128];
  char buf2[128];

  memset(video_codec_str, '\0', sizeof(video_codec_str));
  memset(audio_codec_str, '\0', sizeof(audio_codec_str));

  sprintf(out, "{\"%s\",{", ext);

  sprintf(video_codec_str, "{\"video\",{");
  while (list_head_video->next != NULL) {
    sprintf(buf, "\"%s\",", list_head_video->name);
    strcat(video_codec_str, buf);
    list_head_video = list_head_video->next;
  }
  if (video_codec_str[strlen(video_codec_str) - 1] == ',')
    video_codec_str[strlen(video_codec_str) - 1] = '\0';
  sprintf(buf2, "%s}},", video_codec_str);
  strcat(out, buf2);

  sprintf(audio_codec_str, "{\"audio\",{");
  while (list_head_audio->next != NULL) {
    sprintf(buf, "\"%s\",", list_head_audio->name);
    strcat(audio_codec_str, buf);
    list_head_audio = list_head_audio->next;
  }
  if (audio_codec_str[strlen(audio_codec_str) - 1] == ',')
    audio_codec_str[strlen(audio_codec_str) - 1] = '\0';
  sprintf(buf2, "%s}}}},", audio_codec_str);
  strcat(out, buf2);
  return out;
}

typedef struct AVCodecTag {
  enum AVCodecID id;
  unsigned int tag;
} AVCodecTag;

char *print_cpp_QMap2_only_one(const AVOutputFormat *out_mtx, char *ext) {
  enum AVCodecID id;
  List *list_head_video = malloc(sizeof(List));
  List *list_head_audio = malloc(sizeof(List));
  list_head_audio->next = NULL;
  list_head_video->next = NULL;

  if ((id = out_mtx->video_codec) != AV_CODEC_ID_NONE) {
    const AVCodecDescriptor *codec_desc = avcodec_descriptor_get(id);
    add_item(codec_desc->name, list_head_video);
  }
  if ((id = out_mtx->audio_codec) != AV_CODEC_ID_NONE) {
    const AVCodecDescriptor *codec_desc = avcodec_descriptor_get(id);
    add_item(codec_desc->name, list_head_audio);
  }
  char *out = print_cpp_QMap(ext, list_head_video, list_head_audio);
  free_List(list_head_audio);
  free_List(list_head_video);

  return out;
}

char *print_cpp_QMap2(char *ext) {
  char filename[256] = "a.";
  strcat(filename, ext);
  const AVOutputFormat *out_mtx = av_guess_format(NULL, filename, NULL);
  const struct AVCodecTag *const *tags = out_mtx->codec_tag;
  if (tags == NULL)
    return print_cpp_QMap2_only_one(out_mtx, ext);
  enum AVCodecID id;
  List *list_head_video = malloc(sizeof(List));
  List *list_head_audio = malloc(sizeof(List));
  list_head_audio->next = NULL;
  list_head_video->next = NULL;
  for (int t = 0; tags[t] != NULL; t++) {
    for (int i = 0; (id = tags[t][i].id) != AV_CODEC_ID_NONE; i++) {
      const AVCodecDescriptor *codec_desc = avcodec_descriptor_get(id);
      if (codec_desc->type == AVMEDIA_TYPE_VIDEO &&
          !is_exists(codec_desc->name, list_head_video))
        add_item(codec_desc->name, list_head_video);
      else if (codec_desc->type == AVMEDIA_TYPE_AUDIO &&
               !is_exists(codec_desc->name, list_head_audio))
        add_item(codec_desc->name, list_head_audio);
    }
  }
  char *out = print_cpp_QMap(ext, list_head_video, list_head_audio);
  free_List(list_head_audio);
  free_List(list_head_video);
  return out;
}

int main(int argc, char *argv[]) {
  char buf[256];
  void *opaque = NULL;
  const AVOutputFormat *fmt = NULL;
  List *list_head_ext = malloc(sizeof(List));
  list_head_ext->next = NULL;
  char *o = NULL;

  puts("// 由 tool/generate_codec_descriptors.c 生成\n\n#ifndef "
       "CODEC_DESCRIPTORS_H\n#define CODEC_DESCRIPTORS_H\n\n#include "
       "<qlist.h>\n#include <qmap.h>\n\ninline QMap<QString, QMap<QString, "
       "QList<QString>>> codec_supports = {");

  while ((fmt = av_muxer_iterate(&opaque))) {
    if (fmt->extensions == NULL)
      continue;
    strcpy(buf, fmt->extensions);
    char *tok = strtok(buf, ",");
    while (tok) {
      if (!is_exists(tok, list_head_ext)) {
        char *out = print_cpp_QMap2(tok);
        if (o != NULL) {
          puts(o);
          free(o);
        }
        o = out;
        add_item(tok, list_head_ext);
      }
      tok = strtok(NULL, ",");
    }
  }
  o[strlen(o) - 1] = '\0';
  printf("%s\n};\n\n#endif // CODEC_DESCRIPTORS_H", o);
  return 0;
}
