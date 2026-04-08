import '../../../../core/errors/result.dart';
import '../entities/horario_entity.dart';
import '../repositories/i_horario_repository.dart';

/// Caso de uso: obtener el maestro de información.
class GetMasterUseCase {
  final IHorarioRepository _repository;
  const GetMasterUseCase(this._repository);

  Future<Result<MasterEntity>> call({bool forceRefresh = false}) =>
      _repository.getMaster(forceRefresh: forceRefresh);
}

/// Caso de uso: obtener el horario con filtros aplicados.
class GetHorarioUseCase {
  final IHorarioRepository _repository;
  const GetHorarioUseCase(this._repository);

  Future<Result<List<HorarioItemEntity>>> call(HorarioFiltro filtro) =>
      _repository.getHorario(filtro);
}
