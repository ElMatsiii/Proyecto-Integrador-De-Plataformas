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

class AuthRepository implements IAuthRepository {
  final AuthRemoteDataSource _remote;
  final FlutterSecureStorage _storage;

  const AuthRepository(this._remote, this._storage);

  @override
  Future<Result<UsuarioEntity>> login(
      String usuario, String password,) async {
    final loginResult = await _remote.login(usuario, password);
    if (loginResult is Failure) return Failure(loginResult.errorOrNull!);

    // Guardamos el usuario para saber quién está logueado
    await _storage.write(key: StorageKeys.usuario, value: usuario);

    // Obtenemos el nombre real desde la API
    return getUsuarioActual();
  }

  @override
  Future<Result<void>> logout() async {
    try {
      await _storage.delete(key: StorageKeys.usuario);
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
    return usuario != null;
  }
}
