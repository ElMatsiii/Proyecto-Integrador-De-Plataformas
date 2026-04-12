import '../../domain/entities/horario_entity.dart';

// ── Master DTOs ──────────────────────────────────────────────────────────────

class BloqueDto {
  final int id;
  final String nombre;
  final String? horario;

  const BloqueDto({required this.id, required this.nombre, this.horario});

  factory BloqueDto.fromJson(Map<String, dynamic> json) => BloqueDto(
        id: json['id'] as int,
        nombre: json['nombre'] as String,
        horario: json['horario'] as String?,
      );

  BloqueEntity toEntity() =>
      BloqueEntity(id: id, nombre: nombre, horario: horario);
}

class DiaDto {
  final int id;
  final String nombre;
  final int dotw;

  const DiaDto({required this.id, required this.nombre, required this.dotw});

  factory DiaDto.fromJson(Map<String, dynamic> json) => DiaDto(
        id: json['id'] as int,
        nombre: json['nombre'] as String,
        dotw: json['dotw'] as int,
      );

  DiaEntity toEntity() => DiaEntity(id: id, nombre: nombre, dotw: dotw);
}

class SalaDto {
  final int id;
  final String nombre;
  final String sector;
  final int? capacidad;

  const SalaDto(
      {required this.id,
      required this.nombre,
      required this.sector,
      this.capacidad,});

  factory SalaDto.fromJson(Map<String, dynamic> json) => SalaDto(
        id: json['id'] as int,
        nombre: json['nombre'] as String,
        sector: json['sector'] as String? ?? '',
        capacidad: json['capacidad'] as int?,
      );

  SalaEntity toEntity() =>
      SalaEntity(id: id, nombre: nombre, sector: sector, capacidad: capacidad);
}

class AreaDto {
  final int id;
  final String nombre;

  const AreaDto({required this.id, required this.nombre});

  factory AreaDto.fromJson(Map<String, dynamic> json) => AreaDto(
        id: json['id'] as int,
        nombre: json['nombre'] as String,
      );

  AreaEntity toEntity() => AreaEntity(id: id, nombre: nombre);
}

class SemestreDto {
  final int id;
  final String nombre;
  final String primerLunes;
  final String ultimoDomingo;
  final bool esActual; // ← agregar

  const SemestreDto({
    required this.id,
    required this.nombre,
    required this.primerLunes,
    required this.ultimoDomingo,
    this.esActual = false, // ← agregar
  });

  factory SemestreDto.fromJson(Map<String, dynamic> json) => SemestreDto(
        id: json['id'] as int,
        nombre: json['nombre'] as String,
        primerLunes: json['primer_lunes'] as String,
        ultimoDomingo: json['ultimo_domingo'] as String,
        esActual: (json['es_actual'] as int? ?? 0) == 1, // ← agregar
      );

  SemestreEntity toEntity() => SemestreEntity(
        id: id,
        nombre: nombre,
        primerLunes: DateTime.parse(primerLunes),
        ultimoDomingo: DateTime.parse(ultimoDomingo),
        esActual: esActual, // ← agregar
      );
}

class ProfesorDto {
  final int id;
  final String nombre;

  const ProfesorDto({required this.id, required this.nombre});

  factory ProfesorDto.fromJson(Map<String, dynamic> json) => ProfesorDto(
        id: json['id'] as int,
        nombre: json['nombre'] as String,
      );

  ProfesorEntity toEntity() => ProfesorEntity(id: id, nombre: nombre);
}

class CursoDto {
  final int id;
  final String nombre;

  const CursoDto({required this.id, required this.nombre});

  factory CursoDto.fromJson(Map<String, dynamic> json) => CursoDto(
        id: json['id'] as int,
        nombre: json['nombre'] as String,
      );

  CursoEntity toEntity() => CursoEntity(id: id, nombre: nombre);
}

class MasterDto {
  final List<AreaDto> areas;
  final List<DiaDto> dias;
  final List<BloqueDto> bloques;
  final List<SalaDto> salas;
  final List<CursoDto> cursos;
  final List<ProfesorDto> profesores;
  final List<SemestreDto> semestres;

  const MasterDto({
    required this.areas,
    required this.dias,
    required this.bloques,
    required this.salas,
    required this.cursos,
    required this.profesores,
    required this.semestres,
  });

  factory MasterDto.fromJson(Map<String, dynamic> json) => MasterDto(
        areas: (json['areas'] as List? ?? [])
            .map((e) => AreaDto.fromJson(e as Map<String, dynamic>))
            .toList(),
        dias: (json['dias'] as List? ?? [])
            .map((e) => DiaDto.fromJson(e as Map<String, dynamic>))
            .toList(),
        bloques: (json['bloques'] as List? ?? [])
            .map((e) => BloqueDto.fromJson(e as Map<String, dynamic>))
            .toList(),
        salas: (json['salas'] as List? ?? [])
            .map((e) => SalaDto.fromJson(e as Map<String, dynamic>))
            .toList(),
        cursos: (json['cursos'] as List? ?? [])
            .map((e) => CursoDto.fromJson(e as Map<String, dynamic>))
            .toList(),
        profesores: (json['profesores'] as List? ?? [])
            .map((e) => ProfesorDto.fromJson(e as Map<String, dynamic>))
            .toList(),
        semestres: (json['semestres'] as List? ?? [])
            .map((e) => SemestreDto.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  MasterEntity toEntity() => MasterEntity(
        areas: areas.map((e) => e.toEntity()).toList(),
        dias: dias.map((e) => e.toEntity()).toList(),
        bloques: bloques.map((e) => e.toEntity()).toList(),
        salas: salas.map((e) => e.toEntity()).toList(),
        cursos: cursos.map((e) => e.toEntity()).toList(),
        profesores: profesores.map((e) => e.toEntity()).toList(),
        semestres: semestres.map((e) => e.toEntity()).toList(),
      );
}

// ── Horario DTO ──────────────────────────────────────────────────────────────

class CarreraEnHorarioDto {
  final int id;
  final String nombre;
  final int semestre;

  const CarreraEnHorarioDto(
      {required this.id, required this.nombre, required this.semestre,});

  factory CarreraEnHorarioDto.fromJson(Map<String, dynamic> json) =>
      CarreraEnHorarioDto(
        id: json['id'] as int,
        nombre: json['nombre'] as String,
        semestre: json['semestre'] as int,
      );

  CarreraEnHorario toEntity() =>
      CarreraEnHorario(id: id, nombre: nombre, semestre: semestre);
}

class HorarioItemDto {
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
  final List<CarreraEnHorarioDto> carreras;

  const HorarioItemDto({
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

  factory HorarioItemDto.fromJson(Map<String, dynamic> json) => HorarioItemDto(
        id: json['id'] as int,
        dia: json['dia'] as String? ?? '',
        bloque: json['bloque'] as String? ?? '',
        sala: json['sala'] as String? ?? '',
        curso: json['curso'] as String? ?? '',
        idCurso: json['idcurso'] as int? ?? 0,
        nrc: json['nrc'] as String? ?? '',
        profesor: json['profesor'] as String? ?? '',
        area: json['area'] as String? ?? '',
        comentario: json['comentario'] as String? ?? '',
        carreras: (json['carreras'] as List? ?? [])
            .map((e) =>
                CarreraEnHorarioDto.fromJson(e as Map<String, dynamic>),)
            .toList(),
      );

  HorarioItemEntity toEntity() => HorarioItemEntity(
        id: id,
        dia: dia,
        bloque: bloque,
        sala: sala,
        curso: curso,
        idCurso: idCurso,
        nrc: nrc,
        profesor: profesor,
        area: area,
        comentario: comentario,
        carreras: carreras.map((e) => e.toEntity()).toList(),
      );
}
