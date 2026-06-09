import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/services/notificaciones_service.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/entities/usuario_entity.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../../domain/usecases/auth_usecases.dart';

// ── Estado de sesión ──────────────────────────────────────────────────────────

sealed class AuthState {
  const AuthState();
}

final class AuthInitial extends AuthState {
  const AuthInitial();
}

final class AuthLoading extends AuthState {
  const AuthLoading();
}

final class AuthAuthenticated extends AuthState {
  final UsuarioEntity usuario;
  const AuthAuthenticated(this.usuario);
}

final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

final class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}

// ── Notifier ──────────────────────────────────────────────────────────────────

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthNotifier(
    loginUseCase: LoginUseCase(repo),
    logoutUseCase: LogoutUseCase(repo),
    getUsuarioUseCase: GetUsuarioActualUseCase(repo),
    authRepository: repo,
    notifService: ref.watch(notificacionesServiceProvider),
  )..checkSession();
});

class AuthNotifier extends StateNotifier<AuthState> {
  final LoginUseCase _login;
  final LogoutUseCase _logout;
  final GetUsuarioActualUseCase _getUsuario;
  final IAuthRepository _authRepository;
  final NotificacionesService _notifService;

  AuthNotifier({
    required LoginUseCase loginUseCase,
    required LogoutUseCase logoutUseCase,
    required GetUsuarioActualUseCase getUsuarioUseCase,
    required IAuthRepository authRepository,
    required NotificacionesService notifService,
  })  : _login = loginUseCase,
        _logout = logoutUseCase,
        _getUsuario = getUsuarioUseCase,
        _authRepository = authRepository,
        _notifService = notifService,
        super(const AuthInitial());

  Future<void> checkSession() async {
    state = const AuthLoading();
    final estaAuth = await _authRepository.estaAutenticado();
    if (!estaAuth) {
      state = const AuthUnauthenticated();
      return;
    }
    final result = await _getUsuario();
    if (result is Failure) {
      await _authRepository.logout();
      state = const AuthUnauthenticated();
      return;
    }
    state = _mapResult(result);
  }

  Future<void> login(String usuario, String password) async {
    state = const AuthLoading();
    final result = await _login(usuario, password);
    state = _mapResult(result);
  }

  Future<void> logout() async {
    // Cancelar todas las notificaciones al cerrar sesión
    await _notifService.cancelarTodas();
    await _logout();
    state = const AuthUnauthenticated();
  }

  AuthState _mapResult(Result<UsuarioEntity> result) {
    if (result is Success<UsuarioEntity>) {
      return AuthAuthenticated(result.data);
    } else if (result is Failure<UsuarioEntity>) {
      return AuthError(result.error.message);
    }
    return const AuthUnauthenticated();
  }
}