import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/result.dart';
import '../../domain/entities/horario_entity.dart';
import '../../domain/repositories/i_horario_repository.dart';
import '../datasources/horario_remote_datasource.dart';
import '../models/horario_dto.dart';

final horarioRepositoryProvider = Provider<IHorarioRepository>((ref) {
  return HorarioRepository(ref.watch(horarioRemoteDataSourceProvider));
});

class HorarioRepository implements IHorarioRepository {
  final HorarioRemoteDataSource _remote;

  static const _cacheDurationHours = 24;

  const HorarioRepository(this._remote);

  @override
  Future<Result<MasterEntity>> getMaster({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await _getCachedMaster();
      if (cached != null) return Success(_filtrarAntofagasta(cached));
    }

    final result = await _remote.fetchMaster();
    if (result is Success<MasterDto>) {
      final entity = result.data.toEntity();
      // Si el área llegó vacía (respuesta parcial/transitoria del backend),
      // no la cacheamos: así el próximo intento vuelve a pedirla en vez de
      // quedar 24h mostrando el filtro de área vacío.
      if (entity.areas.isNotEmpty) {
        await _cacheMaster(result.data);
      }
      return Success(_filtrarAntofagasta(entity));
    }
    return Failure((result as Failure).error);
  }

  @override
  Future<Result<List<HorarioItemEntity>>> getHorario(
    HorarioFiltro filtro,
  ) async {
    final result = await _remote.fetchHorario(filtro);
    return result.when(
      success: (dtos) => Success(
        dtos
            .map((d) => d.toEntity())
            .where((i) => !_contieneAntofagasta(i.area, i.sala))
            .toList(),
      ),
      failure: (e) => Failure(e),
    );
  }

  // ── Filtro de datos de la sede de Antofagasta ──────────────────────────────
  // La app es exclusiva para la sede Coquimbo; se descarta cualquier área,
  // sala o profesor cuyo nombre haga referencia a Antofagasta para que no
  // aparezca ni en los filtros ni en los resultados de horario.

  bool _contieneAntofagasta(String a, [String b = '']) {
    final texto = '$a $b'.toLowerCase();
    return texto.contains('antofagasta');
  }

  MasterEntity _filtrarAntofagasta(MasterEntity m) {
    return MasterEntity(
      areas: m.areas.where((a) => !_contieneAntofagasta(a.nombre)).toList(),
      dias: m.dias,
      bloques: m.bloques,
      salas: m.salas.where((s) => !_contieneAntofagasta(s.nombre, s.sector)).toList(),
      cursos: m.cursos,
      profesores: m.profesores
          .where((p) => !_contieneAntofagasta(p.nombre))
          .toList(),
      semestres: m.semestres,
    );
  }

  // ── Caché ────────────────────────────────────────────────────────────────

  Future<MasterEntity?> _getCachedMaster() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timeStr = prefs.getString(StorageKeys.masterCacheTime);
      if (timeStr == null) return null;

      final cacheTime = DateTime.tryParse(timeStr);
      if (cacheTime == null) return null;

      final age = DateTime.now().difference(cacheTime).inHours;
      if (age >= _cacheDurationHours) return null;

      final raw = prefs.getString(StorageKeys.masterCache);
      if (raw == null) return null;

      final json = jsonDecode(raw) as Map<String, dynamic>;
      return MasterDto.fromJson(json).toEntity();
    } catch (_) {
      return null;
    }
  }

  Future<void> _cacheMaster(MasterDto dto) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Serializar el DTO completo a JSON
      final json = _masterDtoToJson(dto);
      final raw = jsonEncode(json);

      await prefs.setString(StorageKeys.masterCache, raw);
      await prefs.setString(
        StorageKeys.masterCacheTime,
        DateTime.now().toIso8601String(),
      );
    } catch (_) {
      // No crítico: la próxima vez simplemente vuelve a fetchear
    }
  }

  Map<String, dynamic> _masterDtoToJson(MasterDto dto) {
    return {
      'areas': dto.areas.map((e) => {'id': e.id, 'nombre': e.nombre}).toList(),
      'dias': dto.dias
          .map((e) => {'id': e.id, 'nombre': e.nombre, 'dotw': e.dotw})
          .toList(),
      'bloques': dto.bloques
          .map((e) => {'id': e.id, 'nombre': e.nombre, 'horario': e.horario})
          .toList(),
      'salas': dto.salas
          .map(
            (e) => {
              'id': e.id,
              'nombre': e.nombre,
              'sector': e.sector,
              'capacidad': e.capacidad,
            },
          )
          .toList(),
      'cursos':
          dto.cursos.map((e) => {'id': e.id, 'nombre': e.nombre}).toList(),
      'profesores':
          dto.profesores.map((e) => {'id': e.id, 'nombre': e.nombre}).toList(),
      'semestres': dto.semestres
          .map(
            (e) => {
              'id': e.id,
              'nombre': e.nombre,
              'primer_lunes': e.primerLunes,
              'ultimo_domingo': e.ultimoDomingo,
              'es_actual': e.esActual ? 1 : 0,
            },
          )
          .toList(),
    };
  }
}