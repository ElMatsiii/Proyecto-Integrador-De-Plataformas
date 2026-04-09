import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/app_error.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/horario_entity.dart';
import '../models/horario_dto.dart';


final horarioRemoteDataSourceProvider =
    Provider<HorarioRemoteDataSource>((ref) {
  return HorarioRemoteDataSource(ref.watch(dioClientProvider));
});

class HorarioRemoteDataSource {
  final Dio _dio;
  const HorarioRemoteDataSource(this._dio);

  Future<Result<MasterDto>> fetchMaster() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.master,
      );
      final data = response.data;
      if (data == null) return const Failure(ServerError('Respuesta vacía'));
      return Success(MasterDto.fromJson(data));
    } on DioException catch (e) {
      return Failure(dioToAppError(e));
    } catch (e) {
      return Failure(UnknownError(e.toString()));
    }
  }

  Future<Result<List<HorarioItemDto>>> fetchHorario(
    HorarioFiltro filtro,
  ) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        ApiConstants.horario,
        queryParameters: <String, dynamic>{
          'sala': filtro.sala,
          'curso': filtro.curso,
          'profesor': filtro.profesor,
          'semestre': filtro.semestre,
          'semestrec': filtro.semestreC,
          'carrera': filtro.carrera,
          'area': filtro.area,
        },
      );
      final list = response.data ?? [];
      return Success(
        list
            .cast<Map<String, dynamic>>()
            .map(HorarioItemDto.fromJson)
            .toList(),
      );
    } on DioException catch (e) {
      return Failure(dioToAppError(e));
    } catch (e) {
      return Failure(UnknownError(e.toString()));
    }
  }
}
