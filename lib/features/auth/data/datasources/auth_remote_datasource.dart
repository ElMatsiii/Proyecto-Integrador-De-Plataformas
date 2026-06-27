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

  /// Login normal con usuario y contraseña (sin cambios).
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

  /// Login con Google. Manda el ID token al endpoint a.php usando el
  /// parámetro 'tg', confirmado por el encargado de Hawaii.
  Future<Result<void>> loginConGoogle(String idToken) async {
    try {
      // === LOGS TEMPORALES — quitar antes de producción ===
      // ignore: avoid_print
      print('=== TOKEN GOOGLE (primeros 50 chars): ${idToken.substring(0, 50)}');
      // ignore: avoid_print
      print('=== ENVIANDO A: ${ApiConstants.baseUrl}${ApiConstants.auth}?op=auth');
      // ignore: avoid_print
      print('=== PARAMETRO: ${ApiConstants.authGoogleTokenParam}');
      // =====================================================

      final response = await _dio.post<Map<String, dynamic>>(
        '${ApiConstants.auth}?op=auth',
        data: <String, String>{
          ApiConstants.authGoogleTokenParam: idToken,
        },
      );

      // ignore: avoid_print
      print('=== RESPUESTA SERVIDOR: ${response.data}');

      final data = response.data;
      if (data == null) return const Failure(AuthError());
      if (data['status'] == 'ok') return const Success(null);
      return Failure(
        AuthError(
          (data['mensaje'] as String?) ??
              'No se pudo iniciar sesión con Google',
        ),
      );
    } on DioException catch (e) {
      // ignore: avoid_print
      print('=== ERROR DIO: ${e.response?.data}');
      return Failure(dioToAppError(e));
    } catch (e) {
      // ignore: avoid_print
      print('=== ERROR DESCONOCIDO: $e');
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