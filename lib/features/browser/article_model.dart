class Article {
  final String id;
  final String headline;
  final String subheadline;
  final String photo;
  final String caption;
  final List<String> body;

  Article({
    required this.id,
    required this.headline,
    required this.subheadline,
    required this.photo,
    required this.caption,
    required this.body,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json["id"] ?? '0',
      headline: json["headline"] ?? 'No Headline',
      subheadline: json["subheadline"] ?? '',
      photo: json["photo"] ?? '',
      caption: json["caption"] ?? '',
      body: json["body"] != null ? List<String>.from(json["body"]) : [],
    );
  }
}
