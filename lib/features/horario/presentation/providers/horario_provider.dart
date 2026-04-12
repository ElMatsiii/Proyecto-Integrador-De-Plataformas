import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';        
import '../../../../core/errors/result.dart';
import '../../../../core/network/dio_client.dart';       
import '../../../auth/presentation/providers/auth_provider.dart';        
import '../../data/repositories/horario_repository.dart';
import '../../domain/entities/horario_entity.dart';
import '../../domain/usecases/horario_usecases.dart';


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
  var filtro = ref.watch(horarioFiltroProvider);
  final authState = ref.watch(authProvider);

  final tieneFiltros = filtro.semestre != -1 ||
      filtro.area != -1 ||
      filtro.profesor != -1 ||
      filtro.curso != -1 ||
      filtro.sala != -1 ||
      filtro.carrera != -1;

  // Sin filtros y sin login → grilla vacía
  if (!tieneFiltros && authState is! AuthAuthenticated) {
    return [];
  }

  // Con login y sin filtros manuales → semestre actual, filtrar por NRCs del usuario
  if (!tieneFiltros && authState is AuthAuthenticated) {
    final master = await ref.watch(masterProvider.future);
    final semestre = master.semestres.firstWhere(
      (s) => s.esActual,
      orElse: () => master.semestres.first,
    );
    filtro = filtro.copyWith(semestre: semestre.id);
  }

  final repo = ref.watch(horarioRepositoryProvider);
  final useCase = GetHorarioUseCase(repo);
  final result = await useCase(filtro);
  if (result is! Success<List<HorarioItemEntity>>) {
    throw Exception((result as Failure<List<HorarioItemEntity>>).error.message);
  }

  var items = result.data;

  // Con login y sin filtros manuales → filtrar por NRCs del usuario
  if (!tieneFiltros && authState is AuthAuthenticated) {
    final idsCursos = await ref.watch(idsCursosUsuarioProvider.future);
    if (idsCursos.isNotEmpty) {
      items = items.where((i) => idsCursos.contains(i.idCurso)).toList();
    }
  }

  return items;
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

final carreraUsuarioProvider = FutureProvider<int?>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState is! AuthAuthenticated) return null;

  final master = await ref.watch(masterProvider.future);
  final semestre = master.semestres.firstWhere(
    (s) => s.esActual,
    orElse: () => master.semestres.first,
  );

  final dio = ref.watch(dioClientProvider);
  try {
    final response = await dio.get<Map<String, dynamic>>( // ← Map no List
      ApiConstants.carreraUsuario,
      queryParameters: <String, dynamic>{'s': semestre.id},
    );
    final data = response.data;
    if (data == null) return null;
    return data['id'] as int?; // ← directo, sin .first
  } catch (_) {
    return null;
  }
});

final idsCursosUsuarioProvider = FutureProvider<Set<int>>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState is! AuthAuthenticated) return {};

  final master = await ref.watch(masterProvider.future);
  final semestre = master.semestres.firstWhere(
    (s) => s.esActual,
    orElse: () => master.semestres.first,
  );

  final dio = ref.watch(dioClientProvider);
  try {
    final response = await dio.get<dynamic>(
      ApiConstants.cursos,
      queryParameters: <String, dynamic>{
        'u': authState.usuario.rut,
        's': semestre.id,
      },
    );
    final data = response.data;
    if (data is! List) return {};
    return data
        .cast<Map<String, dynamic>>()
        .map((e) => (e['id'] as int?) ?? 0)
        .where((id) => id != 0)
        .toSet();
  } catch (_) {
    return {};
  }
});