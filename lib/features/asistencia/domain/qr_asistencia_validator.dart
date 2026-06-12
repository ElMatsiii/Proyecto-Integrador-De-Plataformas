/// Validación pura de las URLs de los QR de asistencia.
///
/// Se extrae del escáner (`_QrScannerSheet`) para poder testearla sin cámara
/// ni widgets. Es lógica crítica de seguridad: solo se aceptan URLs HTTPS del
/// dominio oficial de Tongoy y de los endpoints de asistencia conocidos.
/// Cualquier otra cosa (otro dominio, subdominio, http, otra ruta) se rechaza.
class QrAsistenciaValidator {
  const QrAsistenciaValidator();

  /// Dominio autorizado para los QR de asistencia.
  static const dominioPermitido = 'losvilos.ucn.cl';

  /// Únicas rutas de asistencia válidas (hawaii = dev, tongoy = prod).
  static const rutasPermitidas = {
    '/hawaii/asist.php',
    '/hawaii/asist_marcar6.php',
    '/tongoy/asist_marcar6.php',
  };

  /// Retorna true si [uri] corresponde a un QR de asistencia legítimo.
  ///
  /// Nota: `Uri` normaliza esquema y host a minúsculas, por lo que la
  /// comparación de dominio es case-insensitive. La ruta, en cambio, es
  /// case-sensitive (igual que en el servidor).
  bool esValido(Uri uri) {
    if (uri.scheme != 'https') return false;
    if (uri.host != dominioPermitido) return false;
    return rutasPermitidas.contains(uri.path);
  }

  /// Igual que [esValido] pero acepta el texto crudo leído del QR.
  /// Retorna false si el texto está vacío o no es una URI parseable.
  bool esTextoValido(String raw) {
    if (raw.isEmpty) return false;
    final uri = Uri.tryParse(raw);
    if (uri == null) return false;
    return esValido(uri);
  }
}
