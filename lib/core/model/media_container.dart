class MediaContainer {
  String mime;

  String url;

  String? thumbnailURL;

  MediaContainer({
    this.mime = '',
    this.url = '',
    this.thumbnailURL,
  });

  factory MediaContainer.fromJson(Map<dynamic, dynamic> parsedJson) {
    return MediaContainer(
      mime: parsedJson['mime'] ?? '',
      url: parsedJson['url'] ?? '',
      thumbnailURL: parsedJson['thumbnailURL'] ?? parsedJson['videoThumbnail'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mime': mime,
      'url': url,
      'thumbnailURL': thumbnailURL,
    };
  }
}
