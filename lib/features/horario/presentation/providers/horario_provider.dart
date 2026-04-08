import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/horario_repository.dart';
import '../../domain/entities/horario_entity.dart';
import '../../domain/usecases/horario_usecases.dart';
import '../../../../core/errors/result.dart';

// ── Master (datos estáticos de la API) ───────────────────────────────────────

final masterProvider = FutureProvider<MasterEntity>((ref) async {
  final repo = ref.watch(horarioRepositoryProvider);
  final useCase = GetMasterUseCase(repo);
  final result = await useCase();
  if (result is Success<MasterEntity>) return result.data;
  throw Exception((result as Failure<MasterEntity>).error.message);
});

// ── Filtro activo ────────────────────────────────────────────────────────────

final horarioFiltroProvider =
    StateNotifierProvider<HorarioFiltroNotifier, HorarioFiltro>((ref) {
  return HorarioFiltroNotifier();
});

class HorarioFiltroNotifier extends StateNotifier<HorarioFiltro> {
  HorarioFiltroNotifier() : super(const HorarioFiltro());

  void setSemestre(int id) => state = state.copyWith(semestre: id);
  void setArea(int id) => state = state.copyWith(area: id);
  void setProfesor(int id) => state = state.copyWith(profesor: id);
  void setCurso(int id) => state = state.copyWith(curso: id);
  void setSala(int id) => state = state.copyWith(sala: id);
  void setCarrera(int id) => state = state.copyWith(carrera: id);
  void reset() => state = const HorarioFiltro();
}

// ── Horario filtrado ─────────────────────────────────────────────────────────

final horarioProvider =
    FutureProvider<List<HorarioItemEntity>>((ref) async {
  final filtro = ref.watch(horarioFiltroProvider);
  final repo = ref.watch(horarioRepositoryProvider);
  final useCase = GetHorarioUseCase(repo);
  final result = await useCase(filtro);
  if (result is Success<List<HorarioItemEntity>>) return result.data;
  throw Exception((result as Failure<List<HorarioItemEntity>>).error.message);
});

// ── Texto de búsqueda rápida ─────────────────────────────────────────────────

final horarioSearchProvider = StateProvider<String>((ref) => '');

/// Horario filtrado por texto de búsqueda rápida (sobre los resultados ya
/// obtenidos del servidor).
final horarioFiltradoProvider =
    Provider<AsyncValue<List<HorarioItemEntity>>>((ref) {
  final horario = ref.watch(horarioProvider);
  final search = ref.watch(horarioSearchProvider).toLowerCase().trim();

  return horario.whenData((items) {
    if (search.isEmpty) return items;
    return items.where((item) {
      return item.curso.toLowerCase().contains(search) ||
          item.profesor.toLowerCase().contains(search) ||
          item.sala.toLowerCase().contains(search) ||
          item.area.toLowerCase().contains(search);
    }).toList();
  });
});
