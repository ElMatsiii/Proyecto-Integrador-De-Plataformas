import '../../../../core/errors/result.dart';
import '../entities/horario_entity.dart';

/// Contrato que define qué puede hacer el repositorio de horario.
/// La capa de dominio sólo conoce esta interfaz, no la implementación.
abstract interface class IHorarioRepository {
  /// Obtiene el maestro de información (áreas, días, bloques, etc.)
  /// Se cachea localmente para minimizar llamadas de red.
  Future<Result<MasterEntity>> getMaster({bool forceRefresh = false});

  /// Obtiene el horario filtrado según [filtro].
  Future<Result<List<HorarioItemEntity>>> getHorario(HorarioFiltro filtro);
}
