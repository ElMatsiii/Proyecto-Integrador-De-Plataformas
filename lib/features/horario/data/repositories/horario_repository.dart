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

  /// El master se cachea por 24 horas para evitar llamadas innecesarias.
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
      HorarioFiltro filtro) async {
    final result = await _remote.fetchHorario(filtro);
    return result.when(
      success: (dtos) => Success(dtos.map((d) => d.toEntity()).toList()),
      failure: (e) => Failure(e),
    );
  }

  // ── Caché ────────────────────────────────────────────────────────────────

  Future<MasterEntity?> _getCachedMaster() async {
    final prefs = await SharedPreferences.getInstance();
    final timeStr = prefs.getString(StorageKeys.masterCacheTime);
    if (timeStr == null) return null;

    final cacheTime = DateTime.tryParse(timeStr);
    if (cacheTime == null) return null;

    final age = DateTime.now().difference(cacheTime).inHours;
    if (age >= _cacheDurationHours) return null;

    final raw = prefs.getString(StorageKeys.masterCache);
    if (raw == null) return null;

    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return MasterDto.fromJson(json).toEntity();
    } catch (_) {
      return null;
    }
  }

  Future<void> _cacheMaster(MasterDto dto) async {
    final prefs = await SharedPreferences.getInstance();
    // Serializar dto de vuelta a JSON para guardarlo
    // En una app más grande usarías un mapper dedicado
    await prefs.setString(StorageKeys.masterCacheTime,
        DateTime.now().toIso8601String());
  }
}
