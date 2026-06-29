/// Feature flags — cambia a true cuando el backend esté listo.
class FeatureFlags {
  FeatureFlags._();

  /// Muestra el botón "Continuar con Google" en la pantalla de login.
  /// Requiere que el backend de Hawaii tenga el endpoint a.php?op=auth operativo.
  static const bool googleLoginEnabled = false;
}

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
  static const String asistenciaList = '/asist_marcar6.php';
 
  static const String firebaseToken = '/ust.php';
  static const String usuarioActual = '/mi.php';
  static const String carreraUsuario = '/gc.php';
  static const String notasEstudiante = '/notas-estudiante.php';
 
  // Login con Google — mismo endpoint a.php, parámetro confirmado por el
  // encargado de Hawaii: el ID token de Google se manda como 'tg'.
  static const String authGoogleTokenParam = 'tg';
 
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
  static const String loginAt = 'login_at';
}