import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/models/user.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;

  AuthState({
    required this.status,
    this.user,
    this.errorMessage,
  });

  factory AuthState.initial() => AuthState(status: AuthStatus.initial);
  factory AuthState.loading() => AuthState(status: AuthStatus.loading);
  factory AuthState.authenticated(User user) => AuthState(status: AuthStatus.authenticated, user: user);
  factory AuthState.unauthenticated() => AuthState(status: AuthStatus.unauthenticated);
  factory AuthState.error(String message) => AuthState(status: AuthStatus.error, errorMessage: message);
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;
  final _storage = const FlutterSecureStorage();

  AuthNotifier(this._ref) : super(AuthState.initial()) {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token != null) {
      try {
        final user = await _ref.read(userRepositoryProvider).getProfile();
        state = AuthState.authenticated(user);
      } catch (e) {
        state = AuthState.unauthenticated();
      }
    } else {
      state = AuthState.unauthenticated();
    }
  }

  String _getDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout) return 'Connection timeout. Is the server running?';
    if (e.type == DioExceptionType.receiveTimeout) return 'Server taking too long to respond.';
    if (e.type == DioExceptionType.connectionError) return 'Could not connect to server. Check your IP and Wi-Fi.';
    
    if (e.response != null && e.response?.data != null) {
      final data = e.response?.data;
      if (data is Map) {
        return data['message'] ?? data['error'] ?? 'Error: ${e.response?.statusCode}';
      }
    }
    
    return e.message ?? 'An unknown network error occurred';
  }

  Future<void> login(String email, String password) async {
    state = AuthState.loading();
    try {
      final data = await _ref.read(authRepositoryProvider).login(email, password);
      final user = User.fromMap(data['user']);
      state = AuthState.authenticated(user);
    } on DioException catch (e) {
      state = AuthState.error(_getDioError(e));
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  Future<void> register(Map<String, dynamic> userData) async {
    state = AuthState.loading();
    try {
      final data = await _ref.read(authRepositoryProvider).register(userData);
      final user = User.fromMap(data['user']);
      state = AuthState.authenticated(user);
    } on DioException catch (e) {
      state = AuthState.error(_getDioError(e));
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  Future<void> logout() async {
    await _ref.read(authRepositoryProvider).logout();
    state = AuthState.unauthenticated();
  }
}

final authControllerProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});
