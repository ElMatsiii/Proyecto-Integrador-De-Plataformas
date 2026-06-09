import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        1  => 'Presente',
        0  => 'Ausente',
        3  => 'Justificado',
        -1 => 'Atrasado',
        _  => 'Sin registro',
      };
}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Extrae solo los dígitos numéricos de un RUT.
/// "9586127K" → "9586127"
/// "216542363" → "216542363" (sin cambios, ya es solo números)
String _rutSoloDigitos(String rut) =>
    rut.replaceAll(RegExp(r'[^0-9]'), '');

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
        '/asist_marcar6.php',
        queryParameters: <String, dynamic>{
          'c': cursoId,
          's': semestreId,
          'op': 'list',
        },
      );

      final data = response.data;
      if (data == null || data.isEmpty) return const Success([]);

      final rutDigitos = _rutSoloDigitos(rutEstudiante);

      // LOG: ver cuántas entradas trae la API y las claves de asistentes
      if (kDebugMode) {
        debugPrint('=== ASISTENCIA DEBUG ===');
        debugPrint('RUT buscado (original): $rutEstudiante');
        debugPrint('RUT buscado (dígitos):  $rutDigitos');
        debugPrint('Total entradas en API:  ${data.length}');
        for (final entry in data.entries) {
          final clase = entry.value;
          if (clase is Map) {
            final asistentes = clase['asistentes'];
            if (asistentes is Map) {
              final claves = asistentes.keys.toList();
              final tieneEstudiante = claves.any(
                (k) => _rutSoloDigitos(k.toString()) == rutDigitos,
              );
              debugPrint(
                'Clase ${entry.key}: '
                '${claves.length} asistentes, '
                'estudiante presente: $tieneEstudiante, '
                'claves: ${claves.take(3)}...',
              );
            } else {
              debugPrint('Clase ${entry.key}: asistentes no es Map → ${asistentes.runtimeType}');
            }
          }
        }
        debugPrint('========================');
      }

      final clases = <AsistenciaClaseEntity>[];

      for (final entry in data.entries) {
        final clase = entry.value;
        if (clase is! Map) continue;
        final claseMap = clase.cast<String, dynamic>();

        final fecha  = (claseMap['fecha']  as String?) ?? '';
        final bloque = (claseMap['bloque'] as String?) ?? '';

        final asistentesRaw = claseMap['asistentes'];

        // Caso 1: asistentes es un Map (caso normal)
        if (asistentesRaw is Map) {
          final asistentes = asistentesRaw.cast<String, dynamic>();

          // Buscar por dígitos exactos
          dynamic estudianteData = asistentes[rutDigitos];

          // Fallback: buscar comparando solo dígitos de la clave
          if (estudianteData == null) {
            for (final k in asistentes.keys) {
              if (_rutSoloDigitos(k) == rutDigitos) {
                estudianteData = asistentes[k];
                break;
              }
            }
          }

          if (estudianteData == null) continue;

          final estadoRaw = estudianteData is Map
              ? estudianteData['estado']
              : null;

          clases.add(AsistenciaClaseEntity(
            fecha:  fecha,
            bloque: bloque,
            estado: _parseEstado(estadoRaw),
          ));
        }
        // Caso 2: asistentes es una Lista (formato alternativo que usa la API
        // en algunas versiones — cada elemento tiene 'rut' y 'estado')
        else if (asistentesRaw is List) {
          for (final item in asistentesRaw) {
            if (item is! Map) continue;
            final itemRut = _rutSoloDigitos(
              (item['rut'] ?? item['pid'] ?? '').toString(),
            );
            if (itemRut != rutDigitos) continue;
            clases.add(AsistenciaClaseEntity(
              fecha:  fecha,
              bloque: bloque,
              estado: _parseEstado(item['estado']),
            ));
            break;
          }
        }
      }

      clases.sort((a, b) =>
          '${b.fecha}:${b.bloque}'.compareTo('${a.fecha}:${a.bloque}'));

      if (kDebugMode) {
        debugPrint('Clases encontradas para el estudiante: ${clases.length}');
      }

      return Success(clases);
    } on DioException catch (e) {
      return Failure(dioToAppError(e));
    } catch (e) {
      return Failure(UnknownError(e.toString()));
    }
  }

  int _parseEstado(dynamic raw) {
    if (raw is int)    return raw;
    if (raw is double) return raw.toInt();
    if (raw is String) return int.tryParse(raw) ?? 0;
    return 0;
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