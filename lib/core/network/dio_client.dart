import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/api_constants.dart';

/// Proveedor global del cliente Dio.
/// Se accede desde los data sources via Riverpod.
final dioClientProvider = Provider<Dio>((ref) => DioClient._instance);

/// Singleton que configura Dio con interceptores, cookies y timeouts.
class DioClient {
  DioClient._();

  static late final Dio _instance;
  static late final CookieJar _cookieJar;

  static Future<void> init() async {
    _cookieJar = CookieJar();

    _instance = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout:
            const Duration(milliseconds: ApiConstants.connectTimeoutMs),
        receiveTimeout:
            const Duration(milliseconds: ApiConstants.receiveTimeoutMs),
        responseType: ResponseType.json,
        contentType: Headers.formUrlEncodedContentType,
      ),
    )
      ..interceptors.add(CookieManager(_cookieJar))
      ..interceptors.add(_loggingInterceptor());
  }

  static Interceptor _loggingInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        // En modo debug puedes activar logs aquí
        handler.next(options);
      },
      onError: (error, handler) {
        // Centraliza errores de red antes de propagarlos
        handler.next(error);
      },
    );
  }

  /// Permite acceder al jar para limpiar cookies al cerrar sesión.
  static CookieJar get cookieJar => _cookieJar;
}
