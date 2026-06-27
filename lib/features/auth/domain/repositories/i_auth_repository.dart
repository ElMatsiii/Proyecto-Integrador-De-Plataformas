import '../../../../core/errors/result.dart';
import '../entities/usuario_entity.dart';
 
abstract interface class IAuthRepository {
  Future<Result<UsuarioEntity>> login(String usuario, String password);
 
  /// Inicia sesión usando un ID token de Google obtenido del SDK nativo.
  /// Internamente guarda la cookie de sesión igual que [login].
  Future<Result<UsuarioEntity>> loginConGoogle(String idToken);
 
  Future<Result<void>> logout();
  Future<Result<UsuarioEntity>> getUsuarioActual();
  Future<bool> estaAutenticado();
}
 