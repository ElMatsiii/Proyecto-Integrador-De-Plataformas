/// Entidad de un bloque del horario (ej: A, B, C, D...)
class BloqueEntity {
  final int id;
  final String nombre;
  final String? horario;

  const BloqueEntity({
    required this.id,
    required this.nombre,
    this.horario,
  });
}

/// Entidad de un día de la semana en el sistema Tongoy
class DiaEntity {
  final int id;
  final String nombre;
  final int dotw; // day of the week (1=Lunes..6=Sabado, 0=Sin dia)

  const DiaEntity({
    required this.id,
    required this.nombre,
    required this.dotw,
  });
}

/// Entidad de una sala
class SalaEntity {
  final int id;
  final String nombre;
  final String sector;
  final int? capacidad;

  const SalaEntity({
    required this.id,
    required this.nombre,
    required this.sector,
    this.capacidad,
  });
}

/// Entidad de área/departamento
class AreaEntity {
  final int id;
  final String nombre;

  const AreaEntity({required this.id, required this.nombre});
}

/// Entidad de semestre
class SemestreEntity {
  final int id;
  final String nombre;
  final DateTime primerLunes;
  final DateTime ultimoDomingo;
  final bool esActual;

  const SemestreEntity({
    required this.id,
    required this.nombre,
    required this.primerLunes,
    required this.ultimoDomingo,
    this.esActual = false,
  });
}

/// Entidad de profesor
class ProfesorEntity {
  final int id;
  final String nombre;

  const ProfesorEntity({required this.id, required this.nombre});
}

/// Entidad de curso
class CursoEntity {
  final int id;
  final String nombre;

  const CursoEntity({required this.id, required this.nombre});
}

/// Conjunto completo de datos maestros retornado por master.php
class MasterEntity {
  final List<AreaEntity> areas;
  final List<DiaEntity> dias;
  final List<BloqueEntity> bloques;
  final List<SalaEntity> salas;
  final List<CursoEntity> cursos;
  final List<ProfesorEntity> profesores;
  final List<SemestreEntity> semestres;

  const MasterEntity({
    required this.areas,
    required this.dias,
    required this.bloques,
    required this.salas,
    required this.cursos,
    required this.profesores,
    required this.semestres,
  });
}

/// Carrera asociada a un bloque de horario
class CarreraEnHorario {
  final int id;
  final String nombre;
  final int semestre;

  const CarreraEnHorario({
    required this.id,
    required this.nombre,
    required this.semestre,
  });
}

/// Un bloque de horario (una fila de la grilla)
class HorarioItemEntity {
  final int id;
  final String dia;
  final String bloque;
  final String sala;
  final String curso;
  final int idCurso;
  final String nrc;
  final String profesor;
  final String area;
  final String comentario;
  final List<CarreraEnHorario> carreras;

  const HorarioItemEntity({
    required this.id,
    required this.dia,
    required this.bloque,
    required this.sala,
    required this.curso,
    required this.idCurso,
    required this.nrc,
    required this.profesor,
    required this.area,
    required this.comentario,
    required this.carreras,
  });
}

/// Filtros para consultar el horario.
/// [dia] es filtrado localmente (no se envía a la API).
/// [carreraId] también es filtrado localmente sobre los resultados.
/// [curso] admite selección múltiple; sólo se envía a la API cuando hay
/// exactamente un curso seleccionado (ver [HorarioRemoteDataSource]), el
/// resto de los casos se filtran localmente.
class HorarioFiltro {
  final int sala;
  final Set<int> curso;
  final int profesor;
  final int semestre;
  final int semestreC; // nivel de la carrera (1-10)
  final int carrera;
  final int area;

  /// Días seleccionados para filtro local ('Lunes', 'Martes', etc.). Vacío = todos.
  final Set<String> dias;

  /// ID de carrera para filtro local. -1 = todas.
  final int carreraId;

  const HorarioFiltro({
    this.sala = -1,
    this.curso = const {},
    this.profesor = -1,
    this.semestre = -1,
    this.semestreC = -1,
    this.carrera = -1,
    this.area = -1,
    this.dias = const {},
    this.carreraId = -1,
  });

  HorarioFiltro copyWith({
    int? sala,
    Set<int>? curso,
    int? profesor,
    int? semestre,
    int? semestreC,
    int? carrera,
    int? area,
    Set<String>? dias,
    int? carreraId,
  }) {
    return HorarioFiltro(
      sala: sala ?? this.sala,
      curso: curso ?? this.curso,
      profesor: profesor ?? this.profesor,
      semestre: semestre ?? this.semestre,
      semestreC: semestreC ?? this.semestreC,
      carrera: carrera ?? this.carrera,
      area: area ?? this.area,
      dias: dias ?? this.dias,
      carreraId: carreraId ?? this.carreraId,
    );
  }

  /// Retorna true si hay al menos un filtro activo además del semestre.
  bool get tieneFiltroPorsAplicados =>
      sala != -1 ||
      curso.isNotEmpty ||
      profesor != -1 ||
      semestreC != -1 ||
      carrera != -1 ||
      area != -1 ||
      dias.isNotEmpty ||
      carreraId != -1;
}