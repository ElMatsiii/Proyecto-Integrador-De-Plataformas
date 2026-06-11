import '../../../../core/utils/json_read.dart';
import '../../domain/entities/horario_entity.dart';

class BloqueDto {
  final int id;
  final String nombre;
  final String? horario;

  const BloqueDto({required this.id, required this.nombre, this.horario});

  factory BloqueDto.fromJson(Map<String, dynamic> json) => BloqueDto(
        id: readInt(json['id']),
        nombre: readString(json['nombre']),
        horario: json['horario'] == null ? null : readString(json['horario']),
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
        id: readInt(json['id']),
        nombre: readString(json['nombre']),
        dotw: readInt(json['dotw']),
      );

  DiaEntity toEntity() => DiaEntity(id: id, nombre: nombre, dotw: dotw);
}

class SalaDto {
  final int id;
  final String nombre;
  final String sector;
  final int? capacidad;

  const SalaDto({
    required this.id,
    required this.nombre,
    required this.sector,
    this.capacidad,
  });

  factory SalaDto.fromJson(Map<String, dynamic> json) => SalaDto(
        id: readInt(json['id']),
        nombre: readString(json['nombre']),
        sector: readString(json['sector']),
        capacidad:
            json['capacidad'] == null ? null : readInt(json['capacidad']),
      );

  SalaEntity toEntity() =>
      SalaEntity(id: id, nombre: nombre, sector: sector, capacidad: capacidad);
}

class AreaDto {
  final int id;
  final String nombre;

  const AreaDto({required this.id, required this.nombre});

  factory AreaDto.fromJson(Map<String, dynamic> json) => AreaDto(
        id: readInt(json['id']),
        nombre: readString(json['nombre']),
      );

  AreaEntity toEntity() => AreaEntity(id: id, nombre: nombre);
}

class SemestreDto {
  final int id;
  final String nombre;
  final String primerLunes;
  final String ultimoDomingo;
  final bool esActual;

  const SemestreDto({
    required this.id,
    required this.nombre,
    required this.primerLunes,
    required this.ultimoDomingo,
    this.esActual = false,
  });

  factory SemestreDto.fromJson(Map<String, dynamic> json) => SemestreDto(
        id: readInt(json['id']),
        nombre: readString(json['nombre']),
        primerLunes: readString(json['primer_lunes']),
        ultimoDomingo: readString(json['ultimo_domingo']),
        esActual: readBool(json['es_actual']),
      );

  SemestreEntity toEntity() => SemestreEntity(
        id: id,
        nombre: nombre,
        primerLunes: DateTime.tryParse(primerLunes) ?? DateTime(1970),
        ultimoDomingo: DateTime.tryParse(ultimoDomingo) ?? DateTime(1970),
        esActual: esActual,
      );
}

class ProfesorDto {
  final int id;
  final String nombre;

  const ProfesorDto({required this.id, required this.nombre});

  factory ProfesorDto.fromJson(Map<String, dynamic> json) => ProfesorDto(
        id: readInt(json['id']),
        nombre: readString(json['nombre']),
      );

  ProfesorEntity toEntity() => ProfesorEntity(id: id, nombre: nombre);
}

class CursoDto {
  final int id;
  final String nombre;

  const CursoDto({required this.id, required this.nombre});

  factory CursoDto.fromJson(Map<String, dynamic> json) => CursoDto(
        id: readInt(json['id']),
        nombre: readString(json['nombre']),
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
        areas: asJsonMapList(json['areas']).map(AreaDto.fromJson).toList(),
        dias: asJsonMapList(json['dias']).map(DiaDto.fromJson).toList(),
        bloques:
            asJsonMapList(json['bloques']).map(BloqueDto.fromJson).toList(),
        salas: asJsonMapList(json['salas']).map(SalaDto.fromJson).toList(),
        cursos: asJsonMapList(json['cursos']).map(CursoDto.fromJson).toList(),
        profesores: asJsonMapList(json['profesores'])
            .map(ProfesorDto.fromJson)
            .toList(),
        semestres:
            asJsonMapList(json['semestres']).map(SemestreDto.fromJson).toList(),
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

class CarreraEnHorarioDto {
  final int id;
  final String nombre;
  final int semestre;

  const CarreraEnHorarioDto({
    required this.id,
    required this.nombre,
    required this.semestre,
  });

  factory CarreraEnHorarioDto.fromJson(Map<String, dynamic> json) =>
      CarreraEnHorarioDto(
        id: readInt(json['id']),
        nombre: readString(json['nombre']),
        semestre: readInt(json['semestre']),
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
        id: readInt(json['id']),
        dia: readString(json['dia']),
        bloque: readString(json['bloque']),
        sala: readString(json['sala']),
        curso: readString(json['curso']),
        idCurso: readInt(json['idcurso']),
        nrc: readString(json['nrc']),
        profesor: readString(json['profesor']),
        area: readString(json['area']),
        comentario: readString(json['comentario']),
        carreras: asJsonMapList(json['carreras'])
            .map(CarreraEnHorarioDto.fromJson)
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
