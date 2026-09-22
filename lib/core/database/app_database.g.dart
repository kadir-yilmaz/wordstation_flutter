// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $WordsTableTable extends WordsTable
    with TableInfo<$WordsTableTable, WordsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WordsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _enMeta = const VerificationMeta('en');
  @override
  late final GeneratedColumn<String> en = GeneratedColumn<String>(
    'en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _trMeta = const VerificationMeta('tr');
  @override
  late final GeneratedColumn<String> tr = GeneratedColumn<String>(
    'tr',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _exampleMeta = const VerificationMeta(
    'example',
  );
  @override
  late final GeneratedColumn<String> example = GeneratedColumn<String>(
    'example',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _listNameMeta = const VerificationMeta(
    'listName',
  );
  @override
  late final GeneratedColumn<String> listName = GeneratedColumn<String>(
    'list_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    en,
    tr,
    example,
    listName,
    userId,
    isSynced,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'words_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<WordsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('en')) {
      context.handle(_enMeta, en.isAcceptableOrUnknown(data['en']!, _enMeta));
    } else if (isInserting) {
      context.missing(_enMeta);
    }
    if (data.containsKey('tr')) {
      context.handle(_trMeta, tr.isAcceptableOrUnknown(data['tr']!, _trMeta));
    } else if (isInserting) {
      context.missing(_trMeta);
    }
    if (data.containsKey('example')) {
      context.handle(
        _exampleMeta,
        example.isAcceptableOrUnknown(data['example']!, _exampleMeta),
      );
    }
    if (data.containsKey('list_name')) {
      context.handle(
        _listNameMeta,
        listName.isAcceptableOrUnknown(data['list_name']!, _listNameMeta),
      );
    } else if (isInserting) {
      context.missing(_listNameMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WordsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WordsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      en: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}en'],
      )!,
      tr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tr'],
      )!,
      example: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}example'],
      ),
      listName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}list_name'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_id'],
      ),
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $WordsTableTable createAlias(String alias) {
    return $WordsTableTable(attachedDatabase, alias);
  }
}

class WordsTableData extends DataClass implements Insertable<WordsTableData> {
  final int id;
  final String en;
  final String tr;
  final String? example;
  final String listName;
  final int? userId;
  final bool isSynced;
  final DateTime updatedAt;
  const WordsTableData({
    required this.id,
    required this.en,
    required this.tr,
    this.example,
    required this.listName,
    this.userId,
    required this.isSynced,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['en'] = Variable<String>(en);
    map['tr'] = Variable<String>(tr);
    if (!nullToAbsent || example != null) {
      map['example'] = Variable<String>(example);
    }
    map['list_name'] = Variable<String>(listName);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<int>(userId);
    }
    map['is_synced'] = Variable<bool>(isSynced);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  WordsTableCompanion toCompanion(bool nullToAbsent) {
    return WordsTableCompanion(
      id: Value(id),
      en: Value(en),
      tr: Value(tr),
      example: example == null && nullToAbsent
          ? const Value.absent()
          : Value(example),
      listName: Value(listName),
      userId: userId == null && nullToAbsent
          ? const Value.absent()
          : Value(userId),
      isSynced: Value(isSynced),
      updatedAt: Value(updatedAt),
    );
  }

  factory WordsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WordsTableData(
      id: serializer.fromJson<int>(json['id']),
      en: serializer.fromJson<String>(json['en']),
      tr: serializer.fromJson<String>(json['tr']),
      example: serializer.fromJson<String?>(json['example']),
      listName: serializer.fromJson<String>(json['listName']),
      userId: serializer.fromJson<int?>(json['userId']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'en': serializer.toJson<String>(en),
      'tr': serializer.toJson<String>(tr),
      'example': serializer.toJson<String?>(example),
      'listName': serializer.toJson<String>(listName),
      'userId': serializer.toJson<int?>(userId),
      'isSynced': serializer.toJson<bool>(isSynced),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  WordsTableData copyWith({
    int? id,
    String? en,
    String? tr,
    Value<String?> example = const Value.absent(),
    String? listName,
    Value<int?> userId = const Value.absent(),
    bool? isSynced,
    DateTime? updatedAt,
  }) => WordsTableData(
    id: id ?? this.id,
    en: en ?? this.en,
    tr: tr ?? this.tr,
    example: example.present ? example.value : this.example,
    listName: listName ?? this.listName,
    userId: userId.present ? userId.value : this.userId,
    isSynced: isSynced ?? this.isSynced,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  WordsTableData copyWithCompanion(WordsTableCompanion data) {
    return WordsTableData(
      id: data.id.present ? data.id.value : this.id,
      en: data.en.present ? data.en.value : this.en,
      tr: data.tr.present ? data.tr.value : this.tr,
      example: data.example.present ? data.example.value : this.example,
      listName: data.listName.present ? data.listName.value : this.listName,
      userId: data.userId.present ? data.userId.value : this.userId,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WordsTableData(')
          ..write('id: $id, ')
          ..write('en: $en, ')
          ..write('tr: $tr, ')
          ..write('example: $example, ')
          ..write('listName: $listName, ')
          ..write('userId: $userId, ')
          ..write('isSynced: $isSynced, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, en, tr, example, listName, userId, isSynced, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WordsTableData &&
          other.id == this.id &&
          other.en == this.en &&
          other.tr == this.tr &&
          other.example == this.example &&
          other.listName == this.listName &&
          other.userId == this.userId &&
          other.isSynced == this.isSynced &&
          other.updatedAt == this.updatedAt);
}

class WordsTableCompanion extends UpdateCompanion<WordsTableData> {
  final Value<int> id;
  final Value<String> en;
  final Value<String> tr;
  final Value<String?> example;
  final Value<String> listName;
  final Value<int?> userId;
  final Value<bool> isSynced;
  final Value<DateTime> updatedAt;
  const WordsTableCompanion({
    this.id = const Value.absent(),
    this.en = const Value.absent(),
    this.tr = const Value.absent(),
    this.example = const Value.absent(),
    this.listName = const Value.absent(),
    this.userId = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  WordsTableCompanion.insert({
    this.id = const Value.absent(),
    required String en,
    required String tr,
    this.example = const Value.absent(),
    required String listName,
    this.userId = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : en = Value(en),
       tr = Value(tr),
       listName = Value(listName);
  static Insertable<WordsTableData> custom({
    Expression<int>? id,
    Expression<String>? en,
    Expression<String>? tr,
    Expression<String>? example,
    Expression<String>? listName,
    Expression<int>? userId,
    Expression<bool>? isSynced,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (en != null) 'en': en,
      if (tr != null) 'tr': tr,
      if (example != null) 'example': example,
      if (listName != null) 'list_name': listName,
      if (userId != null) 'user_id': userId,
      if (isSynced != null) 'is_synced': isSynced,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  WordsTableCompanion copyWith({
    Value<int>? id,
    Value<String>? en,
    Value<String>? tr,
    Value<String?>? example,
    Value<String>? listName,
    Value<int?>? userId,
    Value<bool>? isSynced,
    Value<DateTime>? updatedAt,
  }) {
    return WordsTableCompanion(
      id: id ?? this.id,
      en: en ?? this.en,
      tr: tr ?? this.tr,
      example: example ?? this.example,
      listName: listName ?? this.listName,
      userId: userId ?? this.userId,
      isSynced: isSynced ?? this.isSynced,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (en.present) {
      map['en'] = Variable<String>(en.value);
    }
    if (tr.present) {
      map['tr'] = Variable<String>(tr.value);
    }
    if (example.present) {
      map['example'] = Variable<String>(example.value);
    }
    if (listName.present) {
      map['list_name'] = Variable<String>(listName.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WordsTableCompanion(')
          ..write('id: $id, ')
          ..write('en: $en, ')
          ..write('tr: $tr, ')
          ..write('example: $example, ')
          ..write('listName: $listName, ')
          ..write('userId: $userId, ')
          ..write('isSynced: $isSynced, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $DailyPlansTableTable extends DailyPlansTable
    with TableInfo<$DailyPlansTableTable, DailyPlansTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyPlansTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _listNameMeta = const VerificationMeta(
    'listName',
  );
  @override
  late final GeneratedColumn<String> listName = GeneratedColumn<String>(
    'list_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dailyCountMeta = const VerificationMeta(
    'dailyCount',
  );
  @override
  late final GeneratedColumn<int> dailyCount = GeneratedColumn<int>(
    'daily_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shuffledWordIdsJsonMeta =
      const VerificationMeta('shuffledWordIdsJson');
  @override
  late final GeneratedColumn<String> shuffledWordIdsJson =
      GeneratedColumn<String>(
        'shuffled_word_ids_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _currentPointerMeta = const VerificationMeta(
    'currentPointer',
  );
  @override
  late final GeneratedColumn<int> currentPointer = GeneratedColumn<int>(
    'current_pointer',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _streakDaysMeta = const VerificationMeta(
    'streakDays',
  );
  @override
  late final GeneratedColumn<int> streakDays = GeneratedColumn<int>(
    'streak_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastCompletedDateMeta = const VerificationMeta(
    'lastCompletedDate',
  );
  @override
  late final GeneratedColumn<String> lastCompletedDate =
      GeneratedColumn<String>(
        'last_completed_date',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _isEnglishToTurkishMeta =
      const VerificationMeta('isEnglishToTurkish');
  @override
  late final GeneratedColumn<bool> isEnglishToTurkish = GeneratedColumn<bool>(
    'is_english_to_turkish',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_english_to_turkish" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    listName,
    dailyCount,
    shuffledWordIdsJson,
    currentPointer,
    streakDays,
    lastCompletedDate,
    isEnglishToTurkish,
    isActive,
    isSynced,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_plans_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyPlansTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('list_name')) {
      context.handle(
        _listNameMeta,
        listName.isAcceptableOrUnknown(data['list_name']!, _listNameMeta),
      );
    } else if (isInserting) {
      context.missing(_listNameMeta);
    }
    if (data.containsKey('daily_count')) {
      context.handle(
        _dailyCountMeta,
        dailyCount.isAcceptableOrUnknown(data['daily_count']!, _dailyCountMeta),
      );
    } else if (isInserting) {
      context.missing(_dailyCountMeta);
    }
    if (data.containsKey('shuffled_word_ids_json')) {
      context.handle(
        _shuffledWordIdsJsonMeta,
        shuffledWordIdsJson.isAcceptableOrUnknown(
          data['shuffled_word_ids_json']!,
          _shuffledWordIdsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_shuffledWordIdsJsonMeta);
    }
    if (data.containsKey('current_pointer')) {
      context.handle(
        _currentPointerMeta,
        currentPointer.isAcceptableOrUnknown(
          data['current_pointer']!,
          _currentPointerMeta,
        ),
      );
    }
    if (data.containsKey('streak_days')) {
      context.handle(
        _streakDaysMeta,
        streakDays.isAcceptableOrUnknown(data['streak_days']!, _streakDaysMeta),
      );
    }
    if (data.containsKey('last_completed_date')) {
      context.handle(
        _lastCompletedDateMeta,
        lastCompletedDate.isAcceptableOrUnknown(
          data['last_completed_date']!,
          _lastCompletedDateMeta,
        ),
      );
    }
    if (data.containsKey('is_english_to_turkish')) {
      context.handle(
        _isEnglishToTurkishMeta,
        isEnglishToTurkish.isAcceptableOrUnknown(
          data['is_english_to_turkish']!,
          _isEnglishToTurkishMeta,
        ),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DailyPlansTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyPlansTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      listName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}list_name'],
      )!,
      dailyCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}daily_count'],
      )!,
      shuffledWordIdsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shuffled_word_ids_json'],
      )!,
      currentPointer: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_pointer'],
      )!,
      streakDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}streak_days'],
      )!,
      lastCompletedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_completed_date'],
      ),
      isEnglishToTurkish: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_english_to_turkish'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $DailyPlansTableTable createAlias(String alias) {
    return $DailyPlansTableTable(attachedDatabase, alias);
  }
}

class DailyPlansTableData extends DataClass
    implements Insertable<DailyPlansTableData> {
  final String id;
  final String listName;
  final int dailyCount;
  final String shuffledWordIdsJson;
  final int currentPointer;
  final int streakDays;
  final String? lastCompletedDate;
  final bool isEnglishToTurkish;
  final bool isActive;
  final bool isSynced;
  final DateTime createdAt;
  const DailyPlansTableData({
    required this.id,
    required this.listName,
    required this.dailyCount,
    required this.shuffledWordIdsJson,
    required this.currentPointer,
    required this.streakDays,
    this.lastCompletedDate,
    required this.isEnglishToTurkish,
    required this.isActive,
    required this.isSynced,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['list_name'] = Variable<String>(listName);
    map['daily_count'] = Variable<int>(dailyCount);
    map['shuffled_word_ids_json'] = Variable<String>(shuffledWordIdsJson);
    map['current_pointer'] = Variable<int>(currentPointer);
    map['streak_days'] = Variable<int>(streakDays);
    if (!nullToAbsent || lastCompletedDate != null) {
      map['last_completed_date'] = Variable<String>(lastCompletedDate);
    }
    map['is_english_to_turkish'] = Variable<bool>(isEnglishToTurkish);
    map['is_active'] = Variable<bool>(isActive);
    map['is_synced'] = Variable<bool>(isSynced);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  DailyPlansTableCompanion toCompanion(bool nullToAbsent) {
    return DailyPlansTableCompanion(
      id: Value(id),
      listName: Value(listName),
      dailyCount: Value(dailyCount),
      shuffledWordIdsJson: Value(shuffledWordIdsJson),
      currentPointer: Value(currentPointer),
      streakDays: Value(streakDays),
      lastCompletedDate: lastCompletedDate == null && nullToAbsent
          ? const Value.absent()
          : Value(lastCompletedDate),
      isEnglishToTurkish: Value(isEnglishToTurkish),
      isActive: Value(isActive),
      isSynced: Value(isSynced),
      createdAt: Value(createdAt),
    );
  }

  factory DailyPlansTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyPlansTableData(
      id: serializer.fromJson<String>(json['id']),
      listName: serializer.fromJson<String>(json['listName']),
      dailyCount: serializer.fromJson<int>(json['dailyCount']),
      shuffledWordIdsJson: serializer.fromJson<String>(
        json['shuffledWordIdsJson'],
      ),
      currentPointer: serializer.fromJson<int>(json['currentPointer']),
      streakDays: serializer.fromJson<int>(json['streakDays']),
      lastCompletedDate: serializer.fromJson<String?>(
        json['lastCompletedDate'],
      ),
      isEnglishToTurkish: serializer.fromJson<bool>(json['isEnglishToTurkish']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'listName': serializer.toJson<String>(listName),
      'dailyCount': serializer.toJson<int>(dailyCount),
      'shuffledWordIdsJson': serializer.toJson<String>(shuffledWordIdsJson),
      'currentPointer': serializer.toJson<int>(currentPointer),
      'streakDays': serializer.toJson<int>(streakDays),
      'lastCompletedDate': serializer.toJson<String?>(lastCompletedDate),
      'isEnglishToTurkish': serializer.toJson<bool>(isEnglishToTurkish),
      'isActive': serializer.toJson<bool>(isActive),
      'isSynced': serializer.toJson<bool>(isSynced),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  DailyPlansTableData copyWith({
    String? id,
    String? listName,
    int? dailyCount,
    String? shuffledWordIdsJson,
    int? currentPointer,
    int? streakDays,
    Value<String?> lastCompletedDate = const Value.absent(),
    bool? isEnglishToTurkish,
    bool? isActive,
    bool? isSynced,
    DateTime? createdAt,
  }) => DailyPlansTableData(
    id: id ?? this.id,
    listName: listName ?? this.listName,
    dailyCount: dailyCount ?? this.dailyCount,
    shuffledWordIdsJson: shuffledWordIdsJson ?? this.shuffledWordIdsJson,
    currentPointer: currentPointer ?? this.currentPointer,
    streakDays: streakDays ?? this.streakDays,
    lastCompletedDate: lastCompletedDate.present
        ? lastCompletedDate.value
        : this.lastCompletedDate,
    isEnglishToTurkish: isEnglishToTurkish ?? this.isEnglishToTurkish,
    isActive: isActive ?? this.isActive,
    isSynced: isSynced ?? this.isSynced,
    createdAt: createdAt ?? this.createdAt,
  );
  DailyPlansTableData copyWithCompanion(DailyPlansTableCompanion data) {
    return DailyPlansTableData(
      id: data.id.present ? data.id.value : this.id,
      listName: data.listName.present ? data.listName.value : this.listName,
      dailyCount: data.dailyCount.present
          ? data.dailyCount.value
          : this.dailyCount,
      shuffledWordIdsJson: data.shuffledWordIdsJson.present
          ? data.shuffledWordIdsJson.value
          : this.shuffledWordIdsJson,
      currentPointer: data.currentPointer.present
          ? data.currentPointer.value
          : this.currentPointer,
      streakDays: data.streakDays.present
          ? data.streakDays.value
          : this.streakDays,
      lastCompletedDate: data.lastCompletedDate.present
          ? data.lastCompletedDate.value
          : this.lastCompletedDate,
      isEnglishToTurkish: data.isEnglishToTurkish.present
          ? data.isEnglishToTurkish.value
          : this.isEnglishToTurkish,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyPlansTableData(')
          ..write('id: $id, ')
          ..write('listName: $listName, ')
          ..write('dailyCount: $dailyCount, ')
          ..write('shuffledWordIdsJson: $shuffledWordIdsJson, ')
          ..write('currentPointer: $currentPointer, ')
          ..write('streakDays: $streakDays, ')
          ..write('lastCompletedDate: $lastCompletedDate, ')
          ..write('isEnglishToTurkish: $isEnglishToTurkish, ')
          ..write('isActive: $isActive, ')
          ..write('isSynced: $isSynced, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    listName,
    dailyCount,
    shuffledWordIdsJson,
    currentPointer,
    streakDays,
    lastCompletedDate,
    isEnglishToTurkish,
    isActive,
    isSynced,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyPlansTableData &&
          other.id == this.id &&
          other.listName == this.listName &&
          other.dailyCount == this.dailyCount &&
          other.shuffledWordIdsJson == this.shuffledWordIdsJson &&
          other.currentPointer == this.currentPointer &&
          other.streakDays == this.streakDays &&
          other.lastCompletedDate == this.lastCompletedDate &&
          other.isEnglishToTurkish == this.isEnglishToTurkish &&
          other.isActive == this.isActive &&
          other.isSynced == this.isSynced &&
          other.createdAt == this.createdAt);
}

class DailyPlansTableCompanion extends UpdateCompanion<DailyPlansTableData> {
  final Value<String> id;
  final Value<String> listName;
  final Value<int> dailyCount;
  final Value<String> shuffledWordIdsJson;
  final Value<int> currentPointer;
  final Value<int> streakDays;
  final Value<String?> lastCompletedDate;
  final Value<bool> isEnglishToTurkish;
  final Value<bool> isActive;
  final Value<bool> isSynced;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const DailyPlansTableCompanion({
    this.id = const Value.absent(),
    this.listName = const Value.absent(),
    this.dailyCount = const Value.absent(),
    this.shuffledWordIdsJson = const Value.absent(),
    this.currentPointer = const Value.absent(),
    this.streakDays = const Value.absent(),
    this.lastCompletedDate = const Value.absent(),
    this.isEnglishToTurkish = const Value.absent(),
    this.isActive = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailyPlansTableCompanion.insert({
    required String id,
    required String listName,
    required int dailyCount,
    required String shuffledWordIdsJson,
    this.currentPointer = const Value.absent(),
    this.streakDays = const Value.absent(),
    this.lastCompletedDate = const Value.absent(),
    this.isEnglishToTurkish = const Value.absent(),
    this.isActive = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       listName = Value(listName),
       dailyCount = Value(dailyCount),
       shuffledWordIdsJson = Value(shuffledWordIdsJson);
  static Insertable<DailyPlansTableData> custom({
    Expression<String>? id,
    Expression<String>? listName,
    Expression<int>? dailyCount,
    Expression<String>? shuffledWordIdsJson,
    Expression<int>? currentPointer,
    Expression<int>? streakDays,
    Expression<String>? lastCompletedDate,
    Expression<bool>? isEnglishToTurkish,
    Expression<bool>? isActive,
    Expression<bool>? isSynced,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (listName != null) 'list_name': listName,
      if (dailyCount != null) 'daily_count': dailyCount,
      if (shuffledWordIdsJson != null)
        'shuffled_word_ids_json': shuffledWordIdsJson,
      if (currentPointer != null) 'current_pointer': currentPointer,
      if (streakDays != null) 'streak_days': streakDays,
      if (lastCompletedDate != null) 'last_completed_date': lastCompletedDate,
      if (isEnglishToTurkish != null)
        'is_english_to_turkish': isEnglishToTurkish,
      if (isActive != null) 'is_active': isActive,
      if (isSynced != null) 'is_synced': isSynced,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailyPlansTableCompanion copyWith({
    Value<String>? id,
    Value<String>? listName,
    Value<int>? dailyCount,
    Value<String>? shuffledWordIdsJson,
    Value<int>? currentPointer,
    Value<int>? streakDays,
    Value<String?>? lastCompletedDate,
    Value<bool>? isEnglishToTurkish,
    Value<bool>? isActive,
    Value<bool>? isSynced,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return DailyPlansTableCompanion(
      id: id ?? this.id,
      listName: listName ?? this.listName,
      dailyCount: dailyCount ?? this.dailyCount,
      shuffledWordIdsJson: shuffledWordIdsJson ?? this.shuffledWordIdsJson,
      currentPointer: currentPointer ?? this.currentPointer,
      streakDays: streakDays ?? this.streakDays,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      isEnglishToTurkish: isEnglishToTurkish ?? this.isEnglishToTurkish,
      isActive: isActive ?? this.isActive,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (listName.present) {
      map['list_name'] = Variable<String>(listName.value);
    }
    if (dailyCount.present) {
      map['daily_count'] = Variable<int>(dailyCount.value);
    }
    if (shuffledWordIdsJson.present) {
      map['shuffled_word_ids_json'] = Variable<String>(
        shuffledWordIdsJson.value,
      );
    }
    if (currentPointer.present) {
      map['current_pointer'] = Variable<int>(currentPointer.value);
    }
    if (streakDays.present) {
      map['streak_days'] = Variable<int>(streakDays.value);
    }
    if (lastCompletedDate.present) {
      map['last_completed_date'] = Variable<String>(lastCompletedDate.value);
    }
    if (isEnglishToTurkish.present) {
      map['is_english_to_turkish'] = Variable<bool>(isEnglishToTurkish.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyPlansTableCompanion(')
          ..write('id: $id, ')
          ..write('listName: $listName, ')
          ..write('dailyCount: $dailyCount, ')
          ..write('shuffledWordIdsJson: $shuffledWordIdsJson, ')
          ..write('currentPointer: $currentPointer, ')
          ..write('streakDays: $streakDays, ')
          ..write('lastCompletedDate: $lastCompletedDate, ')
          ..write('isEnglishToTurkish: $isEnglishToTurkish, ')
          ..write('isActive: $isActive, ')
          ..write('isSynced: $isSynced, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DailyPlanDaysTableTable extends DailyPlanDaysTable
    with TableInfo<$DailyPlanDaysTableTable, DailyPlanDaysTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyPlanDaysTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dailyQuizPlanIdMeta = const VerificationMeta(
    'dailyQuizPlanId',
  );
  @override
  late final GeneratedColumn<int> dailyQuizPlanId = GeneratedColumn<int>(
    'daily_quiz_plan_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayNumberMeta = const VerificationMeta(
    'dayNumber',
  );
  @override
  late final GeneratedColumn<int> dayNumber = GeneratedColumn<int>(
    'day_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalQuestionsMeta = const VerificationMeta(
    'totalQuestions',
  );
  @override
  late final GeneratedColumn<int> totalQuestions = GeneratedColumn<int>(
    'total_questions',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _correctCountMeta = const VerificationMeta(
    'correctCount',
  );
  @override
  late final GeneratedColumn<int> correctCount = GeneratedColumn<int>(
    'correct_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wrongCountMeta = const VerificationMeta(
    'wrongCount',
  );
  @override
  late final GeneratedColumn<int> wrongCount = GeneratedColumn<int>(
    'wrong_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<int> score = GeneratedColumn<int>(
    'score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _maxScoreMeta = const VerificationMeta(
    'maxScore',
  );
  @override
  late final GeneratedColumn<int> maxScore = GeneratedColumn<int>(
    'max_score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _resultsJsonMeta = const VerificationMeta(
    'resultsJson',
  );
  @override
  late final GeneratedColumn<String> resultsJson = GeneratedColumn<String>(
    'results_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    dailyQuizPlanId,
    dayNumber,
    completedAt,
    totalQuestions,
    correctCount,
    wrongCount,
    score,
    maxScore,
    resultsJson,
    isSynced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_plan_days_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyPlanDaysTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('daily_quiz_plan_id')) {
      context.handle(
        _dailyQuizPlanIdMeta,
        dailyQuizPlanId.isAcceptableOrUnknown(
          data['daily_quiz_plan_id']!,
          _dailyQuizPlanIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dailyQuizPlanIdMeta);
    }
    if (data.containsKey('day_number')) {
      context.handle(
        _dayNumberMeta,
        dayNumber.isAcceptableOrUnknown(data['day_number']!, _dayNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_dayNumberMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completedAtMeta);
    }
    if (data.containsKey('total_questions')) {
      context.handle(
        _totalQuestionsMeta,
        totalQuestions.isAcceptableOrUnknown(
          data['total_questions']!,
          _totalQuestionsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalQuestionsMeta);
    }
    if (data.containsKey('correct_count')) {
      context.handle(
        _correctCountMeta,
        correctCount.isAcceptableOrUnknown(
          data['correct_count']!,
          _correctCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_correctCountMeta);
    }
    if (data.containsKey('wrong_count')) {
      context.handle(
        _wrongCountMeta,
        wrongCount.isAcceptableOrUnknown(data['wrong_count']!, _wrongCountMeta),
      );
    } else if (isInserting) {
      context.missing(_wrongCountMeta);
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    } else if (isInserting) {
      context.missing(_scoreMeta);
    }
    if (data.containsKey('max_score')) {
      context.handle(
        _maxScoreMeta,
        maxScore.isAcceptableOrUnknown(data['max_score']!, _maxScoreMeta),
      );
    } else if (isInserting) {
      context.missing(_maxScoreMeta);
    }
    if (data.containsKey('results_json')) {
      context.handle(
        _resultsJsonMeta,
        resultsJson.isAcceptableOrUnknown(
          data['results_json']!,
          _resultsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_resultsJsonMeta);
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DailyPlanDaysTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyPlanDaysTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      dailyQuizPlanId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}daily_quiz_plan_id'],
      )!,
      dayNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_number'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      )!,
      totalQuestions: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_questions'],
      )!,
      correctCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}correct_count'],
      )!,
      wrongCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wrong_count'],
      )!,
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}score'],
      )!,
      maxScore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max_score'],
      )!,
      resultsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}results_json'],
      )!,
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
    );
  }

  @override
  $DailyPlanDaysTableTable createAlias(String alias) {
    return $DailyPlanDaysTableTable(attachedDatabase, alias);
  }
}

class DailyPlanDaysTableData extends DataClass
    implements Insertable<DailyPlanDaysTableData> {
  final int id;
  final int dailyQuizPlanId;
  final int dayNumber;
  final DateTime completedAt;
  final int totalQuestions;
  final int correctCount;
  final int wrongCount;
  final int score;
  final int maxScore;
  final String resultsJson;
  final bool isSynced;
  const DailyPlanDaysTableData({
    required this.id,
    required this.dailyQuizPlanId,
    required this.dayNumber,
    required this.completedAt,
    required this.totalQuestions,
    required this.correctCount,
    required this.wrongCount,
    required this.score,
    required this.maxScore,
    required this.resultsJson,
    required this.isSynced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['daily_quiz_plan_id'] = Variable<int>(dailyQuizPlanId);
    map['day_number'] = Variable<int>(dayNumber);
    map['completed_at'] = Variable<DateTime>(completedAt);
    map['total_questions'] = Variable<int>(totalQuestions);
    map['correct_count'] = Variable<int>(correctCount);
    map['wrong_count'] = Variable<int>(wrongCount);
    map['score'] = Variable<int>(score);
    map['max_score'] = Variable<int>(maxScore);
    map['results_json'] = Variable<String>(resultsJson);
    map['is_synced'] = Variable<bool>(isSynced);
    return map;
  }

  DailyPlanDaysTableCompanion toCompanion(bool nullToAbsent) {
    return DailyPlanDaysTableCompanion(
      id: Value(id),
      dailyQuizPlanId: Value(dailyQuizPlanId),
      dayNumber: Value(dayNumber),
      completedAt: Value(completedAt),
      totalQuestions: Value(totalQuestions),
      correctCount: Value(correctCount),
      wrongCount: Value(wrongCount),
      score: Value(score),
      maxScore: Value(maxScore),
      resultsJson: Value(resultsJson),
      isSynced: Value(isSynced),
    );
  }

  factory DailyPlanDaysTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyPlanDaysTableData(
      id: serializer.fromJson<int>(json['id']),
      dailyQuizPlanId: serializer.fromJson<int>(json['dailyQuizPlanId']),
      dayNumber: serializer.fromJson<int>(json['dayNumber']),
      completedAt: serializer.fromJson<DateTime>(json['completedAt']),
      totalQuestions: serializer.fromJson<int>(json['totalQuestions']),
      correctCount: serializer.fromJson<int>(json['correctCount']),
      wrongCount: serializer.fromJson<int>(json['wrongCount']),
      score: serializer.fromJson<int>(json['score']),
      maxScore: serializer.fromJson<int>(json['maxScore']),
      resultsJson: serializer.fromJson<String>(json['resultsJson']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'dailyQuizPlanId': serializer.toJson<int>(dailyQuizPlanId),
      'dayNumber': serializer.toJson<int>(dayNumber),
      'completedAt': serializer.toJson<DateTime>(completedAt),
      'totalQuestions': serializer.toJson<int>(totalQuestions),
      'correctCount': serializer.toJson<int>(correctCount),
      'wrongCount': serializer.toJson<int>(wrongCount),
      'score': serializer.toJson<int>(score),
      'maxScore': serializer.toJson<int>(maxScore),
      'resultsJson': serializer.toJson<String>(resultsJson),
      'isSynced': serializer.toJson<bool>(isSynced),
    };
  }

  DailyPlanDaysTableData copyWith({
    int? id,
    int? dailyQuizPlanId,
    int? dayNumber,
    DateTime? completedAt,
    int? totalQuestions,
    int? correctCount,
    int? wrongCount,
    int? score,
    int? maxScore,
    String? resultsJson,
    bool? isSynced,
  }) => DailyPlanDaysTableData(
    id: id ?? this.id,
    dailyQuizPlanId: dailyQuizPlanId ?? this.dailyQuizPlanId,
    dayNumber: dayNumber ?? this.dayNumber,
    completedAt: completedAt ?? this.completedAt,
    totalQuestions: totalQuestions ?? this.totalQuestions,
    correctCount: correctCount ?? this.correctCount,
    wrongCount: wrongCount ?? this.wrongCount,
    score: score ?? this.score,
    maxScore: maxScore ?? this.maxScore,
    resultsJson: resultsJson ?? this.resultsJson,
    isSynced: isSynced ?? this.isSynced,
  );
  DailyPlanDaysTableData copyWithCompanion(DailyPlanDaysTableCompanion data) {
    return DailyPlanDaysTableData(
      id: data.id.present ? data.id.value : this.id,
      dailyQuizPlanId: data.dailyQuizPlanId.present
          ? data.dailyQuizPlanId.value
          : this.dailyQuizPlanId,
      dayNumber: data.dayNumber.present ? data.dayNumber.value : this.dayNumber,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      totalQuestions: data.totalQuestions.present
          ? data.totalQuestions.value
          : this.totalQuestions,
      correctCount: data.correctCount.present
          ? data.correctCount.value
          : this.correctCount,
      wrongCount: data.wrongCount.present
          ? data.wrongCount.value
          : this.wrongCount,
      score: data.score.present ? data.score.value : this.score,
      maxScore: data.maxScore.present ? data.maxScore.value : this.maxScore,
      resultsJson: data.resultsJson.present
          ? data.resultsJson.value
          : this.resultsJson,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyPlanDaysTableData(')
          ..write('id: $id, ')
          ..write('dailyQuizPlanId: $dailyQuizPlanId, ')
          ..write('dayNumber: $dayNumber, ')
          ..write('completedAt: $completedAt, ')
          ..write('totalQuestions: $totalQuestions, ')
          ..write('correctCount: $correctCount, ')
          ..write('wrongCount: $wrongCount, ')
          ..write('score: $score, ')
          ..write('maxScore: $maxScore, ')
          ..write('resultsJson: $resultsJson, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    dailyQuizPlanId,
    dayNumber,
    completedAt,
    totalQuestions,
    correctCount,
    wrongCount,
    score,
    maxScore,
    resultsJson,
    isSynced,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyPlanDaysTableData &&
          other.id == this.id &&
          other.dailyQuizPlanId == this.dailyQuizPlanId &&
          other.dayNumber == this.dayNumber &&
          other.completedAt == this.completedAt &&
          other.totalQuestions == this.totalQuestions &&
          other.correctCount == this.correctCount &&
          other.wrongCount == this.wrongCount &&
          other.score == this.score &&
          other.maxScore == this.maxScore &&
          other.resultsJson == this.resultsJson &&
          other.isSynced == this.isSynced);
}

class DailyPlanDaysTableCompanion
    extends UpdateCompanion<DailyPlanDaysTableData> {
  final Value<int> id;
  final Value<int> dailyQuizPlanId;
  final Value<int> dayNumber;
  final Value<DateTime> completedAt;
  final Value<int> totalQuestions;
  final Value<int> correctCount;
  final Value<int> wrongCount;
  final Value<int> score;
  final Value<int> maxScore;
  final Value<String> resultsJson;
  final Value<bool> isSynced;
  const DailyPlanDaysTableCompanion({
    this.id = const Value.absent(),
    this.dailyQuizPlanId = const Value.absent(),
    this.dayNumber = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.totalQuestions = const Value.absent(),
    this.correctCount = const Value.absent(),
    this.wrongCount = const Value.absent(),
    this.score = const Value.absent(),
    this.maxScore = const Value.absent(),
    this.resultsJson = const Value.absent(),
    this.isSynced = const Value.absent(),
  });
  DailyPlanDaysTableCompanion.insert({
    this.id = const Value.absent(),
    required int dailyQuizPlanId,
    required int dayNumber,
    required DateTime completedAt,
    required int totalQuestions,
    required int correctCount,
    required int wrongCount,
    required int score,
    required int maxScore,
    required String resultsJson,
    this.isSynced = const Value.absent(),
  }) : dailyQuizPlanId = Value(dailyQuizPlanId),
       dayNumber = Value(dayNumber),
       completedAt = Value(completedAt),
       totalQuestions = Value(totalQuestions),
       correctCount = Value(correctCount),
       wrongCount = Value(wrongCount),
       score = Value(score),
       maxScore = Value(maxScore),
       resultsJson = Value(resultsJson);
  static Insertable<DailyPlanDaysTableData> custom({
    Expression<int>? id,
    Expression<int>? dailyQuizPlanId,
    Expression<int>? dayNumber,
    Expression<DateTime>? completedAt,
    Expression<int>? totalQuestions,
    Expression<int>? correctCount,
    Expression<int>? wrongCount,
    Expression<int>? score,
    Expression<int>? maxScore,
    Expression<String>? resultsJson,
    Expression<bool>? isSynced,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dailyQuizPlanId != null) 'daily_quiz_plan_id': dailyQuizPlanId,
      if (dayNumber != null) 'day_number': dayNumber,
      if (completedAt != null) 'completed_at': completedAt,
      if (totalQuestions != null) 'total_questions': totalQuestions,
      if (correctCount != null) 'correct_count': correctCount,
      if (wrongCount != null) 'wrong_count': wrongCount,
      if (score != null) 'score': score,
      if (maxScore != null) 'max_score': maxScore,
      if (resultsJson != null) 'results_json': resultsJson,
      if (isSynced != null) 'is_synced': isSynced,
    });
  }

  DailyPlanDaysTableCompanion copyWith({
    Value<int>? id,
    Value<int>? dailyQuizPlanId,
    Value<int>? dayNumber,
    Value<DateTime>? completedAt,
    Value<int>? totalQuestions,
    Value<int>? correctCount,
    Value<int>? wrongCount,
    Value<int>? score,
    Value<int>? maxScore,
    Value<String>? resultsJson,
    Value<bool>? isSynced,
  }) {
    return DailyPlanDaysTableCompanion(
      id: id ?? this.id,
      dailyQuizPlanId: dailyQuizPlanId ?? this.dailyQuizPlanId,
      dayNumber: dayNumber ?? this.dayNumber,
      completedAt: completedAt ?? this.completedAt,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      correctCount: correctCount ?? this.correctCount,
      wrongCount: wrongCount ?? this.wrongCount,
      score: score ?? this.score,
      maxScore: maxScore ?? this.maxScore,
      resultsJson: resultsJson ?? this.resultsJson,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (dailyQuizPlanId.present) {
      map['daily_quiz_plan_id'] = Variable<int>(dailyQuizPlanId.value);
    }
    if (dayNumber.present) {
      map['day_number'] = Variable<int>(dayNumber.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (totalQuestions.present) {
      map['total_questions'] = Variable<int>(totalQuestions.value);
    }
    if (correctCount.present) {
      map['correct_count'] = Variable<int>(correctCount.value);
    }
    if (wrongCount.present) {
      map['wrong_count'] = Variable<int>(wrongCount.value);
    }
    if (score.present) {
      map['score'] = Variable<int>(score.value);
    }
    if (maxScore.present) {
      map['max_score'] = Variable<int>(maxScore.value);
    }
    if (resultsJson.present) {
      map['results_json'] = Variable<String>(resultsJson.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyPlanDaysTableCompanion(')
          ..write('id: $id, ')
          ..write('dailyQuizPlanId: $dailyQuizPlanId, ')
          ..write('dayNumber: $dayNumber, ')
          ..write('completedAt: $completedAt, ')
          ..write('totalQuestions: $totalQuestions, ')
          ..write('correctCount: $correctCount, ')
          ..write('wrongCount: $wrongCount, ')
          ..write('score: $score, ')
          ..write('maxScore: $maxScore, ')
          ..write('resultsJson: $resultsJson, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTableTable extends SyncQueueTable
    with TableInfo<$SyncQueueTableTable, SyncQueueTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _actionTypeMeta = const VerificationMeta(
    'actionType',
  );
  @override
  late final GeneratedColumn<String> actionType = GeneratedColumn<String>(
    'action_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    actionType,
    payloadJson,
    createdAt,
    retryCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncQueueTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('action_type')) {
      context.handle(
        _actionTypeMeta,
        actionType.isAcceptableOrUnknown(data['action_type']!, _actionTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_actionTypeMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      actionType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action_type'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
    );
  }

  @override
  $SyncQueueTableTable createAlias(String alias) {
    return $SyncQueueTableTable(attachedDatabase, alias);
  }
}

class SyncQueueTableData extends DataClass
    implements Insertable<SyncQueueTableData> {
  final int id;
  final String actionType;
  final String payloadJson;
  final DateTime createdAt;
  final int retryCount;
  const SyncQueueTableData({
    required this.id,
    required this.actionType,
    required this.payloadJson,
    required this.createdAt,
    required this.retryCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['action_type'] = Variable<String>(actionType);
    map['payload_json'] = Variable<String>(payloadJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['retry_count'] = Variable<int>(retryCount);
    return map;
  }

  SyncQueueTableCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueTableCompanion(
      id: Value(id),
      actionType: Value(actionType),
      payloadJson: Value(payloadJson),
      createdAt: Value(createdAt),
      retryCount: Value(retryCount),
    );
  }

  factory SyncQueueTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueTableData(
      id: serializer.fromJson<int>(json['id']),
      actionType: serializer.fromJson<String>(json['actionType']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'actionType': serializer.toJson<String>(actionType),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'retryCount': serializer.toJson<int>(retryCount),
    };
  }

  SyncQueueTableData copyWith({
    int? id,
    String? actionType,
    String? payloadJson,
    DateTime? createdAt,
    int? retryCount,
  }) => SyncQueueTableData(
    id: id ?? this.id,
    actionType: actionType ?? this.actionType,
    payloadJson: payloadJson ?? this.payloadJson,
    createdAt: createdAt ?? this.createdAt,
    retryCount: retryCount ?? this.retryCount,
  );
  SyncQueueTableData copyWithCompanion(SyncQueueTableCompanion data) {
    return SyncQueueTableData(
      id: data.id.present ? data.id.value : this.id,
      actionType: data.actionType.present
          ? data.actionType.value
          : this.actionType,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueTableData(')
          ..write('id: $id, ')
          ..write('actionType: $actionType, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, actionType, payloadJson, createdAt, retryCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueTableData &&
          other.id == this.id &&
          other.actionType == this.actionType &&
          other.payloadJson == this.payloadJson &&
          other.createdAt == this.createdAt &&
          other.retryCount == this.retryCount);
}

class SyncQueueTableCompanion extends UpdateCompanion<SyncQueueTableData> {
  final Value<int> id;
  final Value<String> actionType;
  final Value<String> payloadJson;
  final Value<DateTime> createdAt;
  final Value<int> retryCount;
  const SyncQueueTableCompanion({
    this.id = const Value.absent(),
    this.actionType = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.retryCount = const Value.absent(),
  });
  SyncQueueTableCompanion.insert({
    this.id = const Value.absent(),
    required String actionType,
    required String payloadJson,
    this.createdAt = const Value.absent(),
    this.retryCount = const Value.absent(),
  }) : actionType = Value(actionType),
       payloadJson = Value(payloadJson);
  static Insertable<SyncQueueTableData> custom({
    Expression<int>? id,
    Expression<String>? actionType,
    Expression<String>? payloadJson,
    Expression<DateTime>? createdAt,
    Expression<int>? retryCount,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (actionType != null) 'action_type': actionType,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (createdAt != null) 'created_at': createdAt,
      if (retryCount != null) 'retry_count': retryCount,
    });
  }

  SyncQueueTableCompanion copyWith({
    Value<int>? id,
    Value<String>? actionType,
    Value<String>? payloadJson,
    Value<DateTime>? createdAt,
    Value<int>? retryCount,
  }) {
    return SyncQueueTableCompanion(
      id: id ?? this.id,
      actionType: actionType ?? this.actionType,
      payloadJson: payloadJson ?? this.payloadJson,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (actionType.present) {
      map['action_type'] = Variable<String>(actionType.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueTableCompanion(')
          ..write('id: $id, ')
          ..write('actionType: $actionType, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $WordsTableTable wordsTable = $WordsTableTable(this);
  late final $DailyPlansTableTable dailyPlansTable = $DailyPlansTableTable(
    this,
  );
  late final $DailyPlanDaysTableTable dailyPlanDaysTable =
      $DailyPlanDaysTableTable(this);
  late final $SyncQueueTableTable syncQueueTable = $SyncQueueTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    wordsTable,
    dailyPlansTable,
    dailyPlanDaysTable,
    syncQueueTable,
  ];
}

typedef $$WordsTableTableCreateCompanionBuilder = WordsTableCompanion Function({
  Value<int> id,
  required String en,
  required String tr,
  Value<String?> example,
  required String listName,
  Value<int?> userId,
  Value<bool> isSynced,
  Value<DateTime> updatedAt,
});
typedef $$WordsTableTableUpdateCompanionBuilder = WordsTableCompanion Function({
  Value<int> id,
  Value<String> en,
  Value<String> tr,
  Value<String?> example,
  Value<String> listName,
  Value<int?> userId,
  Value<bool> isSynced,
  Value<DateTime> updatedAt,
});

class $$WordsTableTableFilterComposer
    extends Composer<_$AppDatabase, $WordsTableTable> {
  $$WordsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get en => $composableBuilder(
    column: $table.en,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tr => $composableBuilder(
    column: $table.tr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get example => $composableBuilder(
    column: $table.example,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get listName => $composableBuilder(
    column: $table.listName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WordsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $WordsTableTable> {
  $$WordsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get en => $composableBuilder(
    column: $table.en,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tr => $composableBuilder(
    column: $table.tr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get example => $composableBuilder(
    column: $table.example,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get listName => $composableBuilder(
    column: $table.listName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WordsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $WordsTableTable> {
  $$WordsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get en =>
      $composableBuilder(column: $table.en, builder: (column) => column);

  GeneratedColumn<String> get tr =>
      $composableBuilder(column: $table.tr, builder: (column) => column);

  GeneratedColumn<String> get example =>
      $composableBuilder(column: $table.example, builder: (column) => column);

  GeneratedColumn<String> get listName =>
      $composableBuilder(column: $table.listName, builder: (column) => column);

  GeneratedColumn<int> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$WordsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WordsTableTable,
          WordsTableData,
          $$WordsTableTableFilterComposer,
          $$WordsTableTableOrderingComposer,
          $$WordsTableTableAnnotationComposer,
          $$WordsTableTableCreateCompanionBuilder,
          $$WordsTableTableUpdateCompanionBuilder,
          (
            WordsTableData,
            BaseReferences<_$AppDatabase, $WordsTableTable, WordsTableData>,
          ),
          WordsTableData,
          PrefetchHooks Function()
        > {
  $$WordsTableTableTableManager(_$AppDatabase db, $WordsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WordsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WordsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WordsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> en = const Value.absent(),
                Value<String> tr = const Value.absent(),
                Value<String?> example = const Value.absent(),
                Value<String> listName = const Value.absent(),
                Value<int?> userId = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => WordsTableCompanion(
                id: id,
                en: en,
                tr: tr,
                example: example,
                listName: listName,
                userId: userId,
                isSynced: isSynced,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String en,
                required String tr,
                Value<String?> example = const Value.absent(),
                required String listName,
                Value<int?> userId = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => WordsTableCompanion.insert(
                id: id,
                en: en,
                tr: tr,
                example: example,
                listName: listName,
                userId: userId,
                isSynced: isSynced,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WordsTableTable, WordsTableData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $WordsTableTable,
                    WordsTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WordsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WordsTableTable,
      WordsTableData,
      $$WordsTableTableFilterComposer,
      $$WordsTableTableOrderingComposer,
      $$WordsTableTableAnnotationComposer,
      $$WordsTableTableCreateCompanionBuilder,
      $$WordsTableTableUpdateCompanionBuilder,
      (
        WordsTableData,
        BaseReferences<_$AppDatabase, $WordsTableTable, WordsTableData>,
      ),
      WordsTableData,
      PrefetchHooks Function()
    >;
typedef $$DailyPlansTableTableCreateCompanionBuilder =
    DailyPlansTableCompanion Function({
      required String id,
      required String listName,
      required int dailyCount,
      required String shuffledWordIdsJson,
      Value<int> currentPointer,
      Value<int> streakDays,
      Value<String?> lastCompletedDate,
      Value<bool> isEnglishToTurkish,
      Value<bool> isActive,
      Value<bool> isSynced,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$DailyPlansTableTableUpdateCompanionBuilder =
    DailyPlansTableCompanion Function({
      Value<String> id,
      Value<String> listName,
      Value<int> dailyCount,
      Value<String> shuffledWordIdsJson,
      Value<int> currentPointer,
      Value<int> streakDays,
      Value<String?> lastCompletedDate,
      Value<bool> isEnglishToTurkish,
      Value<bool> isActive,
      Value<bool> isSynced,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$DailyPlansTableTableFilterComposer
    extends Composer<_$AppDatabase, $DailyPlansTableTable> {
  $$DailyPlansTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get listName => $composableBuilder(
    column: $table.listName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dailyCount => $composableBuilder(
    column: $table.dailyCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shuffledWordIdsJson => $composableBuilder(
    column: $table.shuffledWordIdsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentPointer => $composableBuilder(
    column: $table.currentPointer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get streakDays => $composableBuilder(
    column: $table.streakDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastCompletedDate => $composableBuilder(
    column: $table.lastCompletedDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isEnglishToTurkish => $composableBuilder(
    column: $table.isEnglishToTurkish,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DailyPlansTableTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyPlansTableTable> {
  $$DailyPlansTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get listName => $composableBuilder(
    column: $table.listName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dailyCount => $composableBuilder(
    column: $table.dailyCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shuffledWordIdsJson => $composableBuilder(
    column: $table.shuffledWordIdsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentPointer => $composableBuilder(
    column: $table.currentPointer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get streakDays => $composableBuilder(
    column: $table.streakDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastCompletedDate => $composableBuilder(
    column: $table.lastCompletedDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isEnglishToTurkish => $composableBuilder(
    column: $table.isEnglishToTurkish,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DailyPlansTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyPlansTableTable> {
  $$DailyPlansTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get listName =>
      $composableBuilder(column: $table.listName, builder: (column) => column);

  GeneratedColumn<int> get dailyCount => $composableBuilder(
    column: $table.dailyCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get shuffledWordIdsJson => $composableBuilder(
    column: $table.shuffledWordIdsJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get currentPointer => $composableBuilder(
    column: $table.currentPointer,
    builder: (column) => column,
  );

  GeneratedColumn<int> get streakDays => $composableBuilder(
    column: $table.streakDays,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastCompletedDate => $composableBuilder(
    column: $table.lastCompletedDate,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isEnglishToTurkish => $composableBuilder(
    column: $table.isEnglishToTurkish,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$DailyPlansTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DailyPlansTableTable,
          DailyPlansTableData,
          $$DailyPlansTableTableFilterComposer,
          $$DailyPlansTableTableOrderingComposer,
          $$DailyPlansTableTableAnnotationComposer,
          $$DailyPlansTableTableCreateCompanionBuilder,
          $$DailyPlansTableTableUpdateCompanionBuilder,
          (
            DailyPlansTableData,
            BaseReferences<
              _$AppDatabase,
              $DailyPlansTableTable,
              DailyPlansTableData
            >,
          ),
          DailyPlansTableData,
          PrefetchHooks Function()
        > {
  $$DailyPlansTableTableTableManager(
    _$AppDatabase db,
    $DailyPlansTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyPlansTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyPlansTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyPlansTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> listName = const Value.absent(),
                Value<int> dailyCount = const Value.absent(),
                Value<String> shuffledWordIdsJson = const Value.absent(),
                Value<int> currentPointer = const Value.absent(),
                Value<int> streakDays = const Value.absent(),
                Value<String?> lastCompletedDate = const Value.absent(),
                Value<bool> isEnglishToTurkish = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyPlansTableCompanion(
                id: id,
                listName: listName,
                dailyCount: dailyCount,
                shuffledWordIdsJson: shuffledWordIdsJson,
                currentPointer: currentPointer,
                streakDays: streakDays,
                lastCompletedDate: lastCompletedDate,
                isEnglishToTurkish: isEnglishToTurkish,
                isActive: isActive,
                isSynced: isSynced,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String listName,
                required int dailyCount,
                required String shuffledWordIdsJson,
                Value<int> currentPointer = const Value.absent(),
                Value<int> streakDays = const Value.absent(),
                Value<String?> lastCompletedDate = const Value.absent(),
                Value<bool> isEnglishToTurkish = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyPlansTableCompanion.insert(
                id: id,
                listName: listName,
                dailyCount: dailyCount,
                shuffledWordIdsJson: shuffledWordIdsJson,
                currentPointer: currentPointer,
                streakDays: streakDays,
                lastCompletedDate: lastCompletedDate,
                isEnglishToTurkish: isEnglishToTurkish,
                isActive: isActive,
                isSynced: isSynced,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DailyPlansTableTable, DailyPlansTableData>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $DailyPlansTableTable,
                    DailyPlansTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DailyPlansTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DailyPlansTableTable,
      DailyPlansTableData,
      $$DailyPlansTableTableFilterComposer,
      $$DailyPlansTableTableOrderingComposer,
      $$DailyPlansTableTableAnnotationComposer,
      $$DailyPlansTableTableCreateCompanionBuilder,
      $$DailyPlansTableTableUpdateCompanionBuilder,
      (
        DailyPlansTableData,
        BaseReferences<
          _$AppDatabase,
          $DailyPlansTableTable,
          DailyPlansTableData
        >,
      ),
      DailyPlansTableData,
      PrefetchHooks Function()
    >;
typedef $$DailyPlanDaysTableTableCreateCompanionBuilder =
    DailyPlanDaysTableCompanion Function({
      Value<int> id,
      required int dailyQuizPlanId,
      required int dayNumber,
      required DateTime completedAt,
      required int totalQuestions,
      required int correctCount,
      required int wrongCount,
      required int score,
      required int maxScore,
      required String resultsJson,
      Value<bool> isSynced,
    });
typedef $$DailyPlanDaysTableTableUpdateCompanionBuilder =
    DailyPlanDaysTableCompanion Function({
      Value<int> id,
      Value<int> dailyQuizPlanId,
      Value<int> dayNumber,
      Value<DateTime> completedAt,
      Value<int> totalQuestions,
      Value<int> correctCount,
      Value<int> wrongCount,
      Value<int> score,
      Value<int> maxScore,
      Value<String> resultsJson,
      Value<bool> isSynced,
    });

class $$DailyPlanDaysTableTableFilterComposer
    extends Composer<_$AppDatabase, $DailyPlanDaysTableTable> {
  $$DailyPlanDaysTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dailyQuizPlanId => $composableBuilder(
    column: $table.dailyQuizPlanId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dayNumber => $composableBuilder(
    column: $table.dayNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalQuestions => $composableBuilder(
    column: $table.totalQuestions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get correctCount => $composableBuilder(
    column: $table.correctCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wrongCount => $composableBuilder(
    column: $table.wrongCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxScore => $composableBuilder(
    column: $table.maxScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resultsJson => $composableBuilder(
    column: $table.resultsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DailyPlanDaysTableTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyPlanDaysTableTable> {
  $$DailyPlanDaysTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dailyQuizPlanId => $composableBuilder(
    column: $table.dailyQuizPlanId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dayNumber => $composableBuilder(
    column: $table.dayNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalQuestions => $composableBuilder(
    column: $table.totalQuestions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get correctCount => $composableBuilder(
    column: $table.correctCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wrongCount => $composableBuilder(
    column: $table.wrongCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxScore => $composableBuilder(
    column: $table.maxScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resultsJson => $composableBuilder(
    column: $table.resultsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DailyPlanDaysTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyPlanDaysTableTable> {
  $$DailyPlanDaysTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get dailyQuizPlanId => $composableBuilder(
    column: $table.dailyQuizPlanId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dayNumber =>
      $composableBuilder(column: $table.dayNumber, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalQuestions => $composableBuilder(
    column: $table.totalQuestions,
    builder: (column) => column,
  );

  GeneratedColumn<int> get correctCount => $composableBuilder(
    column: $table.correctCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get wrongCount => $composableBuilder(
    column: $table.wrongCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<int> get maxScore =>
      $composableBuilder(column: $table.maxScore, builder: (column) => column);

  GeneratedColumn<String> get resultsJson => $composableBuilder(
    column: $table.resultsJson,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);
}

class $$DailyPlanDaysTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DailyPlanDaysTableTable,
          DailyPlanDaysTableData,
          $$DailyPlanDaysTableTableFilterComposer,
          $$DailyPlanDaysTableTableOrderingComposer,
          $$DailyPlanDaysTableTableAnnotationComposer,
          $$DailyPlanDaysTableTableCreateCompanionBuilder,
          $$DailyPlanDaysTableTableUpdateCompanionBuilder,
          (
            DailyPlanDaysTableData,
            BaseReferences<
              _$AppDatabase,
              $DailyPlanDaysTableTable,
              DailyPlanDaysTableData
            >,
          ),
          DailyPlanDaysTableData,
          PrefetchHooks Function()
        > {
  $$DailyPlanDaysTableTableTableManager(
    _$AppDatabase db,
    $DailyPlanDaysTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyPlanDaysTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyPlanDaysTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyPlanDaysTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> dailyQuizPlanId = const Value.absent(),
                Value<int> dayNumber = const Value.absent(),
                Value<DateTime> completedAt = const Value.absent(),
                Value<int> totalQuestions = const Value.absent(),
                Value<int> correctCount = const Value.absent(),
                Value<int> wrongCount = const Value.absent(),
                Value<int> score = const Value.absent(),
                Value<int> maxScore = const Value.absent(),
                Value<String> resultsJson = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
              }) => DailyPlanDaysTableCompanion(
                id: id,
                dailyQuizPlanId: dailyQuizPlanId,
                dayNumber: dayNumber,
                completedAt: completedAt,
                totalQuestions: totalQuestions,
                correctCount: correctCount,
                wrongCount: wrongCount,
                score: score,
                maxScore: maxScore,
                resultsJson: resultsJson,
                isSynced: isSynced,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int dailyQuizPlanId,
                required int dayNumber,
                required DateTime completedAt,
                required int totalQuestions,
                required int correctCount,
                required int wrongCount,
                required int score,
                required int maxScore,
                required String resultsJson,
                Value<bool> isSynced = const Value.absent(),
              }) => DailyPlanDaysTableCompanion.insert(
                id: id,
                dailyQuizPlanId: dailyQuizPlanId,
                dayNumber: dayNumber,
                completedAt: completedAt,
                totalQuestions: totalQuestions,
                correctCount: correctCount,
                wrongCount: wrongCount,
                score: score,
                maxScore: maxScore,
                resultsJson: resultsJson,
                isSynced: isSynced,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DailyPlanDaysTableTable, DailyPlanDaysTableData>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $DailyPlanDaysTableTable,
                    DailyPlanDaysTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DailyPlanDaysTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DailyPlanDaysTableTable,
      DailyPlanDaysTableData,
      $$DailyPlanDaysTableTableFilterComposer,
      $$DailyPlanDaysTableTableOrderingComposer,
      $$DailyPlanDaysTableTableAnnotationComposer,
      $$DailyPlanDaysTableTableCreateCompanionBuilder,
      $$DailyPlanDaysTableTableUpdateCompanionBuilder,
      (
        DailyPlanDaysTableData,
        BaseReferences<
          _$AppDatabase,
          $DailyPlanDaysTableTable,
          DailyPlanDaysTableData
        >,
      ),
      DailyPlanDaysTableData,
      PrefetchHooks Function()
    >;
typedef $$SyncQueueTableTableCreateCompanionBuilder =
    SyncQueueTableCompanion Function({
      Value<int> id,
      required String actionType,
      required String payloadJson,
      Value<DateTime> createdAt,
      Value<int> retryCount,
    });
typedef $$SyncQueueTableTableUpdateCompanionBuilder =
    SyncQueueTableCompanion Function({
      Value<int> id,
      Value<String> actionType,
      Value<String> payloadJson,
      Value<DateTime> createdAt,
      Value<int> retryCount,
    });

class $$SyncQueueTableTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueTableTable> {
  $$SyncQueueTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actionType => $composableBuilder(
    column: $table.actionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncQueueTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueTableTable> {
  $$SyncQueueTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actionType => $composableBuilder(
    column: $table.actionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncQueueTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueTableTable> {
  $$SyncQueueTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get actionType => $composableBuilder(
    column: $table.actionType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );
}

class $$SyncQueueTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncQueueTableTable,
          SyncQueueTableData,
          $$SyncQueueTableTableFilterComposer,
          $$SyncQueueTableTableOrderingComposer,
          $$SyncQueueTableTableAnnotationComposer,
          $$SyncQueueTableTableCreateCompanionBuilder,
          $$SyncQueueTableTableUpdateCompanionBuilder,
          (
            SyncQueueTableData,
            BaseReferences<
              _$AppDatabase,
              $SyncQueueTableTable,
              SyncQueueTableData
            >,
          ),
          SyncQueueTableData,
          PrefetchHooks Function()
        > {
  $$SyncQueueTableTableTableManager(
    _$AppDatabase db,
    $SyncQueueTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> actionType = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
              }) => SyncQueueTableCompanion(
                id: id,
                actionType: actionType,
                payloadJson: payloadJson,
                createdAt: createdAt,
                retryCount: retryCount,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String actionType,
                required String payloadJson,
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
              }) => SyncQueueTableCompanion.insert(
                id: id,
                actionType: actionType,
                payloadJson: payloadJson,
                createdAt: createdAt,
                retryCount: retryCount,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncQueueTableTable, SyncQueueTableData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SyncQueueTableTable,
                    SyncQueueTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncQueueTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncQueueTableTable,
      SyncQueueTableData,
      $$SyncQueueTableTableFilterComposer,
      $$SyncQueueTableTableOrderingComposer,
      $$SyncQueueTableTableAnnotationComposer,
      $$SyncQueueTableTableCreateCompanionBuilder,
      $$SyncQueueTableTableUpdateCompanionBuilder,
      (
        SyncQueueTableData,
        BaseReferences<_$AppDatabase, $SyncQueueTableTable, SyncQueueTableData>,
      ),
      SyncQueueTableData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$WordsTableTableTableManager get wordsTable =>
      $$WordsTableTableTableManager(_db, _db.wordsTable);
  $$DailyPlansTableTableTableManager get dailyPlansTable =>
      $$DailyPlansTableTableTableManager(_db, _db.dailyPlansTable);
  $$DailyPlanDaysTableTableTableManager get dailyPlanDaysTable =>
      $$DailyPlanDaysTableTableTableManager(_db, _db.dailyPlanDaysTable);
  $$SyncQueueTableTableTableManager get syncQueueTable =>
      $$SyncQueueTableTableTableManager(_db, _db.syncQueueTable);
}
