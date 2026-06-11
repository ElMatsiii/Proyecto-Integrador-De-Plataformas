import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/app_error.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/json_read.dart';
import '../domain/entities/curso_usuario_entity.dart';
import '../domain/repositories/i_mis_cursos_repository.dart';

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
      final errorData = asJsonMap(data);
      if (errorData != null && errorData['status'] == 'error') {
        return Failure(ServerError(readString(errorData['mensaje'])));
      }
      return Success(asJsonMapList(data));
    } on DioException catch (e) {
      return Failure(dioToAppError(e));
    } catch (e) {
      return Failure(UnknownError(e.toString()));
    }
  }
}

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

    final grupos = <String, List<Map<String, dynamic>>>{};
    for (final e in result.data) {
      final codigo = readString(e['codigo']);
      final seccion = readString(e['seccion']);
      if (codigo.isEmpty && seccion.isEmpty) continue;
      final key = '$codigo|$seccion';
      grupos.putIfAbsent(key, () => []).add(e);
    }

    final entidades = <CursoUsuarioEntity>[];

    for (final grupo in grupos.values) {
      final entradaA = grupo.firstWhere(
        (e) => readString(e['extra']) == 'A',
        orElse: () => grupo.first,
      );

      final todosLosIds =
          grupo.map((e) => readInt(e['id'])).where((id) => id != 0).toSet();

      entidades.add(
        CursoUsuarioEntity(
          id: readInt(entradaA['id']),
          nombre: readString(entradaA['nombre']),
          codigo: readString(entradaA['codigo']),
          seccion: readString(entradaA['seccion']),
          rol: readString(entradaA['rol'], fallback: 'E'),
          extra: readString(entradaA['extra']),
          pid: readInt(entradaA['pid']),
          extraIds: todosLosIds,
        ),
      );
    }

    return Success(entidades);
  }
}

final misCursosProvider = FutureProvider.family<List<CursoUsuarioEntity>,
    ({String usuario, int semestre})>((ref, args) async {
  final repo = ref.watch(misCursosRepositoryProvider);
  final result = await repo.getCursos(args.usuario, args.semestre);
  if (result is Success<List<CursoUsuarioEntity>>) return result.data;
  throw Exception(
    (result as Failure<List<CursoUsuarioEntity>>).error.message,
  );
});
