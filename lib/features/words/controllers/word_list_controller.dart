import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/controllers/auth_controller.dart';
import '../models/word_model.dart';
import '../services/word_service.dart';

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
  final wordService = ref.watch(wordServiceProvider);
  final controller = WordListController(wordService);

  ref.listen<AuthState>(authControllerProvider, (prev, next) {
    if (next.isAuthenticated && prev?.isAuthenticated != true) {
      controller.loadInitialData();
    }
  });

  return controller;
});

class WordListController extends StateNotifier<WordListState> {
  final WordService _wordService;
  Timer? _debounceTimer;
  bool _isFetching = false;

  WordListController(this._wordService) : super(WordListState.initial()) {
    loadInitialData();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  static (List<String>, Map<String, int>) _processListsAndCounts(
      List<WordModel> words) {
    final Map<String, int> counts = {};
    for (final w in words) {
      final name = (w.listName == null || w.listName!.trim().isEmpty)
          ? 'General'
          : w.listName!.trim();
      if (name == 'Tümü' || name == 'All') continue;
      counts[name] = (counts[name] ?? 0) + 1;
    }
    final lists = counts.keys.toList()..sort();
    return (lists, counts);
  }

  Future<void> loadInitialData({bool forceRefresh = false}) async {
    if (!mounted) return;
    // Eşzamanlı mükerrer istekleri kilit mekanizmasıyla engelle
    if (_isFetching) return;
    // Eğer veri zaten mevcutsa ve forceRefresh değilse gereksiz yükleme yapma
    if (state.words.isNotEmpty && !forceRefresh) return;

    _isFetching = true;
    if (state.words.isEmpty) {
      state = state.copyWith(isLoading: true, errorMessage: null);
    }

    try {
      // Yalnızca TEK bir optimize getWords çağrısı!
      final words = await _wordService.getWords();
      final (listNames, counts) = _processListsAndCounts(words);

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
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
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
      await _wordService.addList(trimmed);
      await loadInitialData();
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
      await _wordService.renameList(oldName, newName.trim());
      await loadInitialData();
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
      await _wordService.deleteList(listName);
      await loadInitialData();
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
      final words = await _wordService.getWords(
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
      // Reload current list words
      _wordService
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
        final results = await _wordService.searchWords(
          query: query,
          listName: (state.selectedListName == 'Tümü' ||
                  state.selectedListName == 'All')
              ? null
              : state.selectedListName,
        );
        if (!mounted) return;
        state = state.copyWith(words: results, isLoading: false);
      } catch (e) {
        if (!mounted) return;
        state = state.copyWith(
          isLoading: false,
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        );
      }
    });
  }

  Future<bool> addWord(WordModel word) async {
    try {
      final saved = await _wordService.addWord(word);
      if (!mounted) return true;
      // Optimistik: Kelimeyi local state'e ekle, full reload yapma
      final updatedWords = [...state.words, saved];
      final (listNames, counts) = _processListsAndCounts(updatedWords);
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

  Future<bool> updateWord(WordModel word) async {
    try {
      final saved = await _wordService.updateWord(word);
      if (!mounted) return true;
      // Optimistik: Kelimeyi local state'de güncelle, full reload yapma
      final updatedWords = state.words.map((w) {
        if (w.id == saved.id) return saved;
        return w;
      }).toList();
      final (listNames, counts) = _processListsAndCounts(updatedWords);
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

  Future<bool> deleteWord(dynamic id) async {
    try {
      await _wordService.deleteWord(id);
      if (!mounted) return true;
      // Optimistik: Kelimeyi local state'den çıkar, full reload yapma
      final updatedWords = state.words.where((w) => w.id != id).toList();
      final (listNames, counts) = _processListsAndCounts(updatedWords);
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
