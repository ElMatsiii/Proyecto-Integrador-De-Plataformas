import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../horario/presentation/providers/horario_provider.dart';
import '../../../mis_cursos/data/mis_cursos_datasource.dart';
import '../../../mis_cursos/domain/entities/curso_usuario_entity.dart';
import '../../data/asistencia_datasource.dart';

class AsistenciaScreen extends ConsumerWidget {
  const AsistenciaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState is! AuthAuthenticated) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 56),
              const SizedBox(height: 12),
              const Text('Inicia sesión para ver la asistencia'),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => context.pushNamed(AppRoutes.loginName),
                icon: const Icon(Icons.login),
                label: const Text('Iniciar sesión'),
              ),
            ],
          ),
        ),
      );
    }

    final usuario = authState.usuario;
    final master = ref.watch(masterProvider);
    final cursoSeleccionado = ref.watch(cursoSeleccionadoProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          cursoSeleccionado != null ? cursoSeleccionado.nombre : 'Asistencia',
        ),
        leading: cursoSeleccionado != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () =>
                    ref.read(cursoSeleccionadoProvider.notifier).state = null,
              )
            : null,
      ),
      body: master.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (masterData) {
          final semestre = masterData.semestres.firstOrNull;
          if (semestre == null) {
            return const Center(child: Text('Sin semestres disponibles'));
          }

          final curso = cursoSeleccionado;
          if (curso == null) {
            return _SeleccionCurso(
              usuario: usuario.rut,
              semestreId: semestre.id,
            );
          }

          return _VistaAsistencia(
            cursoId: curso.id,
            semestreId: semestre.id,
          );
        },
      ),
    );
  }
}

// ── Selección de curso ────────────────────────────────────────────────────────

class _SeleccionCurso extends ConsumerWidget {
  final String usuario;
  final int semestreId;
  const _SeleccionCurso({required this.usuario, required this.semestreId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cursosAsync = ref.watch(
      misCursosProvider((usuario: usuario, semestre: semestreId)),
    );

    return cursosAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (cursos) {
        final conAsistencia = cursos
            .where((CursoUsuarioEntity c) => c.tieneAsistencia || c.esProfesor)
            .toList();

        if (conAsistencia.isEmpty) {
          return const Center(
            child: Text('No tienes cursos con asistencia disponible'),
          );
        }

        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                'Selecciona un curso',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
            ...conAsistencia.map(
              (CursoUsuarioEntity c) => ListTile(
                leading: const Icon(Icons.fact_check_outlined),
                title: Text(c.nombre),
                subtitle: Text('${c.codigo} · ${c.seccion}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    ref.read(cursoSeleccionadoProvider.notifier).state = c,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Vista de asistencia del curso ─────────────────────────────────────────────

class _VistaAsistencia extends ConsumerWidget {
  final int cursoId;
  final int semestreId;
  const _VistaAsistencia({required this.cursoId, required this.semestreId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asistenciaAsync = ref.watch(
      asistenciaProvider((curso: cursoId, semestre: semestreId)),
    );

    return asistenciaAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (clases) {
        if (clases.isEmpty) {
          return const Center(child: Text('Sin registros de asistencia'));
        }
        return ListView.builder(
          itemCount: clases.length,
          itemBuilder: (_, i) => _ClaseAsistenciaCard(clase: clases[i]),
        );
      },
    );
  }
}

// ── Tarjeta de una clase ──────────────────────────────────────────────────────

class _ClaseAsistenciaCard extends StatelessWidget {
  final AsistenciaClaseEntity clase;
  const _ClaseAsistenciaCard({required this.clase});

  @override
  Widget build(BuildContext context) {
    final presentes =
        clase.asistentes.values.where((e) => e.estado == 1).length;
    final total = clase.asistentes.length;
    final porcentaje = total > 0 ? presentes / total : 0.0;

    return Card(
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _colorPorcentaje(context, porcentaje),
          child: Text(
            '${(porcentaje * 100).round()}%',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
        title: Text('${clase.fecha} · Bloque ${clase.bloque}'),
        subtitle: Text('$presentes / $total presentes'),
        children: clase.asistentes.values
            .map((est) => _EstudianteRow(estudiante: est))
            .toList(),
      ),
    );
  }

  Color _colorPorcentaje(BuildContext context, double p) {
    final colors = Theme.of(context).colorScheme;
    if (p >= 0.75) return colors.primaryContainer;
    if (p >= 0.5) return colors.secondaryContainer;
    return colors.errorContainer;
  }
}

class _EstudianteRow extends StatelessWidget {
  final AsistenciaEstudianteEntity estudiante;
  const _EstudianteRow({required this.estudiante});

  Color _estadoColor(ColorScheme colors) => switch (estudiante.estado) {
        1 => colors.primaryContainer,
        0 => colors.errorContainer,
        3 => colors.tertiaryContainer,
        -1 => colors.secondaryContainer,
        _ => colors.surfaceContainerHighest,
      };

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      dense: true,
      title: Text(
        estudiante.nombreCompleto,
        style: const TextStyle(fontSize: 13),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _estadoColor(colors),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          estudiante.estadoTexto,
          style: const TextStyle(fontSize: 11),
        ),
      ),
    );
  }
}
