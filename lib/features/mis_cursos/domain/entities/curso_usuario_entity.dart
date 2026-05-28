/// Representa un curso asociado al usuario (como estudiante)
class CursoUsuarioEntity {
  final int id;
  final String nombre;
  final String codigo;
  final String seccion;
  /// 'E' = Estudiante, 'P' = Profesor
  final String rol;
  /// 'A' = tiene Asistencia, 'N' = tiene Notas
  final String extra;
  /// RUT numérico del estudiante (pid en la API)
  final int pid;

  const CursoUsuarioEntity({
    required this.id,
    required this.nombre,
    required this.codigo,
    required this.seccion,
    required this.rol,
    required this.extra,
    this.pid = 0,
  });

  bool get esProfesor => rol == 'P';
  bool get tieneAsistencia => extra == 'A';
  bool get tieneNotas => extra == 'N';
}