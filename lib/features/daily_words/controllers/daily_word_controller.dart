import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/controllers/auth_controller.dart';
import '../models/daily_word_session.dart';
import '../services/daily_word_service.dart';

class DailyWordState {
  final bool isLoading;
  final String? errorMessage;
  final DailyWordSession? session;

  const DailyWordState({
    this.isLoading = false,
    this.errorMessage,
    this.session,
  });

  DailyWordState copyWith({
    bool? isLoading,
    String? errorMessage,
    DailyWordSession? session,
    bool clearError = false,
  }) {
    return DailyWordState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      session: session ?? this.session,
    );
  }
}

class DailyWordController extends StateNotifier<DailyWordState> {
  final DailyWordService _dailyWordService;
  final Ref _ref;

  DailyWordController(this._dailyWordService, this._ref)
      : super(const DailyWordState());

  String? get _userId => _ref.read(authControllerProvider).user?.id.toString();

  Future<void> loadSession(String listName) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final session = await _dailyWordService.getSession(_userId, listName);
      if (session != null) {
        state = state.copyWith(isLoading: false, session: session);
      } else {
        // Otomatik init yapalim
        final newSession = await _dailyWordService.initializeSession(_userId, listName);
        state = state.copyWith(isLoading: false, session: newSession);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> addToDaily(String listName, List<int> wordIds) async {
    if (wordIds.isEmpty) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final session = await _dailyWordService.addToDaily(_userId, listName, wordIds);
      state = state.copyWith(isLoading: false, session: session);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> removeFromDaily(String listName, List<int> wordIds) async {
    if (wordIds.isEmpty) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final session = await _dailyWordService.removeFromDaily(_userId, listName, wordIds);
      state = state.copyWith(isLoading: false, session: session);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> completeWord(String listName, int wordId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final session = await _dailyWordService.completeWord(_userId, listName, wordId);
      state = state.copyWith(isLoading: false, session: session);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
  Future<void> completeAllWords(String listName, List<int> wordIds) async {
    if (wordIds.isEmpty) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      DailyWordSession? currentSession;
      for (final id in wordIds) {
        currentSession = await _dailyWordService.completeWord(_userId, listName, id);
      }
      state = state.copyWith(isLoading: false, session: currentSession);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

// Controller provider is created dynamically using family for multiple lists, or we can use a single provider
// and clear it when exiting the page. Since we only view one list at a time, a single provider is fine.
final dailyWordControllerProvider =
    StateNotifierProvider<DailyWordController, DailyWordState>((ref) {
  final service = ref.watch(dailyWordServiceProvider);
  return DailyWordController(service, ref);
});
