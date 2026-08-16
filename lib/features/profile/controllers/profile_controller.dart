import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../words/controllers/word_list_controller.dart';

class ProfileState {
  final String email;
  final String userId;
  final int totalWords;
  final int totalLists;
  final bool isLoading;

  const ProfileState({
    required this.email,
    required this.userId,
    required this.totalWords,
    required this.totalLists,
    this.isLoading = false,
  });

  factory ProfileState.initial() => const ProfileState(
        email: '',
        userId: '',
        totalWords: 0,
        totalLists: 0,
        isLoading: false,
      );

  ProfileState copyWith({
    String? email,
    String? userId,
    int? totalWords,
    int? totalLists,
    bool? isLoading,
  }) {
    return ProfileState(
      email: email ?? this.email,
      userId: userId ?? this.userId,
      totalWords: totalWords ?? this.totalWords,
      totalLists: totalLists ?? this.totalLists,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final profileControllerProvider =
    StateNotifierProvider<ProfileController, ProfileState>((ref) {
  final storage = ref.watch(secureStorageServiceProvider);
  final initialWordListState = ref.read(wordListControllerProvider);
  
  final controller = ProfileController(storage);
  
  // Initialize with current word stats
  controller.updateStatsFromWords(
    totalWords: initialWordListState.words.length,
    totalLists: initialWordListState.listNames
        .where((l) => l != 'Tümü' && l != 'All')
        .length,
  );

  // Listen to word list state changes without disposing this controller
  ref.listen<WordListState>(wordListControllerProvider, (prev, next) {
    controller.updateStatsFromWords(
      totalWords: next.words.length,
      totalLists:
          next.listNames.where((l) => l != 'Tümü' && l != 'All').length,
    );
  });

  return controller;
});

class ProfileController extends StateNotifier<ProfileState> {
  final SecureStorageService _storage;

  ProfileController(this._storage) : super(ProfileState.initial()) {
    loadProfile();
  }

  Future<void> loadProfile() async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true);
    final email = await _storage.getUserEmail() ?? 'kullanici@wordstation.com';
    final userId = await _storage.getUserId() ?? 'ws_user';

    if (!mounted) return;
    state = state.copyWith(
      email: email,
      userId: userId,
      isLoading: false,
    );
  }

  void updateStatsFromWords({
    required int totalWords,
    required int totalLists,
  }) {
    if (!mounted) return;
    state = state.copyWith(
      totalWords: totalWords,
      totalLists: totalLists,
    );
  }
}
