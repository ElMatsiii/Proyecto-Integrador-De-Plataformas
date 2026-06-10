import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/services/notificaciones_service.dart';
import '../../../horario/presentation/providers/horario_provider_notif.dart';
import '../../../mis_cursos/data/mis_cursos_datasource.dart';
import '../../../mis_cursos/data/notas_datasource.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/entities/usuario_entity.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../../domain/usecases/auth_usecases.dart';
import '../../../asistencia/data/asistencia_datasource.dart';

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
    ref: ref,
  )..checkSession();
});

class AuthNotifier extends StateNotifier<AuthState> {
  final LoginUseCase _login;
  final LogoutUseCase _logout;
  final GetUsuarioActualUseCase _getUsuario;
  final IAuthRepository _authRepository;
  final NotificacionesService _notifService;
  final Ref _ref;

  AuthNotifier({
    required LoginUseCase loginUseCase,
    required LogoutUseCase logoutUseCase,
    required GetUsuarioActualUseCase getUsuarioUseCase,
    required IAuthRepository authRepository,
    required NotificacionesService notifService,
    required Ref ref,
  })  : _login = loginUseCase,
        _logout = logoutUseCase,
        _getUsuario = getUsuarioUseCase,
        _authRepository = authRepository,
        _notifService = notifService,
        _ref = ref,
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
    // Primero actualizamos el estado (salimos del ciclo del provider)
    state = _mapResult(result);
  }

  Future<void> logout() async {
    await _notifService.cancelarTodas();
    await _logout();
    // Primero actualizamos el estado (salimos del ciclo del provider)
    state = const AuthUnauthenticated();
    // Luego invalidamos en el siguiente event loop, cuando Riverpod
    // ya terminó de procesar el cambio de estado de authProvider.
    // Future.delayed(zero) es más seguro que microtask porque espera
    // al siguiente ciclo completo del event loop.
    Future.delayed(Duration.zero, _invalidarProveedoresDeUsuario);
  }

  /// Invalida todos los providers con datos específicos de un usuario.
  /// Solo debe llamarse DESPUÉS de que authProvider haya cambiado su estado,
  /// nunca de forma síncrona dentro de un rebuild de Riverpod.
  void _invalidarProveedoresDeUsuario() {
    // Verificar que el notifier sigue montado antes de invalidar
    if (!mounted) return;
    _ref.invalidate(horarioProvider);
    _ref.invalidate(masterProvider);
    _ref.invalidate(idsCursosPorRolProvider);
    _ref.invalidate(idsCursosUsuarioProvider);
    _ref.invalidate(carreraUsuarioProvider);
    _ref.invalidate(misCursosProvider);
    _ref.invalidate(notificacionesProgramadasProvider);
    _ref.invalidate(horarioFiltroProvider);
    _ref.invalidate(horarioSearchProvider);
    _ref.invalidate(modoVistaHorarioProvider);
    _ref.invalidate(asistenciasProvider);
    _ref.invalidate(notasProvider);
    _ref.invalidate(asistenciaEstudianteProvider);
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