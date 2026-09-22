import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../models/list_sort_order.dart';
import '../models/word_model.dart';
import '../repositories/word_repository.dart';

class WordListState {
  final List<WordModel> words;
  final List<String> listNames;
  final Map<String, int> wordCountsByList;
  final String? selectedListName;
  final String searchQuery;
  final bool isLoading;
  final String? errorMessage;

  const WordListState({
    required this.words,
    required this.listNames,
    this.wordCountsByList = const {},
    this.selectedListName,
    this.searchQuery = '',
    this.isLoading = false,
    this.errorMessage,
  });

  factory WordListState.initial() => const WordListState(
        words: [],
        listNames: [],
        wordCountsByList: {},
        selectedListName: null,
        searchQuery: '',
        isLoading: false,
      );

  WordListState copyWith({
    List<WordModel>? words,
    List<String>? listNames,
    Map<String, int>? wordCountsByList,
    String? selectedListName,
    String? searchQuery,
    bool? isLoading,
    String? errorMessage,
  }) {
    return WordListState(
      words: words ?? this.words,
      listNames: listNames ?? this.listNames,
      wordCountsByList: wordCountsByList ?? this.wordCountsByList,
      selectedListName: selectedListName ?? this.selectedListName,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

final wordListControllerProvider =
    StateNotifierProvider<WordListController, WordListState>((ref) {
  final wordRepository = ref.watch(wordRepositoryProvider);
  final storageService = ref.watch(secureStorageServiceProvider);
  final controller = WordListController(
    wordRepository,
    storageService: storageService,
  );

  ref.listen<AuthState>(authControllerProvider, (prev, next) {
    if (next.isAuthenticated && prev?.isAuthenticated != true) {
      controller.loadInitialData();
    }
  });

  return controller;
});

class WordListController extends StateNotifier<WordListState> {
  final IWordRepository _wordRepository;
  final SecureStorageService _storageService;
  Timer? _debounceTimer;
  bool _isFetching = false;
  List<String> _customOrder = [];

  WordListController(
    this._wordRepository, {
    SecureStorageService? storageService,
  })  : _storageService = storageService ?? SecureStorageService(),
        super(WordListState.initial()) {
    loadInitialData();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Belirlenen özel sıralama (savedOrder) listesini esas alarak listeleri sıralar.
  /// Kayıtlı sıralamadaki listeler en başa yerleştirilir; yeni/kayıtsız listeler
  /// ise sona alfabetik olarak eklenir.
  static List<String> applyListOrder(
      List<String> rawLists, List<String> savedOrder) {
    if (savedOrder.isEmpty) {
      return List<String>.from(rawLists)..sort();
    }
    final orderMap = <String, int>{};
    for (int i = 0; i < savedOrder.length; i++) {
      orderMap[savedOrder[i]] = i;
    }

    final sorted = List<String>.from(rawLists);
    sorted.sort((a, b) {
      final aIndex = orderMap[a];
      final bIndex = orderMap[b];
      if (aIndex != null && bIndex != null) {
        return aIndex.compareTo(bIndex);
      }
      if (aIndex != null) return -1;
      if (bIndex != null) return 1;
      return a.toLowerCase().compareTo(b.toLowerCase());
    });
    return sorted;
  }

  static (List<String>, Map<String, int>) _processListsAndCounts(
      List<WordModel> words,
      [List<String> savedOrder = const []]) {
    final Map<String, int> counts = {};
    for (final w in words) {
      final name = (w.listName == null || w.listName!.trim().isEmpty)
          ? 'General'
          : w.listName!.trim();
      if (name == 'Tümü' || name == 'All') continue;
      counts[name] = (counts[name] ?? 0) + 1;
    }
    final lists = applyListOrder(counts.keys.toList(), savedOrder);
    return (lists, counts);
  }

  Future<void> loadInitialData({bool forceRefresh = false}) async {
    if (!mounted) return;
    if (_isFetching) return;
    if (state.words.isNotEmpty && !forceRefresh) return;

    _isFetching = true;
    if (state.words.isEmpty) {
      state = state.copyWith(isLoading: true, errorMessage: null);
    }

    try {
      if (_customOrder.isEmpty) {
        _customOrder = await _storageService.getCustomListOrder();
      }
      final words = await _wordRepository.getWords(forceRefresh: forceRefresh);
      final (listNames, counts) = _processListsAndCounts(words, _customOrder);

      if (!mounted) return;
      state = state.copyWith(
        words: words,
        listNames: listNames,
        wordCountsByList: counts,
        selectedListName: state.selectedListName ??
            (listNames.isNotEmpty ? listNames.first : null),
        isLoading: false,
        errorMessage: null,
      );
    } catch (e) {
      if (!mounted) return;
      // If we already have local words, do not block UI with an error screen
      if (state.words.isNotEmpty) {
        state = state.copyWith(isLoading: false);
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        );
      }
    } finally {
      _isFetching = false;
    }
  }

  Future<bool> createList(String listName) async {
    if (listName.trim().isEmpty) return false;
    final trimmed = listName.trim();

    if (state.listNames.contains(trimmed)) {
      state = state.copyWith(errorMessage: 'Bu isimde bir liste zaten mevcut.');
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _wordRepository.createList(trimmed);
      if (!_customOrder.contains(trimmed)) {
        _customOrder = [trimmed, ..._customOrder];
        await _storageService.saveCustomListOrder(_customOrder);
      }
      await loadInitialData(forceRefresh: true);
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> renameList(String oldName, String newName) async {
    if (newName.trim().isEmpty || oldName == newName) return false;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _wordRepository.renameList(oldName, newName.trim());
      final idx = _customOrder.indexOf(oldName);
      if (idx != -1) {
        _customOrder[idx] = newName.trim();
        await _storageService.saveCustomListOrder(_customOrder);
      }
      await loadInitialData(forceRefresh: true);
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> deleteList(String listName) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _wordRepository.deleteList(listName);
      _customOrder.remove(listName);
      await _storageService.saveCustomListOrder(_customOrder);
      await loadInitialData(forceRefresh: true);
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// Listeleri kullanıcı tarafından sürükleyip bırakıldığında yeniden sıralar
  /// ve bu sırayı yerel depolamada kalıcı olarak saklar.
  Future<void> reorderLists(int oldIndex, int newIndex) async {
    if (oldIndex < 0 || oldIndex >= state.listNames.length) return;
    if (newIndex < 0 || newIndex > state.listNames.length) return;

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    if (oldIndex == newIndex) return;

    final updated = List<String>.from(state.listNames);
    final moved = updated.removeAt(oldIndex);
    updated.insert(newIndex, moved);

    _customOrder = List<String>.from(updated);
    state = state.copyWith(listNames: updated);

    await _storageService.saveCustomListOrder(updated);
  }

  /// Listeleri belirtilen [ListSortOrder] ölçütüne göre sıralar ve kaydeder.
  Future<void> sortLists(ListSortOrder order) async {
    switch (order) {
      case ListSortOrder.alphabeticalAsc:
        await sortListsAlphabetical(ascending: true);
        break;
      case ListSortOrder.alphabeticalDesc:
        await sortListsAlphabetical(ascending: false);
        break;
      case ListSortOrder.wordCountDesc:
        await sortListsByWordCount(descending: true);
        break;
      case ListSortOrder.wordCountAsc:
        await sortListsByWordCount(descending: false);
        break;
      case ListSortOrder.reset:
        await resetListOrder();
        break;
    }
  }

  /// Listeleri alfabetik (A-Z veya Z-A) sıralar ve kaydeder.
  Future<void> sortListsAlphabetical({bool ascending = true}) async {
    final updated = List<String>.from(state.listNames);
    if (ascending) {
      updated.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    } else {
      updated.sort((a, b) => b.toLowerCase().compareTo(a.toLowerCase()));
    }
    _customOrder = List<String>.from(updated);
    state = state.copyWith(listNames: updated);
    await _storageService.saveCustomListOrder(updated);
  }

  /// Listeleri kelime sayısına göre çoktan aza veya azdan çoğa sıralar ve kaydeder.
  Future<void> sortListsByWordCount({bool descending = true}) async {
    final updated = List<String>.from(state.listNames);
    updated.sort((a, b) {
      final countA = state.wordCountsByList[a] ?? 0;
      final countB = state.wordCountsByList[b] ?? 0;
      final cmp = countA.compareTo(countB);
      if (cmp != 0) return descending ? -cmp : cmp;
      return a.toLowerCase().compareTo(b.toLowerCase());
    });
    _customOrder = List<String>.from(updated);
    state = state.copyWith(listNames: updated);
    await _storageService.saveCustomListOrder(updated);
  }

  /// Listeleri varsayılan sıralamaya sıfırlar.
  Future<void> resetListOrder() async {
    final updated = List<String>.from(state.listNames)..sort();
    _customOrder = [];
    state = state.copyWith(listNames: updated);
    await _storageService.clearCustomListOrder();
  }

  Future<void> filterByList(String listName) async {
    if (state.selectedListName == listName) return;

    if (!mounted) return;
    state = state.copyWith(
      selectedListName: listName,
      searchQuery: '',
      isLoading: true,
      errorMessage: null,
    );

    try {
      final words = await _wordRepository.getWords(
        listName: (listName == 'Tümü' || listName == 'All') ? null : listName,
      );
      if (!mounted) return;
      state = state.copyWith(words: words, isLoading: false);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void onSearchQueryChanged(String query) {
    if (!mounted) return;
    state = state.copyWith(searchQuery: query);
    _debounceTimer?.cancel();

    if (query.trim().isEmpty) {
      _wordRepository
          .getWords(
            listName: (state.selectedListName == 'Tümü' ||
                    state.selectedListName == 'All')
                ? null
                : state.selectedListName,
          )
          .then((words) {
        if (!mounted) return;
        state = state.copyWith(words: words, isLoading: false);
      }).catchError((e) {
        if (!mounted) return;
        state = state.copyWith(
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        );
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted) return;
      state = state.copyWith(isLoading: true, errorMessage: null);
      try {
        final allWords = await _wordRepository.getWords(
          listName: (state.selectedListName == 'Tümü' ||
                  state.selectedListName == 'All')
              ? null
              : state.selectedListName,
        );
        final filtered = allWords.where((w) {
          final q = query.toLowerCase();
          return w.en.toLowerCase().contains(q) ||
              w.tr.toLowerCase().contains(q);
        }).toList();

        if (!mounted) return;
        state = state.copyWith(words: filtered, isLoading: false);
      } catch (e) {
        if (!mounted) return;
        state = state.copyWith(
          isLoading: false,
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        );
      }
    });
  }

  Future<WordModel?> addWord(WordModel word) async {
    try {
      final saved = await _wordRepository.createWord(
        en: word.en,
        tr: word.tr,
        example: word.example,
        listName: word.listName ?? 'General',
      );
      if (!mounted || saved == null) return null;
      final updatedWords = [...state.words, saved];
      final (listNames, counts) =
          _processListsAndCounts(updatedWords, _customOrder);
      state = state.copyWith(
        words: updatedWords,
        listNames: listNames,
        wordCountsByList: counts,
      );
      return saved;
    } catch (e) {
      if (!mounted) return null;
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return null;
    }
  }

  Future<WordModel?> updateWord(WordModel word) async {
    try {
      final saved = await _wordRepository.updateWord(
        id: word.id,
        en: word.en,
        tr: word.tr,
        example: word.example,
        listName: word.listName ?? 'General',
      );
      if (!mounted || saved == null) return null;
      final updatedWords = state.words.map((w) {
        if (w.id == saved.id) return saved;
        return w;
      }).toList();
      final (listNames, counts) =
          _processListsAndCounts(updatedWords, _customOrder);
      state = state.copyWith(
        words: updatedWords,
        listNames: listNames,
        wordCountsByList: counts,
      );
      return saved;
    } catch (e) {
      if (!mounted) return null;
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return null;
    }
  }

  Future<bool> deleteWord(dynamic id) async {
    try {
      final intId = id is int ? id : int.tryParse(id.toString()) ?? 0;
      await _wordRepository.deleteWord(intId);
      if (!mounted) return true;
      final updatedWords = state.words.where((w) => w.id != id).toList();
      final (listNames, counts) =
          _processListsAndCounts(updatedWords, _customOrder);
      state = state.copyWith(
        words: updatedWords,
        listNames: listNames,
        wordCountsByList: counts,
      );
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<void> refresh() async {
    await loadInitialData(forceRefresh: true);
  }
}
