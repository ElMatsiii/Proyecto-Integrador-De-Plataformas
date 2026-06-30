import '../../../../core/errors/result.dart';
import '../entities/usuario_entity.dart';
import '../repositories/i_auth_repository.dart';
 
class LoginUseCase {
  final IAuthRepository _repository;
  const LoginUseCase(this._repository);
 
  Future<Result<UsuarioEntity>> call(String usuario, String password) =>
      _repository.login(usuario, password);
}
 
/// Caso de uso: login con access token de Google (OAuth) obtenido del SDK
/// nativo.
class LoginConGoogleUseCase {
  final IAuthRepository _repository;
  const LoginConGoogleUseCase(this._repository);
 
  Future<Result<UsuarioEntity>> call(String accessToken) =>
      _repository.loginConGoogle(accessToken);
}
 
class LogoutUseCase {
  final IAuthRepository _repository;
  const LogoutUseCase(this._repository);
 
  Future<Result<void>> call() => _repository.logout();
}
 
class GetUsuarioActualUseCase {
  final IAuthRepository _repository;
  const GetUsuarioActualUseCase(this._repository);
 
  Future<Result<UsuarioEntity>> call() => _repository.getUsuarioActual();
}