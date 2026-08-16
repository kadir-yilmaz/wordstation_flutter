class WordModel {
  final dynamic id;
  final String en;
  final String tr;
  final String? example;
  final String? listName;
  final dynamic userId;

  const WordModel({
    this.id,
    required this.en,
    required this.tr,
    this.example,
    this.listName,
    this.userId,
  });

  factory WordModel.fromJson(Map<String, dynamic> json) {
    // Helper to find value case-insensitively
    dynamic findVal(List<String> keys) {
      for (final key in keys) {
        if (json.containsKey(key) && json[key] != null) {
          return json[key];
        }
      }
      // Check lowercase matching
      for (final entry in json.entries) {
        for (final key in keys) {
          if (entry.key.toLowerCase() == key.toLowerCase() && entry.value != null) {
            return entry.value;
          }
        }
      }
      return null;
    }

    final id = findVal(['id', 'Id', '_id', 'ID', 'wordId', 'WordId']);
    final en = (findVal(['en', 'En', 'EN', 'english', 'English', 'word', 'Word', 'text', 'Text']) ?? '').toString().trim();
    final tr = (findVal(['tr', 'Tr', 'TR', 'turkish', 'Turkish', 'meaning', 'Meaning', 'translation', 'Translation']) ?? '').toString().trim();
    final example = findVal(['example', 'Example', 'sentence', 'Sentence', 'sample', 'Sample'])?.toString().trim();
    final listName = (findVal(['listName', 'ListName', 'list', 'List', 'category', 'Category', 'tag', 'Tag', 'group', 'Group']) ?? 'General').toString().trim();
    final userId = findVal(['userId', 'UserId', 'user_id', 'User_Id']);

    return WordModel(
      id: id,
      en: en,
      tr: tr,
      example: example != null && example.isNotEmpty ? example : null,
      listName: listName.isNotEmpty ? listName : 'General',
      userId: userId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'en': en,
      'tr': tr,
      'example': example ?? '',
      'listName': listName ?? 'General',
      if (userId != null) 'userId': userId,
    };
  }

  WordModel copyWith({
    dynamic id,
    String? en,
    String? tr,
    String? example,
    String? listName,
    dynamic userId,
  }) {
    return WordModel(
      id: id ?? this.id,
      en: en ?? this.en,
      tr: tr ?? this.tr,
      example: example ?? this.example,
      listName: listName ?? this.listName,
      userId: userId ?? this.userId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WordModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          en == other.en &&
          tr == other.tr;

  @override
  int get hashCode => id.hashCode ^ en.hashCode ^ tr.hashCode;
}
