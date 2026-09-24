import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wordstation_flutter/core/storage/secure_storage_service.dart';
import 'package:wordstation_flutter/features/words/controllers/word_list_controller.dart';
import 'package:wordstation_flutter/features/words/models/word_model.dart';
import 'package:wordstation_flutter/features/words/repositories/word_repository.dart';
import 'package:wordstation_flutter/features/words/services/word_service.dart';
import '../../helpers/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  group('WordModel - Serialization & Deserialization', () {
    test('Standard camelCase json parsing and serialization', () {
      final json = {
        'id': 1,
        'en': 'ubiquitous',
        'tr': 'her yerde bulunan',
        'example': 'Smartphones are ubiquitous.',
        'listName': 'Advanced',
        'userId': 'usr_1',
      };

      final word = WordModel.fromJson(json);
      expect(word.id, 1);
      expect(word.en, 'ubiquitous');
      expect(word.tr, 'her yerde bulunan');
      expect(word.example, 'Smartphones are ubiquitous.');
      expect(word.listName, 'Advanced');

      final serialized = word.toJson();
      expect(serialized['en'], 'ubiquitous');
      expect(serialized['tr'], 'her yerde bulunan');
      expect(serialized['listName'], 'Advanced');
    });

    test('PascalCase backend casing tolerance', () {
      final backendJson = {
        'Id': 10,
        'English': 'abandon',
        'Turkish': 'terk etmek',
        'Sentence': 'He abandoned the car.',
        'Category': 'B2',
      };

      final word = WordModel.fromJson(backendJson);
      expect(word.id, 10);
      expect(word.en, 'abandon');
      expect(word.tr, 'terk etmek');
      expect(word.example, 'He abandoned the car.');
      expect(word.listName, 'B2');
    });
  });

  group('Word CRUD - API & Repository Operations', () {
    late SecureStorageService storage;

    setUp(() async {
      storage = SecureStorageService();
      await storage.clearAll();
      await storage.saveTokens(
        accessToken: 'mock_token',
        refreshToken: 'mock_refresh',
        userId: 'usr_test_1',
        email: 'test@wordstation.com',
      );
    });

    test('getWords fetches list from API and parses models', () async {
      final mockClient = createMockApiClient((options) {
        if (options.path.contains('/words') && options.method == 'GET') {
          return Response(
            requestOptions: options,
            statusCode: 200,
            data: [
              {'id': 1, 'en': 'meticulous', 'tr': 'titiz', 'listName': 'YDS'},
              {'id': 2, 'en': 'diligent', 'tr': 'çalışkan', 'listName': 'YDS'},
            ],
          );
        }
        return Response(requestOptions: options, statusCode: 404);
      });

      final service = WordService(mockClient, storage);
      final repo = WordRepositoryImpl(wordService: service);

      final words = await repo.getWords();
      expect(words.length, 2);
      expect(words.first.en, 'meticulous');
      expect(words.first.tr, 'titiz');
      expect(words.last.en, 'diligent');
    });

    test('createWord sends POST and returns newly created word', () async {
      final mockClient = createMockApiClient((options) {
        if (options.path.contains('/words') && options.method == 'POST') {
          final data = options.data as Map<String, dynamic>;
          return Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'id': 101,
              'en': data['En'],
              'tr': data['Tr'],
              'example': data['Example'],
              'listName': data['ListName'],
            },
          );
        }
        return Response(requestOptions: options, statusCode: 404);
      });

      final service = WordService(mockClient, storage);
      final repo = WordRepositoryImpl(wordService: service);

      final created = await repo.createWord(
        en: 'tenacious',
        tr: 'inatçı',
        example: 'A tenacious leader.',
        listName: 'Advanced',
      );

      expect(created, isNotNull);
      expect(created!.id, 101);
      expect(created.en, 'tenacious');
      expect(created.tr, 'inatçı');
    });

    test('updateWord sends PUT and returns updated word', () async {
      final mockClient = createMockApiClient((options) {
        if (options.path.contains('/words') && options.method == 'PUT') {
          final data = options.data as Map<String, dynamic>;
          return Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'id': data['Id'],
              'en': data['En'],
              'tr': data['Tr'],
              'example': data['Example'],
              'listName': data['ListName'],
            },
          );
        }
        return Response(requestOptions: options, statusCode: 404);
      });

      final service = WordService(mockClient, storage);
      final repo = WordRepositoryImpl(wordService: service);

      final updated = await repo.updateWord(
        id: 101,
        en: 'tenacious (updated)',
        tr: 'azimkar, inatçı',
        example: 'Very tenacious.',
        listName: 'Advanced',
      );

      expect(updated, isNotNull);
      expect(updated!.id, 101);
      expect(updated.en, 'tenacious (updated)');
      expect(updated.tr, 'azimkar, inatçı');
    });

    test('deleteWord sends DELETE and returns true on success', () async {
      final mockClient = createMockApiClient((options) {
        if (options.method == 'DELETE') {
          return Response(requestOptions: options, statusCode: 200, data: true);
        }
        return Response(requestOptions: options, statusCode: 404);
      });

      final service = WordService(mockClient, storage);
      final repo = WordRepositoryImpl(wordService: service);

      final success = await repo.deleteWord(101);
      expect(success, isTrue);
    });

    test('renameList and deleteList API calls succeed', () async {
      final mockClient = createMockApiClient((options) {
        return Response(requestOptions: options, statusCode: 200);
      });

      final service = WordService(mockClient, storage);
      final repo = WordRepositoryImpl(wordService: service);

      final renameSuccess = await repo.renameList('OldList', 'NewList');
      expect(renameSuccess, isTrue);

      final deleteSuccess = await repo.deleteList('NewList');
      expect(deleteSuccess, isTrue);
    });
  });

  group('Word List Custom Ordering Logic', () {
    test('applyListOrder sorts alphabetically if saved order is empty', () {
      final raw = ['General', 'YDS', 'B2', 'A1'];
      final sorted = WordListController.applyListOrder(raw, []);
      expect(sorted, ['A1', 'B2', 'General', 'YDS']);
    });

    test('applyListOrder prioritizes saved order and appends remaining lists alphabetically', () {
      final raw = ['General', 'YDS', 'B2', 'A1'];
      final savedOrder = ['YDS', 'B2'];
      final sorted = WordListController.applyListOrder(raw, savedOrder);
      expect(sorted, ['YDS', 'B2', 'A1', 'General']);
    });

    test('WordListController reorderLists updates state and persists order', () async {
      final storage = SecureStorageService();
      await storage.clearCustomListOrder();

      final mockWords = [
        const WordModel(id: 1, en: 'apple', tr: 'elma', listName: 'General'),
        const WordModel(id: 2, en: 'ubiquitous', tr: 'yaygın', listName: 'YDS'),
        const WordModel(id: 3, en: 'elaborate', tr: 'ayrıntılı', listName: 'B2'),
      ];

      final fakeRepo = _InMemoryWordRepository(mockWords);
      final controller = WordListController(fakeRepo, storageService: storage);

      // Wait for initial load
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(controller.state.listNames, ['B2', 'General', 'YDS']);

      // Reorder: Move 'YDS' (index 2) to top (index 0)
      await controller.reorderLists(2, 0);

      expect(controller.state.listNames, ['YDS', 'B2', 'General']);
      expect(controller.state.listNames.first, 'YDS');

      final persisted = await storage.getCustomListOrder();
      expect(persisted, ['YDS', 'B2', 'General']);
    });
  });
}

class _InMemoryWordRepository implements IWordRepository {
  final List<WordModel> words;
  _InMemoryWordRepository(this.words);

  @override
  Future<List<WordModel>> getWords({String? listName, bool forceRefresh = false}) async {
    if (listName != null) {
      return words.where((w) => w.listName == listName).toList();
    }
    return words;
  }

  @override
  Future<WordModel?> createWord({
    required String en,
    required String tr,
    String? example,
    required String listName,
  }) async {
    final newWord = WordModel(id: words.length + 1, en: en, tr: tr, example: example, listName: listName);
    words.add(newWord);
    return newWord;
  }

  @override
  Future<WordModel?> updateWord({
    required int id,
    required String en,
    required String tr,
    String? example,
    required String listName,
  }) async => null;

  @override
  Future<bool> deleteWord(int id) async => true;

  @override
  Future<bool> createList(String listName) async => true;

  @override
  Future<bool> renameList(String oldName, String newName) async => true;

  @override
  Future<bool> deleteList(String listName) async => true;
}
