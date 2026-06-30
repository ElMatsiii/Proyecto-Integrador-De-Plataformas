import 'package:flutter_test/flutter_test.dart';
import 'package:hawaii_app/core/errors/app_error.dart';
import 'package:hawaii_app/core/errors/result.dart';
import 'package:hawaii_app/features/auth/domain/entities/usuario_entity.dart';
import 'package:hawaii_app/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:hawaii_app/features/auth/domain/usecases/auth_usecases.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements IAuthRepository {}

const _usuarioFake = UsuarioEntity(rut: '12345678', nombre: 'Mario García');

void main() {
  late MockAuthRepository mockRepo;
  late LoginUseCase loginUseCase;
  late LogoutUseCase logoutUseCase;
  late GetUsuarioActualUseCase getUsuarioActualUseCase;

  setUp(() {
    mockRepo = MockAuthRepository();
    loginUseCase = LoginUseCase(mockRepo);
    logoutUseCase = LogoutUseCase(mockRepo);
    getUsuarioActualUseCase = GetUsuarioActualUseCase(mockRepo);
  });

  // ── LoginUseCase ──────────────────────────────────────────────────────────

  group('LoginUseCase', () {
    test('retorna UsuarioEntity cuando las credenciales son correctas', () async {
      when(() => mockRepo.login('mario@ucn.cl', '12345'))
          .thenAnswer((_) async => const Success(_usuarioFake));

      final result = await loginUseCase('mario@ucn.cl', '12345');

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull?.rut, '12345678');
      expect(result.dataOrNull?.nombre, 'Mario García');
    });

    test('retorna Failure(AuthError) con credenciales inválidas', () async {
      when(() => mockRepo.login('bad@ucn.cl', 'wrong'))
          .thenAnswer((_) async => const Failure(AuthError()));

      final result = await loginUseCase('bad@ucn.cl', 'wrong');

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<AuthError>());
    });

    test('retorna Failure(NetworkError) cuando no hay conexión', () async {
      when(() => mockRepo.login(any(), any()))
          .thenAnswer((_) async => const Failure(NetworkError()));

      final result = await loginUseCase('user', 'pass');

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<NetworkError>());
    });

    test('delega usuario y contraseña exactos al repositorio', () async {
      when(() => mockRepo.login('correo@ucn.cl', 'mi_clave_secreta'))
          .thenAnswer((_) async => const Success(_usuarioFake));

      await loginUseCase('correo@ucn.cl', 'mi_clave_secreta');

      verify(() => mockRepo.login('correo@ucn.cl', 'mi_clave_secreta')).called(1);
    });

    test('el repositorio se llama una sola vez', () async {
      when(() => mockRepo.login(any(), any()))
          .thenAnswer((_) async => const Success(_usuarioFake));

      await loginUseCase('u', 'p');

      verify(() => mockRepo.login(any(), any())).called(1);
      verifyNoMoreInteractions(mockRepo);
    });

    test('retorna Failure(ServerError) con error 500', () async {
      when(() => mockRepo.login(any(), any())).thenAnswer(
          (_) async => const Failure(ServerError('Error interno', statusCode: 500)),);

      final result = await loginUseCase('u', 'p');

      expect(result.isFailure, isTrue);
      expect((result.errorOrNull as ServerError).statusCode, 500);
    });
  });

  // ── LogoutUseCase ─────────────────────────────────────────────────────────

  group('LogoutUseCase', () {
    test('retorna Success<void> cuando el logout es exitoso', () async {
      when(() => mockRepo.logout())
          .thenAnswer((_) async => const Success(null));

      final result = await logoutUseCase();

      expect(result.isSuccess, isTrue);
    });

    test('retorna Failure cuando el logout falla', () async {
      when(() => mockRepo.logout())
          .thenAnswer((_) async => const Failure(UnknownError('fallo al limpiar')));

      final result = await logoutUseCase();

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull?.message, 'fallo al limpiar');
    });

    test('llama al repositorio exactamente una vez', () async {
      when(() => mockRepo.logout())
          .thenAnswer((_) async => const Success(null));

      await logoutUseCase();

      verify(() => mockRepo.logout()).called(1);
      verifyNoMoreInteractions(mockRepo);
    });
  });

  // ── GetUsuarioActualUseCase ───────────────────────────────────────────────

  group('GetUsuarioActualUseCase', () {
    test('retorna UsuarioEntity cuando hay sesión activa', () async {
      when(() => mockRepo.getUsuarioActual())
          .thenAnswer((_) async => const Success(_usuarioFake));

      final result = await getUsuarioActualUseCase();

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull?.nombre, 'Mario García');
    });

    test('retorna Failure(AuthError) cuando no hay sesión', () async {
      when(() => mockRepo.getUsuarioActual())
          .thenAnswer((_) async => const Failure(AuthError('Sin sesión activa')));

      final result = await getUsuarioActualUseCase();

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull?.message, 'Sin sesión activa');
    });

    test('retorna Failure(NetworkError) cuando no hay conexión', () async {
      when(() => mockRepo.getUsuarioActual())
          .thenAnswer((_) async => const Failure(NetworkError()));

      final result = await getUsuarioActualUseCase();

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<NetworkError>());
    });

    test('llama al repositorio exactamente una vez', () async {
      when(() => mockRepo.getUsuarioActual())
          .thenAnswer((_) async => const Success(_usuarioFake));

      await getUsuarioActualUseCase();

      verify(() => mockRepo.getUsuarioActual()).called(1);
      verifyNoMoreInteractions(mockRepo);
    });
  });

  // ── UsuarioEntity ─────────────────────────────────────────────────────────

  group('UsuarioEntity', () {
    test('guarda rut y nombre correctamente', () {
      const u = UsuarioEntity(rut: '9586127K', nombre: 'Ana López');
      expect(u.rut, '9586127K');
      expect(u.nombre, 'Ana López');
    });

    test('el rut puede ser un correo UCN', () {
      const u = UsuarioEntity(rut: 'mario.garcia@alumnos.ucn.cl', nombre: 'Mario');
      expect(u.rut, 'mario.garcia@alumnos.ucn.cl');
    });
  });
}