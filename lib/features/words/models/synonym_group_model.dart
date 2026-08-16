import 'word_model.dart';

class SynonymGroupModel {
  final String turkishMeaning;
  final List<WordModel> words;

  const SynonymGroupModel({
    required this.turkishMeaning,
    required this.words,
  });

  factory SynonymGroupModel.fromJson(Map<String, dynamic> json) {
    final tr = (json['turkish'] ?? json['tr'] ?? json['meaning'] ?? json['group'] ?? '').toString();
    final wordsList = (json['words'] ?? json['items'] ?? json['synonyms'] ?? []) as List;

    return SynonymGroupModel(
      turkishMeaning: tr,
      words: wordsList.map((item) {
        if (item is Map<String, dynamic>) {
          return WordModel.fromJson(item);
        } else if (item is Map) {
          return WordModel.fromJson(Map<String, dynamic>.from(item));
        } else {
          return WordModel(en: item.toString(), tr: tr);
        }
      }).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'turkishMeaning': turkishMeaning,
      'words': words.map((w) => w.toJson()).toList(),
    };
  }
}
