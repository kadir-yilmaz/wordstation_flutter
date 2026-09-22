import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'tables.dart';

part 'app_database.g.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

@DriftDatabase(tables: [
  WordsTable,
  DailyPlansTable,
  DailyPlanDaysTable,
  SyncQueueTable,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'wordstation_local.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }

  // ===========================================================================
  // WORDS TABLE OPERATIONS
  // ===========================================================================

  /// Watch all words reactively as a Stream
  Stream<List<WordsTableData>> watchAllWords() {
    return select(wordsTable).watch();
  }

  /// Get all words as a Future
  Future<List<WordsTableData>> getAllWords() {
    return select(wordsTable).get();
  }

  /// Get words by list name
  Future<List<WordsTableData>> getWordsByList(String listName) {
    return (select(wordsTable)..where((tbl) => tbl.listName.equals(listName))).get();
  }

  /// Insert or replace words in batch
  Future<void> upsertWords(List<WordsTableCompanion> wordCompanions) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(wordsTable, wordCompanions);
    });
  }

  /// Insert or update a single word
  Future<void> upsertWord(WordsTableCompanion wordCompanion) async {
    await into(wordsTable).insertOnConflictUpdate(wordCompanion);
  }

  /// Delete word by ID
  Future<int> deleteWordById(int id) {
    return (delete(wordsTable)..where((tbl) => tbl.id.equals(id))).go();
  }

  /// Rename list for all matching words locally
  Future<int> renameListLocally(String oldName, String newName) {
    return (update(wordsTable)..where((tbl) => tbl.listName.equals(oldName))).write(
      WordsTableCompanion(listName: Value(newName)),
    );
  }

  /// Delete entire list of words locally
  Future<int> deleteListLocally(String listName) {
    return (delete(wordsTable)..where((tbl) => tbl.listName.equals(listName))).go();
  }

  /// Clear all words
  Future<int> clearAllWords() {
    return delete(wordsTable).go();
  }

  // ===========================================================================
  // DAILY PLANS OPERATIONS
  // ===========================================================================

  /// Watch active daily plan
  Stream<DailyPlansTableData?> watchActiveDailyPlan() {
    return (select(dailyPlansTable)..where((tbl) => tbl.isActive.equals(true)))
        .watchSingleOrNull();
  }

  /// Get active daily plan
  Future<DailyPlansTableData?> getActiveDailyPlan() {
    return (select(dailyPlansTable)..where((tbl) => tbl.isActive.equals(true)))
        .getSingleOrNull();
  }

  /// Upsert daily plan
  Future<void> upsertDailyPlan(DailyPlansTableCompanion planCompanion) async {
    await into(dailyPlansTable).insertOnConflictUpdate(planCompanion);
  }

  /// Delete daily plan
  Future<int> deleteDailyPlan(String planId) {
    return (delete(dailyPlansTable)..where((tbl) => tbl.id.equals(planId))).go();
  }

  /// Clear all daily plans
  Future<int> clearAllDailyPlans() {
    return delete(dailyPlansTable).go();
  }

  // ===========================================================================
  // DAILY PLAN DAYS OPERATIONS
  // ===========================================================================

  /// Get daily plan days by plan ID
  Future<List<DailyPlanDaysTableData>> getDailyPlanDays(int planId) {
    return (select(dailyPlanDaysTable)
          ..where((tbl) => tbl.dailyQuizPlanId.equals(planId))
          ..orderBy([(t) => OrderingTerm.desc(t.completedAt)]))
        .get();
  }

  /// Upsert daily plan days batch
  Future<void> upsertDailyPlanDays(List<DailyPlanDaysTableCompanion> days) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(dailyPlanDaysTable, days);
    });
  }

  /// Clear plan days
  Future<int> clearAllPlanDays() {
    return delete(dailyPlanDaysTable).go();
  }

  /// Replace a temporary local word with the real backend word in a single transaction
  Future<void> replaceTempWord(int tempId, WordsTableCompanion realCompanion) async {
    await transaction(() async {
      await (delete(wordsTable)..where((tbl) => tbl.id.equals(tempId))).go();
      await into(wordsTable).insertOnConflictUpdate(realCompanion);
    });
  }

  // ===========================================================================
  // SYNC QUEUE OPERATIONS
  // ===========================================================================

  /// Add action to sync queue
  Future<int> addToSyncQueue(String actionType, String payloadJson) {
    return into(syncQueueTable).insert(
      SyncQueueTableCompanion.insert(
        actionType: actionType,
        payloadJson: payloadJson,
      ),
    );
  }

  /// Get all pending sync queue items
  Future<List<SyncQueueTableData>> getPendingSyncItems() {
    return (select(syncQueueTable)
          ..where((tbl) => tbl.retryCount.isSmallerThanValue(5))
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
  }

  /// Update the payload of a sync queue item (used for ID translation)
  Future<int> updateSyncQueuePayload(int id, String newPayloadJson) {
    return (update(syncQueueTable)..where((tbl) => tbl.id.equals(id))).write(
      SyncQueueTableCompanion(payloadJson: Value(newPayloadJson)),
    );
  }

  /// Remove item from sync queue by ID
  Future<int> removeSyncQueueItem(int id) {
    return (delete(syncQueueTable)..where((tbl) => tbl.id.equals(id))).go();
  }

  /// Increment retry count for sync queue item
  Future<int> incrementSyncRetry(int id, int currentRetry) {
    return (update(syncQueueTable)..where((tbl) => tbl.id.equals(id))).write(
      SyncQueueTableCompanion(retryCount: Value(currentRetry + 1)),
    );
  }

  /// Clear all sync queue
  Future<int> clearSyncQueue() {
    return delete(syncQueueTable).go();
  }
}
