import 'package:flutter_test/flutter_test.dart';
import 'package:hawaii_app/core/errors/app_error.dart';
import 'package:hawaii_app/core/errors/result.dart';
import 'package:hawaii_app/features/horario/domain/entities/horario_entity.dart';
import 'package:hawaii_app/features/horario/domain/repositories/i_horario_repository.dart';
import 'package:hawaii_app/features/horario/domain/usecases/horario_usecases.dart';
import 'package:mocktail/mocktail.dart';

class MockHorarioRepository extends Mock implements IHorarioRepository {}

class _FakeHorarioFiltro extends Fake implements HorarioFiltro {}

// ── Fixtures ──────────────────────────────────────────────────────────────────

const _masterVacio = MasterEntity(
  areas: [], dias: [], bloques: [], salas: [],
  cursos: [], profesores: [], semestres: [],
);

MasterEntity _masterConSemestres() => MasterEntity(
      areas: [],
      dias: [],
      bloques: const [
        BloqueEntity(id: 1, nombre: 'A', horario: '08:10 - 09:40'),
        BloqueEntity(id: 2, nombre: 'B', horario: '09:50 - 11:20'),
      ],
      salas: const [SalaEntity(id: 1, nombre: 'X-101', sector: 'X')],
      cursos: const [CursoEntity(id: 10, nombre: 'Algoritmos')],
      profesores: const [ProfesorEntity(id: 5, nombre: 'García')],
      semestres: [
        SemestreEntity(
          id: 6,
          nombre: '2025-1',
          primerLunes: DateTime(2025, 3, 10),
          ultimoDomingo: DateTime(2025, 7, 6),
          esActual: true,
        ),
        SemestreEntity(
          id: 5,
          nombre: '2024-2',
          primerLunes: DateTime(2024, 8, 5),
          ultimoDomingo: DateTime(2024, 12, 1),
        ),
      ],
    );

List<HorarioItemEntity> _itemsFake() => [
      const HorarioItemEntity(
        id: 1,
        dia: 'Lunes',
        bloque: 'A',
        sala: 'X-101',
        curso: 'Algoritmos (ALG-100)',
        idCurso: 100,
        nrc: '12345',
        profesor: 'García Mario',
        area: 'Ingeniería',
        comentario: '',
        carreras: [CarreraEnHorario(id: 1, nombre: 'Informática', semestre: 3)],
      ),
      const HorarioItemEntity(
        id: 2,
        dia: 'Martes',
        bloque: 'B',
        sala: 'Y-202',
        curso: 'Cálculo (MAT-100)',
        idCurso: 200,
        nrc: '54321',
        profesor: 'López Ana',
        area: 'Matemáticas',
        comentario: '',
        carreras: [],
      ),
    ];

void main() {
  late MockHorarioRepository mockRepo;
  late GetHorarioUseCase getHorario;
  late GetMasterUseCase getMaster;

  setUpAll(() {
    registerFallbackValue(_FakeHorarioFiltro());
  });

  setUp(() {
    mockRepo = MockHorarioRepository();
    getHorario = GetHorarioUseCase(mockRepo);
    getMaster = GetMasterUseCase(mockRepo);
  });

  // ── GetHorarioUseCase ─────────────────────────────────────────────────────

  group('GetHorarioUseCase', () {
    const filtroBase = HorarioFiltro(semestre: 6);

    test('retorna lista de items cuando el repo tiene éxito', () async {
      final items = _itemsFake();
      when(() => mockRepo.getHorario(filtroBase))
          .thenAnswer((_) async => Success(items));

      final result = await getHorario(filtroBase);

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, hasLength(2));
    });

    test('retorna Failure(NetworkError) cuando no hay conexión', () async {
      when(() => mockRepo.getHorario(filtroBase))
          .thenAnswer((_) async => const Failure(NetworkError()));

      final result = await getHorario(filtroBase);

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<NetworkError>());
    });

    test('retorna Failure(ServerError) con statusCode 500', () async {
      when(() => mockRepo.getHorario(filtroBase))
          .thenAnswer((_) async =>
              const Failure(ServerError('Internal Server Error', statusCode: 500)),);

      final result = await getHorario(filtroBase);

      expect(result.isFailure, isTrue);
      final error = result.errorOrNull as ServerError;
      expect(error.statusCode, 500);
    });

    test('lista vacía es un caso de éxito válido', () async {
      when(() => mockRepo.getHorario(filtroBase))
          .thenAnswer((_) async => const Success([]));

      final result = await getHorario(filtroBase);

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, isEmpty);
    });

    test('delega el filtro exacto al repositorio', () async {
      const filtro = HorarioFiltro(
        semestre: 6,
        area: 3,
        sala: 1,
        profesor: 5,
        semestreC: 2,
      );
      when(() => mockRepo.getHorario(filtro))
          .thenAnswer((_) async => const Success([]));

      await getHorario(filtro);

      verify(() => mockRepo.getHorario(filtro)).called(1);
    });

    test('el repositorio se llama exactamente una vez por invocación', () async {
      when(() => mockRepo.getHorario(filtroBase))
          .thenAnswer((_) async => const Success([]));

      await getHorario(filtroBase);

      verify(() => mockRepo.getHorario(filtroBase)).called(1);
      verifyNoMoreInteractions(mockRepo);
    });

    test('datos del primer item son correctos', () async {
      when(() => mockRepo.getHorario(filtroBase))
          .thenAnswer((_) async => Success(_itemsFake()));

      final result = await getHorario(filtroBase);

      final item = result.dataOrNull!.first;
      expect(item.dia, 'Lunes');
      expect(item.bloque, 'A');
      expect(item.profesor, 'García Mario');
      expect(item.idCurso, 100);
      expect(item.carreras, hasLength(1));
      expect(item.carreras.first.id, 1);
    });
  });

  // ── GetMasterUseCase ──────────────────────────────────────────────────────

  group('GetMasterUseCase', () {
    test('retorna MasterEntity cuando el repo tiene éxito', () async {
      when(() => mockRepo.getMaster(forceRefresh: false))
          .thenAnswer((_) async => const Success(_masterVacio));

      final result = await getMaster();

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, isA<MasterEntity>());
    });

    test('retorna el master con todos sus campos poblados', () async {
      final master = _masterConSemestres();
      when(() => mockRepo.getMaster(forceRefresh: false))
          .thenAnswer((_) async => Success(master));

      final result = await getMaster();

      final data = result.dataOrNull!;
      expect(data.semestres, hasLength(2));
      expect(data.bloques, hasLength(2));
      expect(data.salas, hasLength(1));
      expect(data.cursos, hasLength(1));
      expect(data.profesores, hasLength(1));
    });

    test('el semestre esActual se identifica correctamente', () async {
      final master = _masterConSemestres();
      when(() => mockRepo.getMaster(forceRefresh: false))
          .thenAnswer((_) async => Success(master));

      final result = await getMaster();

      final actual = result.dataOrNull!.semestres.where((s) => s.esActual);
      expect(actual, hasLength(1));
      expect(actual.first.id, 6);
      expect(actual.first.nombre, '2025-1');
    });

    test('forceRefresh=false es el valor por defecto', () async {
      when(() => mockRepo.getMaster(forceRefresh: false))
          .thenAnswer((_) async => const Success(_masterVacio));

      await getMaster();

      verify(() => mockRepo.getMaster(forceRefresh: false)).called(1);
      verifyNever(() => mockRepo.getMaster(forceRefresh: true));
    });

    test('forceRefresh=true se pasa correctamente al repositorio', () async {
      when(() => mockRepo.getMaster(forceRefresh: true))
          .thenAnswer((_) async => const Success(_masterVacio));

      await getMaster(forceRefresh: true);

      verify(() => mockRepo.getMaster(forceRefresh: true)).called(1);
    });

    test('retorna Failure cuando el repo falla', () async {
      when(() => mockRepo.getMaster(forceRefresh: false))
          .thenAnswer((_) async => const Failure(NetworkError()));

      final result = await getMaster();

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<NetworkError>());
    });

    test('el repositorio se llama exactamente una vez', () async {
      when(() => mockRepo.getMaster(forceRefresh: false))
          .thenAnswer((_) async => const Success(_masterVacio));

      await getMaster();

      verify(() => mockRepo.getMaster(forceRefresh: false)).called(1);
      verifyNoMoreInteractions(mockRepo);
    });
  });

  // ── Interacción entre use cases ───────────────────────────────────────────

  group('combinación de use cases', () {
    test('getMaster y getHorario usan el mismo repositorio sin conflicto',
        () async {
      when(() => mockRepo.getMaster(forceRefresh: false))
          .thenAnswer((_) async => const Success(_masterVacio));
      when(() => mockRepo.getHorario(any()))
          .thenAnswer((_) async => const Success([]));

      final masterResult = await getMaster();
      final horarioResult = await getHorario(const HorarioFiltro(semestre: 6));

      expect(masterResult.isSuccess, isTrue);
      expect(horarioResult.isSuccess, isTrue);
      verify(() => mockRepo.getMaster(forceRefresh: false)).called(1);
      verify(() => mockRepo.getHorario(any())).called(1);
    });
  });
}