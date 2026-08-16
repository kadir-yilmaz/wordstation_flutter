import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../models/synonym_group_model.dart';
import '../models/word_model.dart';

final wordServiceProvider = Provider<WordService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final storage = ref.watch(secureStorageServiceProvider);
  return WordService(apiClient, storage);
});

class WordService {
  final ApiClient _apiClient;
  final SecureStorageService _storage;

  WordService(this._apiClient, this._storage);

  List<dynamic> _extractList(dynamic data) {
    if (data == null) return [];
    if (data is List) return data;
    if (data is Map) {
      final possibleKeys = [
        'data',
        'items',
        'words',
        'lists',
        'result',
        'results',
        'value',
        'values',
        'list',
        'groups',
      ];
      for (final key in possibleKeys) {
        if (data.containsKey(key) && data[key] is List) {
          return data[key] as List;
        }
      }
      for (final entry in data.entries) {
        if (entry.value is List) {
          return entry.value as List;
        }
      }
    }
    return [];
  }

  // Get words (fetches user's all words or specific list words)
  Future<List<WordModel>> getWords({String? listName}) async {
    try {
      final userId = await _storage.getUserId();
      if (userId == null || userId.isEmpty) {
        log('WordService.getWords: No userId available in storage.');
        return [];
      }

      Response response;
      if (listName == null ||
          listName.isEmpty ||
          listName == 'All' ||
          listName == 'Tümü' ||
          listName == 'My Lists') {
        // Fetch all words for this user
        log('WordService.getWords: Fetching all words for user: $userId (/api/words/user/$userId)');
        response = await _apiClient.get(ApiConstants.wordsByUserId(userId));
      } else {
        // Fetch words for a specific list
        log('WordService.getWords: Fetching words for list "$listName" with userId: $userId');
        response = await _apiClient.get(
          ApiConstants.words,
          queryParameters: {
            'userId': userId,
            'listName': listName,
          },
        );
      }

      final rawList = _extractList(response.data);
      log('WordService.getWords: Received ${rawList.length} words from API.');

      return rawList.map((item) {
        if (item is Map<String, dynamic>) {
          return WordModel.fromJson(item);
        } else if (item is Map) {
          return WordModel.fromJson(Map<String, dynamic>.from(item));
        } else {
          return WordModel(en: item.toString(), tr: '');
        }
      }).where((w) => w.en.isNotEmpty || w.tr.isNotEmpty).toList();
    } on DioException catch (e) {
      log('WordService.getWords DioException: ${e.response?.statusCode} -> ${e.response?.data}');
      throw Exception(_extractErrorMessage(e));
    }
  }

  // Get list of category / list names
  Future<List<String>> getListNames() async {
    try {
      final userId = await _storage.getUserId();
      if (userId == null || userId.isEmpty) return [];

      log('WordService.getListNames: Fetching list names for userId: $userId');
      final response = await _apiClient.get(
        ApiConstants.lists,
        queryParameters: {'userId': userId},
      );

      final rawList = _extractList(response.data);

      final lists = rawList
          .map((item) {
            if (item is Map) {
              return (item['name'] ??
                      item['Name'] ??
                      item['listName'] ??
                      item['ListName'] ??
                      item['title'] ??
                      item['Title'] ??
                      item['category'] ??
                      item['Category'] ??
                      '')
                  .toString()
                  .trim();
            }
            return item.toString().trim();
          })
          .where((name) => name.isNotEmpty)
          .toSet()
          .toList();

      log('WordService.getListNames: Found ${lists.length} lists: $lists');

      if (lists.isNotEmpty) {
        return lists;
      }

      // Fallback: extract distinct list names from all user words
      final allWords = await getWords();
      return allWords
          .map((w) => w.listName ?? 'General')
          .where((name) => name.isNotEmpty && name != 'Tümü')
          .toSet()
          .toList();
    } on DioException catch (e) {
      log('WordService.getListNames DioException: ${e.response?.statusCode} -> ${e.response?.data}');
      // Fallback on error: extract from words
      try {
        final words = await getWords();
        return words
            .map((w) => w.listName ?? 'General')
            .where((name) => name.isNotEmpty && name != 'Tümü')
            .toSet()
            .toList();
      } catch (_) {
        throw Exception(_extractErrorMessage(e));
      }
    }
  }

  // Create a new list (adds placeholder word so backend creates list entity)
  Future<void> addList(String listName) async {
    try {
      final userId = await _storage.getUserId();
      if (userId == null || userId.isEmpty) {
        throw Exception('Kullanıcı oturumu bulunamadı.');
      }

      await addWord(
        WordModel(
          en: 'new word',
          tr: 'yeni kelime',
          example: 'You can edit or delete this word.',
          listName: listName,
          userId: userId,
        ),
      );
    } catch (e) {
      throw Exception('Liste oluşturulamadı: $e');
    }
  }

  // Rename a list
  Future<void> renameList(String oldName, String newName) async {
    try {
      final userId = await _storage.getUserId();
      if (userId == null || userId.isEmpty) return;

      await _apiClient.put(
        '${ApiConstants.lists}/rename',
        queryParameters: {
          'userId': userId,
          'listName': oldName,
          'newListName': newName,
        },
      );
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  // Delete an entire list
  Future<void> deleteList(String listName) async {
    try {
      final userId = await _storage.getUserId();
      if (userId == null || userId.isEmpty) return;

      await _apiClient.delete(
        ApiConstants.lists,
        queryParameters: {
          'userId': userId,
          'listName': listName,
        },
      );
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  // Search words with query
  Future<List<WordModel>> searchWords({
    required String query,
    String? listName,
  }) async {
    try {
      final userId = await _storage.getUserId();
      if (userId == null || userId.isEmpty) return [];

      if (listName != null &&
          listName.isNotEmpty &&
          listName != 'All' &&
          listName != 'Tümü' &&
          listName != 'My Lists') {
        final response = await _apiClient.get(
          ApiConstants.search,
          queryParameters: {
            'en': query.trim(),
            'userId': userId,
            'listName': listName,
            'searchMode': 'starts',
          },
        );

        final rawList = _extractList(response.data);
        if (rawList.isNotEmpty) {
          return rawList.map((item) {
            if (item is Map<String, dynamic>) {
              return WordModel.fromJson(item);
            } else if (item is Map) {
              return WordModel.fromJson(Map<String, dynamic>.from(item));
            } else {
              return WordModel(en: item.toString(), tr: '');
            }
          }).toList();
        }
      }

      // Local search fallback across all words or list
      final allWords = await getWords(listName: listName);
      final q = query.toLowerCase().trim();
      return allWords.where((w) {
        final en = w.en.toLowerCase().trim();
        final tr = w.tr.toLowerCase().trim();
        return en.startsWith(q) || tr.startsWith(q);
      }).toList();
    } on DioException catch (e) {
      log('WordService.searchWords DioException: ${e.response?.statusCode}');
      final allWords = await getWords(listName: listName);
      final q = query.toLowerCase().trim();
      return allWords.where((w) {
        final en = w.en.toLowerCase().trim();
        final tr = w.tr.toLowerCase().trim();
        return en.startsWith(q) || tr.startsWith(q);
      }).toList();
    }
  }

  // Get synonym groups
  Future<List<SynonymGroupModel>> getSynonymGroups() async {
    try {
      final userId = await _storage.getUserId();
      if (userId == null || userId.isEmpty) {
        return _groupWordsLocally(await getWords());
      }

      final response = await _apiClient.get(
        ApiConstants.synonymGroups,
        queryParameters: {'userId': userId},
      );

      final rawList = _extractList(response.data);

      if (rawList.isNotEmpty) {
        return rawList.map((item) {
          if (item is Map<String, dynamic>) {
            return SynonymGroupModel.fromJson(item);
          } else if (item is Map) {
            return SynonymGroupModel.fromJson(
                Map<String, dynamic>.from(item));
          } else {
            return SynonymGroupModel(
                turkishMeaning: item.toString(), words: []);
          }
        }).where((g) => g.words.isNotEmpty).toList();
      }

      return _groupWordsLocally(await getWords());
    } catch (_) {
      return _groupWordsLocally(await getWords());
    }
  }

  List<SynonymGroupModel> _groupWordsLocally(List<WordModel> allWords) {
    final map = <String, List<WordModel>>{};
    for (final w in allWords) {
      final trKey = w.tr.toLowerCase().trim();
      if (trKey.isNotEmpty) {
        map.putIfAbsent(trKey, () => []).add(w);
      }
    }
    return map.entries
        .where((entry) => entry.value.length > 1)
        .map((entry) => SynonymGroupModel(
              turkishMeaning: entry.key,
              words: entry.value,
            ))
        .toList();
  }

  // Add word
  Future<WordModel> addWord(WordModel word) async {
    try {
      final userId = await _storage.getUserId();
      final payload = {
        'En': word.en,
        'Tr': word.tr,
        'Example': word.example ?? '',
        'ListName': word.listName ?? 'General',
        'UserId': word.userId?.toString() ?? userId ?? '',
      };

      final response = await _apiClient.post(
        ApiConstants.words,
        data: payload,
      );

      if (response.data != null && response.data is Map) {
        return WordModel.fromJson(
          response.data is Map<String, dynamic>
              ? response.data
              : Map<String, dynamic>.from(response.data as Map),
        );
      }
      return word;
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  // Update word
  Future<WordModel> updateWord(WordModel word) async {
    try {
      final userId = await _storage.getUserId();
      final payload = {
        'Id': word.id,
        'En': word.en,
        'Tr': word.tr,
        'Example': word.example ?? '',
        'ListName': word.listName ?? 'General',
        'UserId': word.userId?.toString() ?? userId ?? '',
      };

      final response = await _apiClient.put(
        ApiConstants.words,
        data: payload,
      );

      if (response.data != null && response.data is Map) {
        return WordModel.fromJson(
          response.data is Map<String, dynamic>
              ? response.data
              : Map<String, dynamic>.from(response.data as Map),
        );
      }
      return word;
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  // Delete word
  Future<bool> deleteWord(dynamic id) async {
    try {
      await _apiClient.delete(ApiConstants.wordById(id));
      return true;
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  String _extractErrorMessage(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Sunucu bağlantı zaman aşımı.';
    }
    if (e.response?.data != null && e.response!.data is Map) {
      final data = e.response!.data as Map;
      return data['message']?.toString() ??
          data['error']?.toString() ??
          'İşlem başarısız oldu.';
    }
    return 'Bir hata oluştu (${e.response?.statusCode ?? 'Ağ'}).';
  }
}
