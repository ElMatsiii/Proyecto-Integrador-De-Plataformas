import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/errors/app_error.dart';
import '../../../../core/errors/result.dart';

final googleAuthServiceProvider = Provider<GoogleAuthService>((ref) {
  return GoogleAuthService();
});

/// Envuelve `google_sign_in` (API 7.x) para obtener el access token de
/// Google que se enviará al endpoint a.php de Hawaii como parámetro 'tg'.
class GoogleAuthService {
  // Web Client ID creado en Google Cloud Console (tipo "Aplicación web").
  // Este es el que google_sign_in necesita como serverClientId para que
  // Android genere correctamente el ID token / access token.
  static const _clientId =
      '773114131140-ji1hgmfcu9v1l1pk2ieeu9ta5rsssat0.apps.googleusercontent.com';

  // Scopes mínimos para obtener un access token de tipo OAuth (ya29...),
  // que es lo que espera el backend de Hawaii en a.php?op=auth (param 'tg').
  static const _scopes = <String>['email', 'profile'];

  bool _initialized = false;

  GoogleSignIn get _instance => GoogleSignIn.instance;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await _instance.initialize(serverClientId: _clientId);
    _initialized = true;
  }

  /// Dispara el selector de cuenta de Google del dispositivo y retorna el
  /// access token OAuth (ya29...) para enviarlo al endpoint a.php de Hawaii
  /// como 'tg'. (En API 7.x el idToken y el accessToken se obtienen por vías
  /// separadas: authenticate() solo da el idToken; el accessToken hay que
  /// pedirlo explícitamente vía authorizationClient).
  Future<Result<String>> obtenerAccessToken() async {
    try {
      await _ensureInitialized();

      if (!_instance.supportsAuthenticate()) {
        return const Failure(
          UnknownError(
            'Inicio de sesión con Google no disponible en este dispositivo',
          ),
        );
      }

      final GoogleSignInAccount cuenta = await _instance.authenticate();

      final authClient = cuenta.authorizationClient;
      var authorization = await authClient.authorizationForScopes(_scopes);
      authorization ??= await authClient.authorizeScopes(_scopes);

      final accessToken = authorization.accessToken;

      if (accessToken.isEmpty) {
        return const Failure(
          UnknownError('Google no devolvió un access token válido'),
        );
      }

      return Success(accessToken);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return const Failure(AuthError('Inicio de sesión cancelado'));
      }
      return Failure(
        UnknownError('Error de Google Sign-In: ${e.description ?? e.code}'),
      );
    } catch (e) {
      return Failure(UnknownError(e.toString()));
    }
  }

  /// Cierra la sesión de Google del dispositivo (no la sesión de Tongoy).
  Future<void> signOut() async {
    try {
      await _ensureInitialized();
      await _instance.signOut();
    } catch (_) {
      // No crítico.
    }
  }
}