import 'package:drift/drift.dart';

/// SQLite table for caching and offline-first word vocabulary
class WordsTable extends Table {
  IntColumn get id => integer()();
  TextColumn get en => text()();
  TextColumn get tr => text()();
  TextColumn get example => text().nullable()();
  TextColumn get listName => text()();
  IntColumn get userId => integer().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(true))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// SQLite table for caching and offline-first daily quiz plan
class DailyPlansTable extends Table {
  TextColumn get id => text()();
  TextColumn get listName => text()();
  IntColumn get dailyCount => integer()();
  TextColumn get shuffledWordIdsJson => text()(); // JSON list of IDs
  IntColumn get currentPointer => integer().withDefault(const Constant(0))();
  IntColumn get streakDays => integer().withDefault(const Constant(0))();
  TextColumn get lastCompletedDate => text().nullable()();
  BoolColumn get isEnglishToTurkish => boolean().withDefault(const Constant(true))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// SQLite table for daily completed plan days history
class DailyPlanDaysTable extends Table {
  IntColumn get id => integer()();
  IntColumn get dailyQuizPlanId => integer()();
  IntColumn get dayNumber => integer()();
  DateTimeColumn get completedAt => dateTime()();
  IntColumn get totalQuestions => integer()();
  IntColumn get correctCount => integer()();
  IntColumn get wrongCount => integer()();
  IntColumn get score => integer()();
  IntColumn get maxScore => integer()();
  TextColumn get resultsJson => text()(); // JSON list of QuizQuestionResult
  BoolColumn get isSynced => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

/// SQLite table for outbox sync queue when actions occur while offline
class SyncQueueTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get actionType => text()(); // 'create_word', 'edit_word', 'delete_word', 'submit_daily_quiz', 'create_plan', 'delete_plan'
  TextColumn get payloadJson => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
}
