import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/app_error.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/network/dio_client.dart';

// ── Entidades ─────────────────────────────────────────────────────────────────

class AsistenciaResumenEntity {
  final int cursoId;
  final int presentes;
  final int ausentes;
  final int justificados;
  final int total;

  const AsistenciaResumenEntity({
    required this.cursoId,
    required this.presentes,
    required this.ausentes,
    required this.justificados,
    required this.total,
  });

  int get porcentaje =>
      total == 0 ? 0 : ((presentes / total) * 100).round();
}

class AsistenciaClaseEntity {
  final String fecha;
  final String bloque;
  final int estado; // 1=Presente, 0=Ausente, 3=Justificado, -1=Atrasado

  const AsistenciaClaseEntity({
    required this.fecha,
    required this.bloque,
    required this.estado,
  });

  String get estadoTexto => switch (estado) {
        1 => 'Presente',
        0 => 'Ausente',
        3 => 'Justificado',
        -1 => 'Atrasado',
        _ => 'Sin registro',
      };
}

// ── Data source ───────────────────────────────────────────────────────────────

final asistenciaEstudianteRemoteProvider =
    Provider<AsistenciaEstudianteRemoteDataSource>((ref) {
  return AsistenciaEstudianteRemoteDataSource(ref.watch(dioClientProvider));
});

class AsistenciaEstudianteRemoteDataSource {
  final Dio _dio;
  const AsistenciaEstudianteRemoteDataSource(this._dio);

  Future<Result<List<AsistenciaClaseEntity>>> fetchAsistenciaEstudiante(
    int cursoId,
    int semestreId,
    String rutEstudiante,
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

      // Print temporal para debug
      if (data.isNotEmpty) {
        final primeraClase = data.values.first as Map<String, dynamic>;
        final asistentes =
            primeraClase['asistentes'] as Map<String, dynamic>? ?? {};
        print('RUTS EN ASISTENCIA: ${asistentes.keys.take(5).toList()}');
        print('BUSCANDO RUT: $rutEstudiante');
      }

      final clases = <AsistenciaClaseEntity>[];

      for (final entry in data.entries) {
        final clase = entry.value as Map<String, dynamic>;
        final fecha = (clase['fecha'] as String?) ?? '';
        final bloque = (clase['bloque'] as String?) ?? '';
        final asistentes =
            clase['asistentes'] as Map<String, dynamic>? ?? {};

        if (asistentes.containsKey(rutEstudiante)) {
          final est = asistentes[rutEstudiante] as Map<String, dynamic>;
          final estado = (est['estado'] as int?) ?? 0;
          clases.add(AsistenciaClaseEntity(
            fecha: fecha,
            bloque: bloque,
            estado: estado,
          ));
        }
      }

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

typedef AsistenciaArgs = ({int curso, int semestre, String rut});

final asistenciaEstudianteProvider = FutureProvider.family<
    List<AsistenciaClaseEntity>,
    AsistenciaArgs>((ref, args) async {
  final ds = ref.watch(asistenciaEstudianteRemoteProvider);
  final result = await ds.fetchAsistenciaEstudiante(
    args.curso,
    args.semestre,
    args.rut,
  );
  if (result is Success<List<AsistenciaClaseEntity>>) return result.data;
  throw Exception(
    (result as Failure<List<AsistenciaClaseEntity>>).error.message,
  );
});