import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tongoy_app/core/errors/app_error.dart';
import 'package:tongoy_app/core/errors/result.dart';
import 'package:tongoy_app/features/horario/domain/entities/horario_entity.dart';
import 'package:tongoy_app/features/horario/domain/repositories/i_horario_repository.dart';
import 'package:tongoy_app/features/horario/domain/usecases/horario_usecases.dart';

// Mock del repositorio
class MockHorarioRepository extends Mock implements IHorarioRepository {}

void main() {
  late MockHorarioRepository mockRepo;
  late GetHorarioUseCase getHorario;
  late GetMasterUseCase getMaster;

  setUp(() {
    mockRepo = MockHorarioRepository();
    getHorario = GetHorarioUseCase(mockRepo);
    getMaster = GetMasterUseCase(mockRepo);
  });

  group('GetHorarioUseCase', () {
    final filtro = HorarioFiltro(semestre: 6);
    final itemsFake = [
      const HorarioItemEntity(
        id: 1,
        dia: 'Lunes',
        bloque: 'A',
        sala: 'CQB X-101',
        curso: 'Introducción a la Ingeniería',
        idCurso: 100,
        nrc: '12345',
        profesor: 'Ross Eric',
        area: 'Escuela de Ingeniería',
        comentario: '',
        carreras: [],
      ),
    ];

    test('retorna lista de items cuando el repositorio tiene éxito', () async {
      when(() => mockRepo.getHorario(filtro))
          .thenAnswer((_) async => Success(itemsFake));

      final result = await getHorario(filtro);

      expect(result, isA<Success<List<HorarioItemEntity>>>());
      expect(result.dataOrNull, hasLength(1));
      expect(result.dataOrNull?.first.profesor, 'Ross Eric');
    });

    test('retorna Failure cuando el repositorio falla', () async {
      when(() => mockRepo.getHorario(filtro))
          .thenAnswer((_) async => const Failure(NetworkError()));

      final result = await getHorario(filtro);

      expect(result, isA<Failure<List<HorarioItemEntity>>>());
      expect(result.errorOrNull, isA<NetworkError>());
    });

    test('HorarioFiltro.copyWith mantiene valores no modificados', () {
      const original = HorarioFiltro(semestre: 6, area: 12);
      final copia = original.copyWith(profesor: 120);

      expect(copia.semestre, 6);
      expect(copia.area, 12);
      expect(copia.profesor, 120);
      expect(copia.sala, -1); // valor por defecto
    });
  });

  group('GetMasterUseCase', () {
    final masterFake = MasterEntity(
      areas: [],
      dias: [],
      bloques: [],
      salas: [],
      cursos: [],
      profesores: [],
      semestres: [],
    );

    test('retorna MasterEntity cuando el repositorio tiene éxito', () async {
      when(() => mockRepo.getMaster(forceRefresh: false))
          .thenAnswer((_) async => Success(masterFake));

      final result = await getMaster();

      expect(result, isA<Success<MasterEntity>>());
    });

    test('forceRefresh se pasa correctamente al repositorio', () async {
      when(() => mockRepo.getMaster(forceRefresh: true))
          .thenAnswer((_) async => Success(masterFake));

      await getMaster(forceRefresh: true);

      verify(() => mockRepo.getMaster(forceRefresh: true)).called(1);
    });
  });
}
