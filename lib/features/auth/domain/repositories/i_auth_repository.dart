import '../../../../core/errors/result.dart';
import '../entities/usuario_entity.dart';

abstract interface class IAuthRepository {
  Future<Result<UsuarioEntity>> login(String usuario, String password);
  Future<Result<void>> logout();
  Future<Result<UsuarioEntity>> getUsuarioActual();
  Future<bool> estaAutenticado();
}
