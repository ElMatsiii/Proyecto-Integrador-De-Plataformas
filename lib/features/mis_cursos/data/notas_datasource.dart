import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';

class AsistenciaCursoEntity {
  final String nombre;
  final String codigo;
  final String seccion;
  final int porcentaje;

  const AsistenciaCursoEntity({
    required this.nombre,
    required this.codigo,
    required this.seccion,
    required this.porcentaje,
  });
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
      return AsistenciaCursoEntity(
        nombre: (e['nombre'] as String?) ?? '',
        codigo: (e['codigo'] as String?) ?? '',
        seccion: (e['seccion'] as String?) ?? '',
        porcentaje: int.tryParse((e['porcentaje'] as String?) ?? '0') ?? 0,
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

final asistenciasProvider =
    FutureProvider.family<List<AsistenciaCursoEntity>, int>(
        (ref, semestreId) async {
  final ds = ref.watch(notasRemoteProvider);
  return ds.fetchAsistencias(semestreId);
});

final notasProvider =
    FutureProvider.family<List<NotasCursoEntity>, int>(
        (ref, semestreId) async {
  final ds = ref.watch(notasRemoteProvider);
  return ds.fetchNotas(semestreId);
});
