import '../../../../core/errors/result.dart';
import '../entities/curso_usuario_entity.dart';

abstract interface class IMisCursosRepository {
  Future<Result<List<CursoUsuarioEntity>>> getCursos(
      String usuario, int semestreId,);
}
