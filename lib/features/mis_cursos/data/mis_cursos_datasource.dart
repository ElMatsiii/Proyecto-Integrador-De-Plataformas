import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/app_error.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/network/dio_client.dart';
import '../domain/entities/curso_usuario_entity.dart';
import '../domain/repositories/i_mis_cursos_repository.dart';

// ── Data Source ───────────────────────────────────────────────────────────────

final misCursosRemoteProvider = Provider<MisCursosRemoteDataSource>((ref) {
  return MisCursosRemoteDataSource(ref.watch(dioClientProvider));
});

class MisCursosRemoteDataSource {
  final Dio _dio;
  const MisCursosRemoteDataSource(this._dio);

  Future<Result<List<Map<String, dynamic>>>> fetchCursos(
    String usuario,
    int semestreId,
  ) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiConstants.cursos,
        queryParameters: <String, dynamic>{'u': usuario, 's': semestreId},
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data['status'] == 'error') {
        return Failure(ServerError(data['mensaje'] as String));
      }
      if (data is List) {
        return Success(data.cast<Map<String, dynamic>>());
      }
      return const Success([]);
    } on DioException catch (e) {
      return Failure(dioToAppError(e));
    } catch (e) {
      return Failure(UnknownError(e.toString()));
    }
  }
}

// ── Repository ────────────────────────────────────────────────────────────────

final misCursosRepositoryProvider = Provider<IMisCursosRepository>((ref) {
  return MisCursosRepository(ref.watch(misCursosRemoteProvider));
});

class MisCursosRepository implements IMisCursosRepository {
  final MisCursosRemoteDataSource _remote;
  const MisCursosRepository(this._remote);

  @override
  Future<Result<List<CursoUsuarioEntity>>> getCursos(
    String usuario,
    int semestreId,
  ) async {
    final result = await _remote.fetchCursos(usuario, semestreId);
    if (result is! Success<List<Map<String, dynamic>>>) {
      return Failure((result as Failure<List<Map<String, dynamic>>>).error);
    }

    // La API devuelve el mismo curso dos veces cuando tiene tanto asistencia
    // como notas: una entrada con extra=A (id del registro de asistencia) y
    // otra con extra=N (id del registro de notas). Estos IDs son DISTINTOS y
    // ambos pueden aparecer en g.php como idcurso.
    //
    // Solución: agrupar por (codigo, seccion) y guardar TODOS los IDs
    // en extraIds para que el filtro de horario funcione con cualquiera.

    // Primero agrupamos todas las entradas por clave (codigo|seccion)
    final grupos = <String, List<Map<String, dynamic>>>{};
    for (final e in result.data) {
      final codigo  = (e['codigo']  as String?) ?? '';
      final seccion = (e['seccion'] as String?) ?? '';
      final key = '$codigo|$seccion';
      grupos.putIfAbsent(key, () => []).add(e);
    }

    final entidades = <CursoUsuarioEntity>[];

    for (final grupo in grupos.values) {
      // Preferir la entrada con extra=A para los datos principales
      // (tiene el id correcto para consultar asistencia)
      final entradaA = grupo.firstWhere(
        (e) => (e['extra'] as String?) == 'A',
        orElse: () => grupo.first,
      );

      // Recopilar TODOS los IDs del grupo (puede haber uno o dos)
      final todosLosIds = grupo
          .map((e) => (e['id'] as int?) ?? 0)
          .where((id) => id != 0)
          .toSet();

      entidades.add(CursoUsuarioEntity(
        id:       (entradaA['id']      as int?)    ?? 0,
        nombre:   (entradaA['nombre']  as String?) ?? '',
        codigo:   (entradaA['codigo']  as String?) ?? '',
        seccion:  (entradaA['seccion'] as String?) ?? '',
        rol:      (entradaA['rol']     as String?) ?? 'E',
        extra:    (entradaA['extra']   as String?) ?? '',
        pid:      (entradaA['pid']     as int?)    ?? 0,
        extraIds: todosLosIds,
      ));
    }

    return Success(entidades);
  }
}

// ── Provider de UI ────────────────────────────────────────────────────────────

final misCursosProvider = FutureProvider.family<
    List<CursoUsuarioEntity>,
    ({String usuario, int semestre})>((ref, args) async {
  final repo = ref.watch(misCursosRepositoryProvider);
  final result = await repo.getCursos(args.usuario, args.semestre);
  if (result is Success<List<CursoUsuarioEntity>>) return result.data;
  throw Exception(
    (result as Failure<List<CursoUsuarioEntity>>).error.message,
  );
});