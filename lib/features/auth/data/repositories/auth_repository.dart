import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/app_error.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/usuario_entity.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  return AuthRepository(
    ref.watch(authRemoteDataSourceProvider),
    const FlutterSecureStorage(),
  );
});

/// Clave usada para guardar la cookie de sesión en SecureStorage.
const _kCookieKey = 'phpsessid_cookie';

class AuthRepository implements IAuthRepository {
  final AuthRemoteDataSource _remote;
  final FlutterSecureStorage _storage;

  const AuthRepository(this._remote, this._storage);

  @override
  Future<Result<UsuarioEntity>> login(
      String usuario, String password,) async {
    final loginResult = await _remote.login(usuario, password);
    if (loginResult is Failure) return Failure(loginResult.errorOrNull!);

    // Guardar usuario para saber quién está logueado
    await _storage.write(key: StorageKeys.usuario, value: usuario);

    // Persistir la cookie de sesión para sobrevivir reinicios
    await _persistCookie();

    return getUsuarioActual();
  }

  @override
  Future<Result<void>> logout() async {
    try {
      await Future.wait([
        _storage.delete(key: StorageKeys.usuario),
        _storage.delete(key: _kCookieKey),
      ]);
      await DioClient.cookieJar.deleteAll();
      return const Success(null);
    } catch (e) {
      return Failure(UnknownError(e.toString()));
    }
  }

  @override
  Future<Result<UsuarioEntity>> getUsuarioActual() async {
    final result = await _remote.getUsuarioActual();
    return result.when(
      success: (data) => Success(
        UsuarioEntity(rut: data['rut']!, nombre: data['nombre']!),
      ),
      failure: (e) => Failure(e),
    );
  }

  @override
  Future<bool> estaAutenticado() async {
    final usuario = await _storage.read(key: StorageKeys.usuario);
    if (usuario == null) return false;

    // Intentar restaurar la cookie antes de verificar
    await _restoreCookie();
    return true;
  }

  // ── Cookie persistence ────────────────────────────────────────────────────

  /// Guarda la PHPSESSID en SecureStorage tras un login exitoso.
  Future<void> _persistCookie() async {
    try {
      final uri = Uri.parse(ApiConstants.baseUrl);
      final cookies = await DioClient.cookieJar.loadForRequest(uri);
      final session = cookies.firstWhere(
        (c) => c.name == 'PHPSESSID',
        orElse: () => Cookie('', ''),
      );
      if (session.value.isNotEmpty) {
        // Guardamos "nombre=valor" para reconstruirla luego
        await _storage.write(
          key: _kCookieKey,
          value: '${session.name}=${session.value}',
        );
      }
    } catch (_) {
      // No crítico: la sesión en memoria sigue funcionando
    }
  }

  /// Restaura la cookie desde SecureStorage al CookieJar de Dio.
  Future<void> _restoreCookie() async {
    try {
      final raw = await _storage.read(key: _kCookieKey);
      if (raw == null || !raw.contains('=')) return;

      final parts = raw.split('=');
      final name = parts[0];
      final value = parts.sublist(1).join('=');

      final cookie = Cookie(name, value)
        // Sin fecha de expiración → vive mientras la app esté en memoria
        // El servidor decidirá si la sesión sigue válida
        ..httpOnly = true
        ..path = '/';

      final uri = Uri.parse(ApiConstants.baseUrl);
      await DioClient.cookieJar.saveFromResponse(uri, [cookie]);
    } catch (_) {
      // Si falla la restauración, el usuario tendrá que loguearse de nuevo
    }
  }
}