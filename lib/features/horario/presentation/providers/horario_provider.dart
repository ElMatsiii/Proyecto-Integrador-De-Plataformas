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
  void setNivel(int nivel) => state = state.copyWith(semestreC: nivel);
  /// Filtro de día: local, no se envía a la API.
  void setDia(String dia) => state = state.copyWith(dia: dia);
  /// Filtro de carrera por ID: local, sobre los resultados ya descargados.
  void setCarreraId(int id) => state = state.copyWith(carreraId: id);

  void reset() => state = const HorarioFiltro();
}

// ── Horario completo del semestre ─────────────────────────────────────────────

final horarioProvider =
    FutureProvider<List<HorarioItemEntity>>((ref) async {
  var filtro = ref.watch(horarioFiltroProvider);
  final authState = ref.watch(authProvider);

  if (authState is AuthInitial || authState is AuthLoading) {
    return [];
  }

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
  // Solo se envían a la API los filtros de servidor (no dia ni carreraId local)
  final filtroApi = HorarioFiltro(
    sala: filtro.sala,
    curso: filtro.curso,
    profesor: filtro.profesor,
    semestre: filtro.semestre,
    semestreC: filtro.semestreC,
    carrera: filtro.carrera,
    area: filtro.area,
  );
  final result = await useCase(filtroApi);

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

/// Horario final con búsqueda y filtros locales aplicados.
///
/// Filtros locales:
/// - [dia]: filtra por día de la semana.
/// - [carreraId]: filtra items que pertenecen a esa carrera.
/// - búsqueda de texto: filtra por curso/profesor/sala/área.
/// - ":" activa "mis ramos" (requiere login).
final horarioFiltradoProvider =
    Provider<AsyncValue<List<HorarioItemEntity>>>((ref) {
  final horario = ref.watch(horarioProvider);
  final search = ref.watch(horarioSearchProvider).trim();
  final filtro = ref.watch(horarioFiltroProvider);

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
        (items) => _aplicarFiltrosLocales(
          items.where((i) => ids.contains(i.idCurso)).toList(),
          filtro,
          '',
        ),
      ),
    );
  }

  // Modo búsqueda normal: filtra sobre TODOS los ramos
  return horario.whenData(
    (items) => _aplicarFiltrosLocales(items, filtro, search),
  );
});

/// Aplica los filtros locales (día, carreraId, búsqueda de texto).
List<HorarioItemEntity> _aplicarFiltrosLocales(
  List<HorarioItemEntity> items,
  HorarioFiltro filtro,
  String search,
) {
  var resultado = items;

  // Filtro por día (local)
  if (filtro.dia.isNotEmpty) {
    resultado = resultado.where((i) => i.dia == filtro.dia).toList();
  }

  // Filtro por carrera (local, sobre el campo carreras de cada item)
  if (filtro.carreraId != -1) {
    resultado = resultado
        .where((i) => i.carreras.any((c) => c.id == filtro.carreraId))
        .toList();
  }

  // Búsqueda de texto
  if (search.isNotEmpty) {
    final query = search.toLowerCase();
    resultado = resultado.where((item) {
      return item.curso.toLowerCase().contains(query) ||
          item.profesor.toLowerCase().contains(query) ||
          item.sala.toLowerCase().contains(query) ||
          item.area.toLowerCase().contains(query);
    }).toList();
  }

  return resultado;
}

// ── Carreras únicas desde los items cargados ──────────────────────────────────

/// Extrae todas las carreras únicas de los ítems del horario actual.
/// Se usa para el filtro de carrera local.
final carrerasDisponiblesProvider =
    Provider<AsyncValue<List<CarreraEnHorario>>>((ref) {
  return ref.watch(horarioProvider).whenData((items) {
    final seen = <int, CarreraEnHorario>{};
    for (final item in items) {
      for (final carrera in item.carreras) {
        seen.putIfAbsent(carrera.id, () => carrera);
      }
    }
    final lista = seen.values.toList()
      ..sort((a, b) => a.nombre.compareTo(b.nombre));
    return lista;
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