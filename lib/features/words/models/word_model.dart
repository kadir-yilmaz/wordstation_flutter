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
    // Doğrudan O(1) anahtar kontrolü — döngüsüz, son derece hızlı
    final id = json['id'] ??
        json['Id'] ??
        json['ID'] ??
        json['_id'] ??
        json['wordId'] ??
        json['WordId'];

    final rawEn = json['en'] ??
        json['En'] ??
        json['english'] ??
        json['English'] ??
        json['word'] ??
        json['Word'] ??
        json['text'] ??
        json['Text'] ??
        json['EN'];

    final rawTr = json['tr'] ??
        json['Tr'] ??
        json['turkish'] ??
        json['Turkish'] ??
        json['meaning'] ??
        json['Meaning'] ??
        json['translation'] ??
        json['Translation'] ??
        json['TR'];

    final rawExample = json['example'] ??
        json['Example'] ??
        json['sentence'] ??
        json['Sentence'] ??
        json['sample'] ??
        json['Sample'];

    final rawListName = json['listName'] ??
        json['ListName'] ??
        json['category'] ??
        json['Category'] ??
        json['list'] ??
        json['List'] ??
        json['tag'] ??
        json['Tag'] ??
        json['group'] ??
        json['Group'];

    final userId = json['userId'] ??
        json['UserId'] ??
        json['user_id'] ??
        json['User_Id'];

    final en = (rawEn ?? '').toString().trim();
    final tr = (rawTr ?? '').toString().trim();
    final exampleStr = rawExample?.toString().trim();
    final listNameStr = (rawListName ?? 'General').toString().trim();

    return WordModel(
      id: id,
      en: en,
      tr: tr,
      example: (exampleStr != null && exampleStr.isNotEmpty) ? exampleStr : null,
      listName: listNameStr.isNotEmpty ? listNameStr : 'General',
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
