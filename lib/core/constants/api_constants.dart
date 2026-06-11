/// Todas las URLs y constantes de la API de Tongoy.
/// Si cambia el servidor, sólo hay que modificar este archivo.
class ApiConstants {
  ApiConstants._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://losvilos.ucn.cl/hawaii',
  );

  // Endpoints
  static const String master = '/master.php';
  static const String horario = '/g.php';
  static const String planificacion = '/planif_curso.php';
  static const String auth = '/a.php';
  static const String validarRut = '/ge.php';
  static const String cursos = '/cp.php';

  // Documentación oficial v0.9.8: el endpoint correcto es asist_marcar6.php
  static const String asistenciaList = '/asist_marcar6.php';

  static const String firebaseToken = '/ust.php';
  static const String usuarioActual = '/mi.php';
  static const String carreraUsuario = '/gc.php';
  static const String notasEstudiante = '/notas-estudiante.php';

  // Timeouts
  static const int connectTimeoutMs = 10000;
  static const int receiveTimeoutMs = 15000;
}

/// Claves para SharedPreferences / SecureStorage.
class StorageKeys {
  StorageKeys._();

  static const String sessionCookie = 'session_cookie';
  static const String usuario = 'usuario';
  static const String semestreActual = 'semestre_actual';
  static const String masterCache = 'master_cache';
  static const String masterCacheTime = 'master_cache_time';
}
