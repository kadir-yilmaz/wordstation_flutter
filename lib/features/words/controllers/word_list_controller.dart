import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/controllers/auth_controller.dart';
import '../models/word_model.dart';
import '../services/word_service.dart';

class WordListState {
  final List<WordModel> words;
  final List<String> listNames;
  final String? selectedListName;
  final String searchQuery;
  final bool isLoading;
  final String? errorMessage;

  const WordListState({
    required this.words,
    required this.listNames,
    this.selectedListName,
    this.searchQuery = '',
    this.isLoading = false,
    this.errorMessage,
  });

  factory WordListState.initial() => const WordListState(
        words: [],
        listNames: [],
        selectedListName: null,
        searchQuery: '',
        isLoading: false,
      );

  WordListState copyWith({
    List<WordModel>? words,
    List<String>? listNames,
    String? selectedListName,
    String? searchQuery,
    bool? isLoading,
    String? errorMessage,
  }) {
    return WordListState(
      words: words ?? this.words,
      listNames: listNames ?? this.listNames,
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

  WordListController(this._wordService) : super(WordListState.initial()) {
    loadInitialData();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> loadInitialData() async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final fetchedLists = await _wordService.getListNames();
      final words = await _wordService.getWords();
      
      final derivedLists = words
          .map((w) => w.listName ?? 'General')
          .where((l) => l.isNotEmpty && l != 'Tümü' && l != 'All')
          .toSet()
          .toList();

      final combinedLists = <String>{
        ...fetchedLists.where((l) => l.isNotEmpty && l != 'Tümü' && l != 'All'),
        ...derivedLists,
      }.toList();

      if (!mounted) return;
      state = state.copyWith(
        words: words,
        listNames: combinedLists,
        selectedListName: state.selectedListName ??
            (combinedLists.isNotEmpty ? combinedLists.first : null),
        isLoading: false,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> createList(String listName) async {
    if (listName.trim().isEmpty) return;
    final trimmed = listName.trim();

    if (state.listNames.contains(trimmed)) {
      state = state.copyWith(errorMessage: 'Bu isimde bir liste zaten mevcut.');
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _wordService.addList(trimmed);
      await loadInitialData();
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> renameList(String oldName, String newName) async {
    if (newName.trim().isEmpty || oldName == newName) return;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _wordService.renameList(oldName, newName.trim());
      await loadInitialData();
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> deleteList(String listName) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _wordService.deleteList(listName);
      await loadInitialData();
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
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
      final created = await _wordService.addWord(word);
      final updatedList = [created, ...state.words];
      
      // Update list names if new list name added
      final currentLists = List<String>.from(state.listNames);
      if (word.listName != null &&
          word.listName!.isNotEmpty &&
          !currentLists.contains(word.listName)) {
        currentLists.add(word.listName!);
      }

      if (!mounted) return true;
      state = state.copyWith(words: updatedList, listNames: currentLists);
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
      final updated = await _wordService.updateWord(word);
      final updatedList = state.words.map((w) {
        return w.id == word.id ? updated : w;
      }).toList();

      if (!mounted) return true;
      state = state.copyWith(words: updatedList);
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
      final updatedList = state.words.where((w) => w.id != id).toList();
      if (!mounted) return true;
      state = state.copyWith(words: updatedList);
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
    await loadInitialData();
  }
}
