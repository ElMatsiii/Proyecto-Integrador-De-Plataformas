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

// ── Horario completo del semestre ─────────────────────────────────────────────
//
// Siempre carga TODOS los ramos del semestre activo (o del filtro
// seleccionado), sin importar si hay sesión o no.

final horarioProvider =
    FutureProvider<List<HorarioItemEntity>>((ref) async {
  var filtro = ref.watch(horarioFiltroProvider);
  final authState = ref.watch(authProvider);

  // Esperar a que auth termine de verificar
  if (authState is AuthInitial || authState is AuthLoading) {
    return [];
  }

  // Si no hay semestre seleccionado, usar el semestre actual del master.
  if (filtro.semestre == -1) {
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

  return result.data;
});

// ── IDs de cursos inscritos del usuario ──────────────────────────────────────

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

// ── Texto de búsqueda rápida ─────────────────────────────────────────────────

final horarioSearchProvider = StateProvider<String>((ref) => '');

/// Horario final con búsqueda aplicada.
///
/// Lógica inspirada en Hawaii:
/// - Texto vacío      → muestra todos los ramos del semestre.
/// - Texto con ":"    → muestra SOLO los ramos inscritos del usuario
///                      (requiere login; sin login muestra lista vacía).
/// - Cualquier texto  → filtra sobre todos los ramos por curso/profesor/sala/área.
final horarioFiltradoProvider =
    Provider<AsyncValue<List<HorarioItemEntity>>>((ref) {
  final horario = ref.watch(horarioProvider);
  final search = ref.watch(horarioSearchProvider).trim();

  // Modo "mis ramos": el usuario escribió ":"
  if (search == ':') {
    final authState = ref.watch(authProvider);
    if (authState is! AuthAuthenticated) {
      return const AsyncData([]);
    }
    final idsCursos = ref.watch(idsCursosUsuarioProvider);
    return idsCursos.when(
      loading: () => const AsyncLoading(),
      error: (e, st) => AsyncError(e, st),
      data: (ids) => horario.whenData(
        (items) => items.where((i) => ids.contains(i.idCurso)).toList(),
      ),
    );
  }

  // Modo búsqueda normal: filtra sobre TODOS los ramos
  return horario.whenData((items) {
    if (search.isEmpty) return items;
    final query = search.toLowerCase();
    return items.where((item) {
      return item.curso.toLowerCase().contains(query) ||
          item.profesor.toLowerCase().contains(query) ||
          item.sala.toLowerCase().contains(query) ||
          item.area.toLowerCase().contains(query);
    }).toList();
  });
});

// ── Provider auxiliar (carrera del usuario) ───────────────────────────────────

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
    final response = await dio.get<Map<String, dynamic>>(
      ApiConstants.carreraUsuario,
      queryParameters: <String, dynamic>{'s': semestre.id},
    );
    final data = response.data;
    if (data == null) return null;
    return data['id'] as int?;
  } catch (_) {
    return null;
  }
});