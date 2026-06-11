import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tongoy_app/features/auth/presentation/providers/auth_provider_notif.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';

class AsistenciaCursoEntity {
  final String nombre;
  final String codigo;
  final String seccion;
  final int porcentaje;
  final int presentes;
  final int total;

  const AsistenciaCursoEntity({
    required this.nombre,
    required this.codigo,
    required this.seccion,
    required this.porcentaje,
    required this.presentes,
    required this.total,
  });

  int get ausentes => total - presentes;
}

class NotaCursoEntity {
  final String nombre;
  final String nota;

  const NotaCursoEntity({required this.nombre, required this.nota});
}

class NotasCursoEntity {
  final String codigo;
  final String asignatura;
  final String seccion;
  final List<NotaCursoEntity> notas;

  const NotasCursoEntity({
    required this.codigo,
    required this.asignatura,
    required this.seccion,
    required this.notas,
  });
}

final notasRemoteProvider = Provider<NotasRemoteDataSource>((ref) {
  return NotasRemoteDataSource(ref.watch(dioClientProvider));
});

/// Convierte un valor dinámico de la API a int de forma segura.
int _toInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

/// Lee la primera clave que exista de una lista de candidatos.
dynamic _firstKey(Map<String, dynamic> map, List<String> candidatos) {
  for (final k in candidatos) {
    if (map.containsKey(k) && map[k] != null) return map[k];
  }
  return null;
}

class NotasRemoteDataSource {
  final Dio _dio;
  const NotasRemoteDataSource(this._dio);

  Future<List<AsistenciaCursoEntity>> fetchAsistencias(int semestreId) async {
    final response = await _dio.get<List<dynamic>>(
      ApiConstants.notasEstudiante,
      queryParameters: <String, dynamic>{'s': semestreId, 'op': 'as'},
    );
    final list = response.data ?? [];

    return list.cast<Map<String, dynamic>>().map((e) {
      final porcentaje = _toInt(
        _firstKey(e, ['porcentaje', 'por', 'pct', 'porc']),
      );
      final presentes = _toInt(
        _firstKey(e, ['presentes', 'pre', 'asistidas', 'asistencias']),
      );
      final total = _toInt(
        _firstKey(e, ['total', 'tot', 'clases', 'sesiones']),
      );

      return AsistenciaCursoEntity(
        nombre: (e['nombre'] as String?) ?? '',
        codigo: (e['codigo'] as String?) ?? '',
        seccion: (e['seccion'] as String?) ?? '',
        porcentaje: porcentaje,
        presentes: presentes,
        total: total,
      );
    }).toList();
  }

  Future<List<NotasCursoEntity>> fetchNotas(int semestreId) async {
    final response = await _dio.get<List<dynamic>>(
      ApiConstants.notasEstudiante,
      queryParameters: <String, dynamic>{'s': semestreId, 'op': 'list'},
    );
    final list = response.data ?? [];
    return list.cast<Map<String, dynamic>>().map((e) {
      final notasRaw =
          (e['notas'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
      return NotasCursoEntity(
        codigo: (e['codigo'] as String?) ?? '',
        asignatura: (e['asignatura'] as String?) ?? '',
        seccion: (e['seccion'] as String?) ?? '',
        notas: notasRaw
            .map((n) => NotaCursoEntity(
                  nombre: (n['nombre'] as String?) ?? '',
                  nota: (n['nota'] as String?) ?? '',
                ),)
            .where((n) =>
                n.nota.isNotEmpty &&
                n.nombre != 'Nombre' &&
                n.nombre != 'Par',)
            .toList(),
      );
    }).toList();
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final asistenciasProvider =
    FutureProvider.family<List<AsistenciaCursoEntity>, int>(
        (ref, semestreId) async {
  final usuario = ref.watch(currentUserProvider);
  if (usuario == null) return [];

  final ds = ref.watch(notasRemoteProvider);
  return ds.fetchAsistencias(semestreId);
});

final notasProvider =
    FutureProvider.family<List<NotasCursoEntity>, int>(
        (ref, semestreId) async {
  final usuario = ref.watch(currentUserProvider);
  if (usuario == null) return [];

  final ds = ref.watch(notasRemoteProvider);
  return ds.fetchNotas(semestreId);
});