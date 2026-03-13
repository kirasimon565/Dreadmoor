class Article {
  final String id;
  final String headline;
  final String subheadline;
  final String photo;
  final String caption;
  final List<String> body;
  final String date;     // e.g. "OCTOBER 14, 2026"
  final String reporter; // e.g. "BY ELIAS VOSS"
  final String source;   // e.g. "DREADMOOR DAILY"

  Article({
    required this.id,
    required this.headline,
    required this.subheadline,
    required this.photo,
    required this.caption,
    required this.body,
    required this.date,
    required this.reporter,
    required this.source,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json["id"] ?? '0',
      headline: json["headline"] ?? 'No Headline',
      subheadline: json["subheadline"] ?? '',
      photo: json["photo"] ?? '',
      caption: json["caption"] ?? '',
      body: json["body"] != null ? List<String>.from(json["body"]) : [],
      date: json["date"] ?? 'UNKNOWN DATE',
      reporter: json["reporter"] ?? 'STAFF WRITER',
      source: json["source"] ?? 'DREADMOOR ARCHIVE',
    );
  }
}
