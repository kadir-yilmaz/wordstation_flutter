import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
  });

  factory AuthState.initial() => const AuthState(status: AuthStatus.initial);
  factory AuthState.loading() => const AuthState(status: AuthStatus.loading);
  factory AuthState.authenticated(UserModel user) =>
      AuthState(status: AuthStatus.authenticated, user: user);
  factory AuthState.unauthenticated() =>
      const AuthState(status: AuthStatus.unauthenticated);
  factory AuthState.error(String message) =>
      AuthState(status: AuthStatus.error, errorMessage: message);

  bool get isLoading => status == AuthStatus.loading;
  bool get isAuthenticated => status == AuthStatus.authenticated;
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  final storage = ref.watch(secureStorageServiceProvider);

  final controller = AuthController(
    authService: authService,
    storage: storage,
  );

  // Listen to 401 unauthorized events from interceptor
  ref.listen<int>(unauthorizedEventProvider, (prev, next) {
    if (next > 0) {
      controller.handleUnauthorized();
    }
  });

  return controller;
});

class AuthController extends StateNotifier<AuthState> {
  final AuthService authService;
  final SecureStorageService storage;

  AuthController({
    required this.authService,
    required this.storage,
  }) : super(AuthState.initial());

  Future<void> checkAuthStatus() async {
    try {
      final hasToken = await storage.hasValidToken();
      if (hasToken) {
        final userId = await storage.getUserId() ?? 'user';
        final email = await storage.getUserEmail() ?? '';
        state = AuthState.authenticated(UserModel(id: userId, email: email));
      } else {
        state = AuthState.unauthenticated();
      }
    } catch (_) {
      state = AuthState.unauthenticated();
    }
  }

  Future<bool> login(String email, String password) async {
    state = AuthState.loading();
    try {
      final user = await authService.loginWithEmail(email, password);
      state = AuthState.authenticated(user);
      return true;
    } catch (e) {
      state = AuthState.error(e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<bool> register(String email, String password) async {
    state = AuthState.loading();
    try {
      final user = await authService.register(email, password);
      state = AuthState.authenticated(user);
      return true;
    } catch (e) {
      state = AuthState.error(e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<bool> loginWithGoogle() async {
    state = AuthState.loading();
    try {
      final user = await authService.loginWithGoogle();
      state = AuthState.authenticated(user);
      return true;
    } catch (e) {
      state = AuthState.error(e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<void> logout() async {
    state = AuthState.loading();
    try {
      await authService.logout();
    } finally {
      state = AuthState.unauthenticated();
    }
  }

  void handleUnauthorized() {
    state = AuthState.unauthenticated();
  }

  void clearError() {
    if (state.status == AuthStatus.error) {
      state = AuthState.unauthenticated();
    }
  }
}
