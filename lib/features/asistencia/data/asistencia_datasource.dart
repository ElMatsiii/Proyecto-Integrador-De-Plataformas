import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/app_error.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/network/dio_client.dart';
import '../../../mis_cursos/domain/entities/curso_usuario_entity.dart';

// ── Entidades ─────────────────────────────────────────────────────────────────

class AsistenciaClaseEntity {
  final String fecha;
  final String bloque;
  final Map<String, AsistenciaEstudianteEntity> asistentes;

  const AsistenciaClaseEntity({
    required this.fecha,
    required this.bloque,
    required this.asistentes,
  });
}

class AsistenciaEstudianteEntity {
  final String rut;
  final String nombres;
  final String apellidos;

  /// 1=Presente, 0=Ausente, 3=Justificado, -1=Atrasado
  final int estado;
  final String razon;

  const AsistenciaEstudianteEntity({
    required this.rut,
    required this.nombres,
    required this.apellidos,
    required this.estado,
    required this.razon,
  });

  String get nombreCompleto => '$nombres $apellidos';

  String get estadoTexto => switch (estado) {
        1 => 'Presente',
        0 => 'Ausente',
        3 => 'Justificado',
        -1 => 'Atrasado',
        _ => 'Desconocido',
      };
}

// ── Data source ───────────────────────────────────────────────────────────────

final asistenciaRemoteProvider = Provider<AsistenciaRemoteDataSource>((ref) {
  return AsistenciaRemoteDataSource(ref.watch(dioClientProvider));
});

class AsistenciaRemoteDataSource {
  final Dio _dio;
  const AsistenciaRemoteDataSource(this._dio);

  Future<Result<List<AsistenciaClaseEntity>>> fetchAsistencia(
    int cursoId,
    int semestreId,
  ) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.asistenciaList,
        queryParameters: <String, dynamic>{
          'c': cursoId,
          's': semestreId,
          'op': 'list',
        },
      );

      final data = response.data;
      if (data == null) return const Success([]);

      final clases = data.entries.map((entry) {
        final clase = entry.value as Map<String, dynamic>;
        final asistentesRaw =
            clase['asistentes'] as Map<String, dynamic>? ?? {};

        final asistentes = asistentesRaw.map((rut, est) {
          final e = est as Map<String, dynamic>;
          return MapEntry(
            rut,
            AsistenciaEstudianteEntity(
              rut: (e['rut'] as String?) ?? rut,
              nombres: (e['nombres'] as String?) ?? '',
              apellidos: (e['apellidos'] as String?) ?? '',
              estado: (e['estado'] as int?) ?? 0,
              razon: (e['razon'] as String?) ?? '',
            ),
          );
        });

        return AsistenciaClaseEntity(
          fecha: (clase['fecha'] as String?) ?? '',
          bloque: (clase['bloque'] as String?) ?? '',
          asistentes: asistentes,
        );
      }).toList();

      clases.sort((a, b) =>
          '${b.fecha}:${b.bloque}'.compareTo('${a.fecha}:${a.bloque}'));

      return Success(clases);
    } on DioException catch (e) {
      return Failure(dioToAppError(e));
    } catch (e) {
      return Failure(UnknownError(e.toString()));
    }
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final cursoSeleccionadoProvider =
    StateProvider<CursoUsuarioEntity?>((ref) => null);

final asistenciaProvider = FutureProvider.family<
    List<AsistenciaClaseEntity>,
    ({int curso, int semestre})>((ref, args) async {
  final ds = ref.watch(asistenciaRemoteProvider);
  final result = await ds.fetchAsistencia(args.curso, args.semestre);
  if (result is Success<List<AsistenciaClaseEntity>>) return result.data;
  throw Exception(
    (result as Failure<List<AsistenciaClaseEntity>>).error.message,
  );
});
