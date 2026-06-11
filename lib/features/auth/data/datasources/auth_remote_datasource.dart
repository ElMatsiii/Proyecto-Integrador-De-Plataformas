import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/app_error.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/json_read.dart';

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(ref.watch(dioClientProvider));
});

class AuthRemoteDataSource {
  final Dio _dio;
  const AuthRemoteDataSource(this._dio);

  /// Hace POST al endpoint de auth. En caso de éxito, Dio guarda la cookie
  /// de sesión (PHPSESSID) automáticamente vía CookieManager.
  Future<Result<void>> login(String usuario, String password) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '${ApiConstants.auth}?op=auth',
        data: <String, String>{'u': usuario, 'p': password},
      );
      final data = response.data;
      if (data == null) return const Failure(AuthError());
      if (data['status'] == 'ok') return const Success(null);
      return Failure(
        AuthError(
          (data['mensaje'] as String?) ?? 'Credenciales inválidas',
        ),
      );
    } on DioException catch (e) {
      return Failure(dioToAppError(e));
    } catch (e) {
      return Failure(UnknownError(e.toString()));
    }
  }

  /// Obtiene el nombre del usuario desde la cookie de sesión activa.
  Future<Result<Map<String, String>>> getUsuarioActual() async {
    try {
      final response = await _dio.get<List<dynamic>>(
        ApiConstants.usuarioActual,
      );
      final list = response.data;
      if (list == null || list.isEmpty) {
        return const Failure(AuthError('Sin sesión activa'));
      }
      final item = asJsonMap(list.first);
      if (item == null) {
        return const Failure(AuthError('Respuesta de usuario inválida'));
      }
      return Success(<String, String>{
        'rut': readString(item['rut']),
        'nombre': readString(item['nombre']),
      });
    } on DioException catch (e) {
      return Failure(dioToAppError(e));
    } catch (e) {
      return Failure(UnknownError(e.toString()));
    }
  }
}
