import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart' as drift_import;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/quiz/services/daily_quiz_api_service.dart';
import '../../features/words/models/word_model.dart';
import '../../features/words/services/word_service.dart';
import '../database/app_database.dart';
import 'connectivity_service.dart';

abstract interface class ISyncManager {
  void initialize();
  Future<void> enqueueAction(String actionType, Map<String, dynamic> payload);
  Future<void> syncPendingQueue();
  void dispose();
}

final syncManagerProvider = Provider<ISyncManager>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final wordService = ref.watch(wordServiceProvider);
  final dailyQuizApiService = ref.watch(dailyQuizApiServiceProvider);
  final connectivity = ref.watch(connectivityServiceProvider);

  final manager = SyncManager(
    db: db,
    wordService: wordService,
    dailyQuizApiService: dailyQuizApiService,
    connectivity: connectivity,
  );
  manager.initialize();
  ref.onDispose(manager.dispose);
  return manager;
});

class SyncManager implements ISyncManager {
  final AppDatabase db;
  final WordService wordService;
  final DailyQuizApiService dailyQuizApiService;
  final IConnectivityService connectivity;

  StreamSubscription<bool>? _connectivitySub;
  bool _isSyncing = false;

  SyncManager({
    required this.db,
    required this.wordService,
    required this.dailyQuizApiService,
    required this.connectivity,
  });

  @override
  void initialize() {
    _connectivitySub = connectivity.onConnectivityChanged.listen((isOnline) {
      if (isOnline) {
        syncPendingQueue();
      }
    });
  }

  @override
  Future<void> enqueueAction(
    String actionType,
    Map<String, dynamic> payload,
  ) async {
    // Optimization: If deleting a word that was created offline and not yet synced, cancel both!
    if (actionType == 'delete_word') {
      final deleteId = payload['id'] as int?;
      if (deleteId != null) {
        final pending = await db.getPendingSyncItems();
        for (final item in pending) {
          if (item.actionType == 'create_word') {
            try {
              final cPayload = jsonDecode(item.payloadJson) as Map<String, dynamic>;
              if (cPayload['tempId'] == deleteId) {
                await db.removeSyncQueueItem(item.id);
                return;
              }
            } catch (_) {}
          }
        }
      }
    }

    final payloadJson = jsonEncode(payload);
    await db.addToSyncQueue(actionType, payloadJson);

    if (await connectivity.isOnline) {
      unawaited(syncPendingQueue());
    }
  }

  @override
  Future<void> syncPendingQueue() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final isOnline = await connectivity.isOnline;
      if (!isOnline) {
        _isSyncing = false;
        return;
      }

      final pendingItems = await db.getPendingSyncItems();
      for (final item in pendingItems) {
        try {
          final payload = jsonDecode(item.payloadJson) as Map<String, dynamic>;
          final success = await _executeAction(item.actionType, payload);
          if (success) {
            await db.removeSyncQueueItem(item.id);
          } else {
            await db.incrementSyncRetry(item.id, item.retryCount);
          }
        } catch (_) {
          await db.incrementSyncRetry(item.id, item.retryCount);
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _translateTempIdInPendingQueue(int tempId, int realId) async {
    final pendingItems = await db.getPendingSyncItems();
    for (final item in pendingItems) {
      try {
        final itemPayload = jsonDecode(item.payloadJson) as Map<String, dynamic>;
        if (itemPayload['id'] == tempId) {
          itemPayload['id'] = realId;
          await db.updateSyncQueuePayload(item.id, jsonEncode(itemPayload));
        }
      } catch (_) {}
    }
  }

  Future<bool> _executeAction(
    String actionType,
    Map<String, dynamic> payload,
  ) async {
    switch (actionType) {
      case 'create_word':
        final tempId = payload['tempId'] as int?;
        final word = await wordService.addWord(
          WordModel(
            en: payload['en'] as String,
            tr: payload['tr'] as String,
            example: payload['example'] as String?,
            listName: payload['listName'] as String,
          ),
        );

        if (word.en.isNotEmpty) {
          final realId = word.id;
          if (realId != null && tempId != null && realId != tempId) {
            // 1. Replace temporary record in SQLite with real ID and mark isSynced = true
            await db.replaceTempWord(
              tempId,
              WordsTableCompanion(
                id: drift_import.Value(realId),
                en: drift_import.Value(word.en),
                tr: drift_import.Value(word.tr),
                example: drift_import.Value(word.example),
                listName: drift_import.Value(word.listName ?? (payload['listName'] as String? ?? 'General')),
                isSynced: const drift_import.Value(true),
                updatedAt: drift_import.Value(DateTime.now()),
              ),
            );

            // 2. Translate any chained mutations in the remaining sync queue
            await _translateTempIdInPendingQueue(tempId, realId);
          } else if (word.id != null) {
            await db.upsertWord(
              WordsTableCompanion(
                id: drift_import.Value(word.id!),
                en: drift_import.Value(word.en),
                tr: drift_import.Value(word.tr),
                example: drift_import.Value(word.example),
                listName: drift_import.Value(word.listName ?? (payload['listName'] as String? ?? 'General')),
                isSynced: const drift_import.Value(true),
                updatedAt: drift_import.Value(DateTime.now()),
              ),
            );
          }
          return true;
        }
        return false;

      case 'edit_word':
        final id = payload['id'] as int;
        try {
          final word = await wordService.updateWord(
            WordModel(
              id: id,
              en: payload['en'] as String,
              tr: payload['tr'] as String,
              example: payload['example'] as String?,
              listName: payload['listName'] as String,
            ),
          );
          if (word.en.isNotEmpty) {
            await db.upsertWord(
              WordsTableCompanion(
                id: drift_import.Value(id),
                en: drift_import.Value(word.en),
                tr: drift_import.Value(word.tr),
                example: drift_import.Value(word.example),
                listName: drift_import.Value(word.listName ?? (payload['listName'] as String? ?? 'General')),
                isSynced: const drift_import.Value(true),
                updatedAt: drift_import.Value(DateTime.now()),
              ),
            );
            return true;
          }
          return false;
        } catch (e) {
          if (e.toString().contains('404')) {
            return true; // Item was deleted remotely, dismiss from queue
          }
          rethrow;
        }

      case 'delete_word':
        final id = payload['id'] as int;
        try {
          await wordService.deleteWord(id);
          return true;
        } catch (e) {
          if (e.toString().contains('404')) {
            return true;
          }
          rethrow;
        }

      case 'create_list':
        final listName = payload['listName'] as String;
        await wordService.addList(listName);
        return true;

      case 'rename_list':
        final oldName = payload['oldName'] as String;
        final newName = payload['newName'] as String;
        await wordService.renameList(oldName, newName);
        return true;

      case 'delete_list':
        final listName = payload['listName'] as String;
        await wordService.deleteList(listName);
        return true;

      case 'submit_daily_quiz':
        final score = payload['score'] as int;
        final correctCount = payload['correctCount'] as int;
        final wrongCount = payload['wrongCount'] as int;
        final totalQuestions = payload['totalQuestions'] as int;
        final maxScore = payload['maxScore'] as int;
        final dayNumber = payload['dayNumber'] as int? ?? 1;
        final resultsJson = payload['resultsJson'] as String? ?? '[]';

        final history = await dailyQuizApiService.saveDayHistory(
          dayNumber: dayNumber,
          totalQuestions: totalQuestions,
          correctCount: correctCount,
          wrongCount: wrongCount,
          score: score,
          maxScore: maxScore,
          resultsJson: resultsJson,
        );
        return history != null;

      case 'create_plan':
        final listName = payload['listName'] as String;
        final dailyCount = payload['dailyCount'] as int;
        final englishToTurkish = payload['englishToTurkish'] as bool;
        final plan = await dailyQuizApiService.createOrResetPlan(
          listName: listName,
          dailyCount: dailyCount,
          isEnglishToTurkish: englishToTurkish,
        );
        return plan != null;

      case 'delete_plan':
        return dailyQuizApiService.deletePlan();

      default:
        return true;
    }
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
  }
}
