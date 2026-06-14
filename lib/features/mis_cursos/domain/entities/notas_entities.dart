class AsistenciaCursoEntity {
  final String nombre;
  final String codigo;
  final String seccion;
  final int porcentaje;
  final int presentes;
  final int total;

  const AsistenciaCursoEntity({
    required this.nombre,
    required this.codigo,
    required this.seccion,
    required this.porcentaje,
    required this.presentes,
    required this.total,
  });

  int get ausentes => total - presentes;
}

class NotaCursoEntity {
  final String nombre;
  final String nota;

  const NotaCursoEntity({required this.nombre, required this.nota});
}

class NotasCursoEntity {
  final String codigo;
  final String asignatura;
  final String seccion;
  final List<NotaCursoEntity> notas;

  const NotasCursoEntity({
    required this.codigo,
    required this.asignatura,
    required this.seccion,
    required this.notas,
  });
}
