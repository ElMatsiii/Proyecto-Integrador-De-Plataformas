import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tongoy_app/features/auth/presentation/providers/auth_provider_notif.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/json_read.dart';
import '../domain/entities/notas_entities.dart';

export '../domain/entities/notas_entities.dart';

final notasRemoteProvider = Provider<NotasRemoteDataSource>((ref) {
  return NotasRemoteDataSource(ref.watch(dioClientProvider));
});

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

    return asJsonMapList(response.data).map((e) {
      final porcentaje = readInt(
        _firstKey(e, ['porcentaje', 'por', 'pct', 'porc']),
      );
      final presentes = readInt(
        _firstKey(e, ['presentes', 'pre', 'asistidas', 'asistencias']),
      );
      final total = readInt(
        _firstKey(e, ['total', 'tot', 'clases', 'sesiones']),
      );

      return AsistenciaCursoEntity(
        nombre: readString(e['nombre']),
        codigo: readString(e['codigo']),
        seccion: readString(e['seccion']),
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

    return asJsonMapList(response.data).map((e) {
      final notasRaw = asJsonMapList(e['notas']);
      return NotasCursoEntity(
        codigo: readString(e['codigo']),
        asignatura: readString(e['asignatura']),
        seccion: readString(e['seccion']),
        notas: notasRaw
            .map(
              (n) => NotaCursoEntity(
                nombre: readString(n['nombre']),
                nota: readString(n['nota']),
              ),
            )
            .where(
              (n) =>
                  n.nota.isNotEmpty &&
                  n.nombre != 'Nombre' &&
                  n.nombre != 'Par',
            )
            .toList(),
      );
    }).toList();
  }
}

final asistenciasProvider =
    FutureProvider.family<List<AsistenciaCursoEntity>, int>(
  (ref, semestreId) async {
    final usuario = ref.watch(currentUserProvider);
    if (usuario == null) return [];

    final ds = ref.watch(notasRemoteProvider);
    return ds.fetchAsistencias(semestreId);
  },
);

final notasProvider = FutureProvider.family<List<NotasCursoEntity>, int>(
  (ref, semestreId) async {
    final usuario = ref.watch(currentUserProvider);
    if (usuario == null) return [];

    final ds = ref.watch(notasRemoteProvider);
    return ds.fetchNotas(semestreId);
  },
);
