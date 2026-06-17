import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hanpay_mobil/core/network/auth_token_holder.dart';
import 'package:hanpay_mobil/features/auth/data/auth_repository.dart';
import 'package:hanpay_mobil/shared/models/auth_session.dart';

class AuthState {
  const AuthState({
    this.session,
    this.isBootstrapping = true,
  });

  final AuthSession? session;
  final bool isBootstrapping;

  bool get isAuthenticated => session != null;

  AuthState copyWith({
    AuthSession? session,
    bool? isBootstrapping,
    bool clearSession = false,
  }) {
    return AuthState(
      session: clearSession ? null : (session ?? this.session),
      isBootstrapping: isBootstrapping ?? this.isBootstrapping,
    );
  }
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    Future.microtask(_bootstrap);
    return const AuthState(isBootstrapping: true);
  }

  AuthRepository get _repo => ref.read(authRepositoryProvider);
  AuthTokenHolder get _tokenHolder => ref.read(authTokenHolderProvider);

  void _syncToken(AuthSession? session) {
    _tokenHolder.token = session?.token;
  }

  Future<void> _bootstrap() async {
    final session = await _repo.restoreSession();
    _syncToken(session);
    state = AuthState(session: session, isBootstrapping: false);
  }

  Future<void> login({required String email, required String password}) async {
    final session = await _repo.login(email: email, password: password);
    _syncToken(session);
    state = AuthState(session: session, isBootstrapping: false);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final session = await _repo.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    _syncToken(session);
    state = AuthState(session: session, isBootstrapping: false);
  }

  void applySession(AuthSession session) {
    _syncToken(session);
    state = AuthState(session: session, isBootstrapping: false);
  }

  Future<void> logout({bool localOnly = false}) async {
    if (!localOnly) {
      await _repo.logoutRemote();
    }
    await _repo.clearSession();
    _syncToken(null);
    state = const AuthState(isBootstrapping: false);
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);
