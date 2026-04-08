class DiaryPageMeta {
  final String id;
  final String episode;
  final int page;
  final String word;
  final List<String> content;

  DiaryPageMeta({
    required this.id,
    required this.episode,
    required this.page,
    required this.word,
    required this.content,
  });

  factory DiaryPageMeta.fromJson(Map<String, dynamic> json) {
    return DiaryPageMeta(
      id: json['id'] as String,
      episode: json['episode'] as String,
      page: json['page'] as int,
      word: json['word'] as String,
      content: (json['content'] as List<dynamic>).map((e) => e as String).toList(),
    );
  }
}