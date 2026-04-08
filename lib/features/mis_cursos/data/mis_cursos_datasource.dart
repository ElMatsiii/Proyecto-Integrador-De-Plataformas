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
    if (result is Success<List<Map<String, dynamic>>>) {
      final entidades = result.data.map((Map<String, dynamic> e) {
        return CursoUsuarioEntity(
          id: (e['id'] as int?) ?? 0,
          nombre: (e['nombre'] as String?) ?? '',
          codigo: (e['codigo'] as String?) ?? '',
          seccion: (e['seccion'] as String?) ?? '',
          rol: (e['rol'] as String?) ?? 'E',
          extra: (e['extra'] as String?) ?? '',
        );
      }).toList();
      return Success(entidades);
    }
    return Failure((result as Failure<List<Map<String, dynamic>>>).error);
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
