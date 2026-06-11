import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/services/notificaciones_service.dart';
import '../../../auth/presentation/providers/auth_provider_notif.dart';
import '../../../mis_cursos/data/mis_cursos_datasource.dart';
import '../../../mis_cursos/domain/entities/curso_usuario_entity.dart';
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

SemestreEntity? semestreActualOrNull(MasterEntity master) {
  if (master.semestres.isEmpty) return null;
  return master.semestres.firstWhere(
    (s) => s.esActual,
    orElse: () => master.semestres.first,
  );
}

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
  void setDia(String dia) => state = state.copyWith(dia: dia);
  void setCarreraId(int id) => state = state.copyWith(carreraId: id);

  void reset() => state = const HorarioFiltro();
}

// ── Horario completo del semestre ─────────────────────────────────────────────

final horarioProvider = FutureProvider<List<HorarioItemEntity>>((ref) async {
  var filtro = ref.watch(horarioFiltroProvider);

  // Observar currentUserProvider para que este provider se reconstruya
  // automáticamente cuando cambia la sesión (login / logout).
  ref.watch(currentUserProvider);

  // Si aún no sabemos el estado de auth, devolver vacío sin hacer request.
  final authState = ref.watch(authProvider);
  if (authState is AuthInitial || authState is AuthLoading) {
    return [];
  }

  if (filtro.semestre == -1) {
    final master = await ref.watch(masterProvider.future);
    final semestre = semestreActualOrNull(master);
    if (semestre == null) return [];
    filtro = filtro.copyWith(semestre: semestre.id);
  }

  final repo = ref.watch(horarioRepositoryProvider);
  final useCase = GetHorarioUseCase(repo);
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
    throw Exception(
      (result as Failure<List<HorarioItemEntity>>).error.message,
    );
  }

  return result.data;
});

// ── Modo de vista: estudiante o ayudante ─────────────────────────────────────

enum ModoVistaHorario { estudiante, ayudante }

final modoVistaHorarioProvider = StateProvider<ModoVistaHorario>(
  (ref) => ModoVistaHorario.estudiante,
);

// ── IDs de cursos separados por rol ──────────────────────────────────────────

typedef RolesCursos = ({Set<int> comoEstudiante, Set<int> comoProfesor});

final idsCursosPorRolProvider = FutureProvider<RolesCursos>((ref) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) {
    return (comoEstudiante: <int>{}, comoProfesor: <int>{});
  }

  final master = await ref.watch(masterProvider.future);
  final semestre = semestreActualOrNull(master);
  if (semestre == null) {
    return (comoEstudiante: <int>{}, comoProfesor: <int>{});
  }

  final repo = ref.watch(misCursosRepositoryProvider);
  final result = await repo.getCursos(currentUser.rut, semestre.id);

  if (result is! Success<List<CursoUsuarioEntity>>) {
    return (comoEstudiante: <int>{}, comoProfesor: <int>{});
  }

  final comoEstudiante = result.data
      .where((c) => !c.esProfesor)
      .expand((c) => c.todosLosIds)
      .toSet();
  final comoProfesor = result.data
      .where((c) => c.esProfesor)
      .expand((c) => c.todosLosIds)
      .toSet();

  return (comoEstudiante: comoEstudiante, comoProfesor: comoProfesor);
});

// ── Provider legacy (mantiene compatibilidad con AsistenciaScreen) ────────────

final idsCursosUsuarioProvider = FutureProvider<Set<int>>((ref) async {
  final roles = await ref.watch(idsCursosPorRolProvider.future);
  return {...roles.comoEstudiante, ...roles.comoProfesor};
});

// ── Programar notificaciones cuando el horario del usuario está listo ─────────

final notificacionesProgramadasProvider = FutureProvider<void>((ref) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return;

  final rolesCursos = await ref.watch(idsCursosPorRolProvider.future);
  final horarioItems = await ref.watch(horarioProvider.future);
  final master = await ref.watch(masterProvider.future);

  final itemsUsuario = horarioItems
      .where((i) => rolesCursos.comoEstudiante.contains(i.idCurso))
      .toList();

  if (itemsUsuario.isEmpty) return;

  final notifService = ref.watch(notificacionesServiceProvider);
  await notifService.programarSemana(
    items: itemsUsuario,
    bloques: master.bloques,
  );
});

// ── Texto de búsqueda rápida ─────────────────────────────────────────────────

final horarioSearchProvider = StateProvider<String>((ref) => '');

/// Horario final con búsqueda y filtros locales aplicados.
final horarioFiltradoProvider =
    Provider<AsyncValue<List<HorarioItemEntity>>>((ref) {
  final horario = ref.watch(horarioProvider);
  final search = ref.watch(horarioSearchProvider).trim();
  final filtro = ref.watch(horarioFiltroProvider);

  if (search == ':') {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) {
      return const AsyncData([]);
    }

    final rolesCursos = ref.watch(idsCursosPorRolProvider);
    final modo = ref.watch(modoVistaHorarioProvider);
    final nombreUsuario = currentUser.nombre.toLowerCase();

    return rolesCursos.when(
      loading: () => const AsyncLoading(),
      error: (e, st) => AsyncError(e, st),
      data: (roles) {
        if (modo == ModoVistaHorario.ayudante) {
          return horario.whenData(
            (items) => _aplicarFiltrosLocales(
              items
                  .where(
                    (i) =>
                        roles.comoProfesor.contains(i.idCurso) &&
                        i.profesor.toLowerCase().contains(nombreUsuario),
                  )
                  .toList(),
              filtro,
              '',
            ),
          );
        }

        return horario.whenData(
          (items) => _aplicarFiltrosLocales(
            items
                .where((i) => roles.comoEstudiante.contains(i.idCurso))
                .toList(),
            filtro,
            '',
          ),
        );
      },
    );
  }

  return horario.whenData(
    (items) => _aplicarFiltrosLocales(items, filtro, search),
  );
});

List<HorarioItemEntity> _aplicarFiltrosLocales(
  List<HorarioItemEntity> items,
  HorarioFiltro filtro,
  String search,
) {
  var resultado = items;

  if (filtro.dia.isNotEmpty) {
    resultado = resultado.where((i) => i.dia == filtro.dia).toList();
  }

  if (filtro.carreraId != -1) {
    resultado = resultado
        .where((i) => i.carreras.any((c) => c.id == filtro.carreraId))
        .toList();
  }

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
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return null;

  final master = await ref.watch(masterProvider.future);
  final semestre = semestreActualOrNull(master);
  if (semestre == null) return null;

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
