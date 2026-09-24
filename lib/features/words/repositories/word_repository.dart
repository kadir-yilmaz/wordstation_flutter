import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/word_model.dart';
import '../services/word_service.dart';

abstract interface class IWordRepository {
  Future<List<WordModel>> getWords({
    String? listName,
    bool forceRefresh = false,
  });
  Future<WordModel?> createWord({
    required String en,
    required String tr,
    String? example,
    required String listName,
  });
  Future<WordModel?> updateWord({
    required int id,
    required String en,
    required String tr,
    String? example,
    required String listName,
  });
  Future<bool> deleteWord(int id);
  Future<bool> createList(String listName);
  Future<bool> renameList(String oldName, String newName);
  Future<bool> deleteList(String listName);
}

final wordRepositoryProvider = Provider<IWordRepository>((ref) {
  final service = ref.watch(wordServiceProvider);
  return WordRepositoryImpl(wordService: service);
});

class WordRepositoryImpl implements IWordRepository {
  final WordService wordService;

  WordRepositoryImpl({required this.wordService});

  @override
  Future<List<WordModel>> getWords({
    String? listName,
    bool forceRefresh = false,
  }) async {
    return await wordService.getWords(listName: listName);
  }

  @override
  Future<WordModel?> createWord({
    required String en,
    required String tr,
    String? example,
    required String listName,
  }) async {
    final newModel = WordModel(
      en: en,
      tr: tr,
      example: example,
      listName: listName,
    );
    final created = await wordService.addWord(newModel);
    return created.en.isNotEmpty ? created : null;
  }

  @override
  Future<WordModel?> updateWord({
    required int id,
    required String en,
    required String tr,
    String? example,
    required String listName,
  }) async {
    final model = WordModel(
      id: id,
      en: en,
      tr: tr,
      example: example,
      listName: listName,
    );
    final updated = await wordService.updateWord(model);
    return updated.en.isNotEmpty ? updated : null;
  }

  @override
  Future<bool> deleteWord(int id) async {
    return await wordService.deleteWord(id);
  }

  @override
  Future<bool> createList(String listName) async {
    await wordService.addList(listName);
    return true;
  }

  @override
  Future<bool> renameList(String oldName, String newName) async {
    await wordService.renameList(oldName, newName);
    return true;
  }

  @override
  Future<bool> deleteList(String listName) async {
    await wordService.deleteList(listName);
    return true;
  }
}
