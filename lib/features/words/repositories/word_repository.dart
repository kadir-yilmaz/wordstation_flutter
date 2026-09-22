import 'dart:async';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/sync/connectivity_service.dart';
import '../../../core/sync/sync_manager.dart';
import '../models/word_model.dart';
import '../services/word_service.dart';

abstract interface class IWordRepository {
  Future<List<WordModel>> getWords({
    String? listName,
    bool forceRefresh = false,
  });
  Stream<List<WordModel>> watchWords({String? listName});
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
  final db = ref.watch(appDatabaseProvider);
  final service = ref.watch(wordServiceProvider);
  final syncManager = ref.watch(syncManagerProvider);
  final connectivity = ref.watch(connectivityServiceProvider);

  return WordRepositoryImpl(
    db: db,
    wordService: service,
    syncManager: syncManager,
    connectivity: connectivity,
  );
});

class WordRepositoryImpl implements IWordRepository {
  final AppDatabase db;
  final WordService wordService;
  final ISyncManager syncManager;
  final IConnectivityService connectivity;

  WordRepositoryImpl({
    required this.db,
    required this.wordService,
    required this.syncManager,
    required this.connectivity,
  });

  WordModel _dataToModel(WordsTableData data) {
    return WordModel(
      id: data.id,
      en: data.en,
      tr: data.tr,
      example: data.example,
      listName: data.listName,
      userId: data.userId,
    );
  }

  WordsTableCompanion _modelToCompanion(WordModel model, {bool isSynced = true}) {
    return WordsTableCompanion(
      id: Value(model.id),
      en: Value(model.en),
      tr: Value(model.tr),
      example: Value(model.example),
      listName: Value(model.listName ?? 'General'),
      userId: Value(model.userId is int ? model.userId as int : int.tryParse(model.userId?.toString() ?? '')),
      isSynced: Value(isSynced),
      updatedAt: Value(DateTime.now()),
    );
  }

  @override
  Stream<List<WordModel>> watchWords({String? listName}) {
    return db.watchAllWords().map((list) {
      if (listName != null && listName != 'All' && listName != 'Tümü') {
        return list
            .where((w) => w.listName == listName)
            .map(_dataToModel)
            .toList();
      }
      return list.map(_dataToModel).toList();
    });
  }

  @override
  Future<List<WordModel>> getWords({
    String? listName,
    bool forceRefresh = false,
  }) async {
    final localData = (listName != null && listName != 'All' && listName != 'Tümü')
        ? await db.getWordsByList(listName)
        : await db.getAllWords();

    final localWords = localData.map(_dataToModel).toList();

    if (localWords.isNotEmpty && !forceRefresh) {
      unawaited(_silentSyncFromRemote(listName));
      return localWords;
    }

    try {
      final remoteWords = await wordService.getWords(listName: listName);
      if (remoteWords.isNotEmpty) {
        final companions = remoteWords
            .map((w) => _modelToCompanion(w, isSynced: true))
            .toList();
        await db.upsertWords(companions);
        return remoteWords;
      }
      return localWords;
    } catch (_) {
      return localWords;
    }
  }

  Future<void> _silentSyncFromRemote([String? listName]) async {
    if (!await connectivity.isOnline) return;
    try {
      final remoteWords = await wordService.getWords(listName: listName);
      if (remoteWords.isNotEmpty) {
        final companions = remoteWords
            .map((w) => _modelToCompanion(w, isSynced: true))
            .toList();
        await db.upsertWords(companions);
      }
    } catch (_) {}
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

    final isOnline = await connectivity.isOnline;
    if (isOnline) {
      try {
        final created = await wordService.addWord(newModel);
        await db.upsertWord(_modelToCompanion(created, isSynced: true));
        return created;
      } catch (_) {}
    }

    // Offline fallback
    final tempId = DateTime.now().millisecondsSinceEpoch;
    final offlineWord = newModel.copyWith(id: tempId);

    await db.upsertWord(_modelToCompanion(offlineWord, isSynced: false));
    await syncManager.enqueueAction('create_word', {
      'tempId': tempId,
      'en': en,
      'tr': tr,
      'example': example,
      'listName': listName,
    });

    return offlineWord;
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

    final isOnline = await connectivity.isOnline;
    if (isOnline) {
      try {
        final updated = await wordService.updateWord(model);
        await db.upsertWord(_modelToCompanion(updated, isSynced: true));
        return updated;
      } catch (_) {}
    }

    await db.upsertWord(_modelToCompanion(model, isSynced: false));
    await syncManager.enqueueAction('edit_word', {
      'id': id,
      'en': en,
      'tr': tr,
      'example': example,
      'listName': listName,
    });

    return model;
  }

  @override
  Future<bool> deleteWord(int id) async {
    await db.deleteWordById(id);

    final isOnline = await connectivity.isOnline;
    if (isOnline) {
      try {
        await wordService.deleteWord(id);
        return true;
      } catch (_) {}
    }

    await syncManager.enqueueAction('delete_word', {'id': id});
    return true;
  }

  @override
  Future<bool> createList(String listName) async {
    final isOnline = await connectivity.isOnline;
    if (isOnline) {
      try {
        await wordService.addList(listName);
        return true;
      } catch (_) {}
    }

    await syncManager.enqueueAction('create_list', {'listName': listName});
    return true;
  }

  @override
  Future<bool> renameList(String oldName, String newName) async {
    await db.renameListLocally(oldName, newName);

    final isOnline = await connectivity.isOnline;
    if (isOnline) {
      try {
        await wordService.renameList(oldName, newName);
        return true;
      } catch (_) {}
    }

    await syncManager.enqueueAction('rename_list', {
      'oldName': oldName,
      'newName': newName,
    });
    return true;
  }

  @override
  Future<bool> deleteList(String listName) async {
    await db.deleteListLocally(listName);

    final isOnline = await connectivity.isOnline;
    if (isOnline) {
      try {
        await wordService.deleteList(listName);
        return true;
      } catch (_) {}
    }

    await syncManager.enqueueAction('delete_list', {'listName': listName});
    return true;
  }
}
