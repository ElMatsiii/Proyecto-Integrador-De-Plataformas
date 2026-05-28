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
      if (cached != null) return Success(cached);
    }

    final result = await _remote.fetchMaster();
    if (result is Success<MasterDto>) {
      await _cacheMaster(result.data);
      return Success(result.data.toEntity());
    }
    return Failure((result as Failure).error);
  }

  @override
  Future<Result<List<HorarioItemEntity>>> getHorario(
      HorarioFiltro filtro,) async {
    final result = await _remote.fetchHorario(filtro);
    return result.when(
      success: (dtos) => Success(dtos.map((d) => d.toEntity()).toList()),
      failure: (e) => Failure(e),
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
      'areas': dto.areas
          .map((e) => {'id': e.id, 'nombre': e.nombre})
          .toList(),
      'dias': dto.dias
          .map((e) => {'id': e.id, 'nombre': e.nombre, 'dotw': e.dotw})
          .toList(),
      'bloques': dto.bloques
          .map((e) => {'id': e.id, 'nombre': e.nombre, 'horario': e.horario})
          .toList(),
      'salas': dto.salas
          .map((e) => {
                'id': e.id,
                'nombre': e.nombre,
                'sector': e.sector,
                'capacidad': e.capacidad,
              })
          .toList(),
      'cursos': dto.cursos
          .map((e) => {'id': e.id, 'nombre': e.nombre})
          .toList(),
      'profesores': dto.profesores
          .map((e) => {'id': e.id, 'nombre': e.nombre})
          .toList(),
      'semestres': dto.semestres
          .map((e) => {
                'id': e.id,
                'nombre': e.nombre,
                'primer_lunes': e.primerLunes,
                'ultimo_domingo': e.ultimoDomingo,
                'es_actual': e.esActual ? 1 : 0,
              })
          .toList(),
    };
  }
}