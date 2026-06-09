/// Representa un curso asociado al usuario (como estudiante o profesor).
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
  /// Todos los IDs con los que este curso aparece en cp.php.
  /// La API puede devolver el mismo curso dos veces con IDs distintos
  /// (uno con extra=A y otro con extra=N). Ambos pueden aparecer como
  /// idcurso en g.php, así que los guardamos todos para el filtro de horario.
  final Set<int> extraIds;

  const CursoUsuarioEntity({
    required this.id,
    required this.nombre,
    required this.codigo,
    required this.seccion,
    required this.rol,
    required this.extra,
    this.pid = 0,
    Set<int>? extraIds,
  }) : extraIds = extraIds ?? const {};

  bool get esProfesor      => rol == 'P';
  bool get tieneAsistencia => extra == 'A';
  bool get tieneNotas      => extra == 'N';

  /// Todos los IDs asociados a este curso (incluye [id] y [extraIds]).
  Set<int> get todosLosIds => {id, ...extraIds};
}