import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../auth/presentation/providers/auth_provider_notif.dart';
import '../../../horario/presentation/providers/horario_provider_notif.dart';
import '../../data/mis_cursos_datasource.dart';
import '../../data/notas_datasource.dart';
import '../../domain/entities/curso_usuario_entity.dart';

class MisCursosScreen extends ConsumerWidget {
  const MisCursosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState is AuthUnauthenticated || authState is AuthInitial) {
      return _SinSesionView(
        onLogin: () => context.pushNamed(AppRoutes.loginName),
      );
    }

    if (authState is AuthLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (authState is! AuthAuthenticated) {
      return _SinSesionView(
        onLogin: () => context.pushNamed(AppRoutes.loginName),
      );
    }

    final usuario = authState.usuario;
    final master = ref.watch(masterProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mis Cursos'),
            Text(
              usuario.nombre,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => _confirmarLogout(context, ref),
          ),
        ],
      ),
      body: master.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error al cargar: $e')),
        data: (masterData) {
          final semestres = masterData.semestres;
          if (semestres.isEmpty) {
            return const Center(child: Text('Sin semestres disponibles'));
          }

          final semestreActual = semestres.firstWhere(
            (s) => s.esActual,
            orElse: () => semestres.first,
          );

          final cursosAsync = ref.watch(
            misCursosProvider(
              (usuario: usuario.rut, semestre: semestreActual.id),
            ),
          );

          return cursosAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _ErrorCursos(
              mensaje: e.toString(),
              onRetry: () => ref.invalidate(misCursosProvider),
            ),
            data: (cursos) => _CursosList(
              cursos: cursos,
              semestreNombre: semestreActual.nombre,
              semestreId: semestreActual.id,
            ),
          );
        },
      ),
    );
  }

  void _confirmarLogout(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Quieres cerrar tu sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              // Toda la limpieza de providers se hace dentro de AuthNotifier.logout()
              ref.read(authProvider.notifier).logout();
            },
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }
}

// ── Lista de cursos ───────────────────────────────────────────────────────────

class _CursosList extends StatelessWidget {
  final List<CursoUsuarioEntity> cursos;
  final String semestreNombre;
  final int semestreId;

  const _CursosList({
    required this.cursos,
    required this.semestreNombre,
    required this.semestreId,
  });

  @override
  Widget build(BuildContext context) {
    if (cursos.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.book_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text('Sin cursos en $semestreNombre'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: cursos.length,
      itemBuilder: (_, i) => _CursoCard(
        curso: cursos[i],
        semestreId: semestreId,
      ),
    );
  }
}

// ── Tarjeta de curso ──────────────────────────────────────────────────────────

class _CursoCard extends ConsumerWidget {
  final CursoUsuarioEntity curso;
  final int semestreId;

  const _CursoCard({required this.curso, required this.semestreId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: curso.esProfesor
              ? colors.tertiaryContainer
              : colors.secondaryContainer,
          child: Icon(
            curso.esProfesor
                ? Icons.co_present_outlined
                : Icons.person_outline,
            color: curso.esProfesor
                ? colors.onTertiaryContainer
                : colors.onSecondaryContainer,
          ),
        ),
        title: Text(
          curso.nombre,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        subtitle: Text(
          '${curso.codigo} · Sección ${curso.seccion}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (curso.tieneAsistencia)
              _Badge(
                label: 'Asist.',
                color: colors.primaryContainer,
                textColor: colors.onPrimaryContainer,
              ),
            if (curso.tieneNotas)
              _Badge(
                label: 'Notas',
                color: colors.secondaryContainer,
                textColor: colors.onSecondaryContainer,
              ),
          ],
        ),
        onTap: () => _mostrarDetalle(context, ref),
      ),
    );
  }

  void _mostrarDetalle(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _CursoDetalleSheet(
        curso: curso,
        semestreId: semestreId,
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;

  const _Badge({
    required this.label,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, color: textColor)),
    );
  }
}

// ── Detalle del curso ─────────────────────────────────────────────────────────

class _CursoDetalleSheet extends ConsumerWidget {
  final CursoUsuarioEntity curso;
  final int semestreId;

  const _CursoDetalleSheet({
    required this.curso,
    required this.semestreId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asistenciasAsync = ref.watch(asistenciasProvider(semestreId));
    final notasAsync = ref.watch(notasProvider(semestreId));

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (_, controller) => Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  curso.nombre,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  '${curso.codigo} · Sección ${curso.seccion}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.all(16),
              children: [
                // Asistencia
                const _SeccionTitulo(titulo: 'Asistencia'),
                asistenciasAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error: $e'),
                  data: (asistencias) {
                    final match = asistencias
                        .where((a) =>
                            a.codigo == curso.codigo &&
                            a.seccion == curso.seccion,)
                        .firstOrNull;
                    if (match == null) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('Sin datos de asistencia'),
                      );
                    }
                    return _AsistenciaCard(asistencia: match);
                  },
                ),
                const SizedBox(height: 16),
                // Notas
                const _SeccionTitulo(titulo: 'Notas'),
                notasAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error: $e'),
                  data: (notas) {
                    final match = notas
                        .where((n) =>
                            n.codigo == curso.codigo &&
                            n.seccion == curso.seccion,)
                        .firstOrNull;
                    if (match == null || match.notas.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('Sin notas disponibles'),
                      );
                    }
                    return _NotasCard(notasCurso: match);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _SeccionTitulo extends StatelessWidget {
  final String titulo;
  const _SeccionTitulo({required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        titulo,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _AsistenciaCard extends StatelessWidget {
  final AsistenciaCursoEntity asistencia;
  const _AsistenciaCard({required this.asistencia});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final porcentaje = asistencia.porcentaje;
    final color = porcentaje >= 75
        ? colors.primaryContainer
        : porcentaje >= 50
            ? colors.secondaryContainer
            : colors.errorContainer;

    final total = asistencia.total;
    final presentes = asistencia.presentes;
    final ausentes = total - presentes;

    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '$porcentaje%',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Asistencia actual'),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: porcentaje / 100,
                        backgroundColor: colors.surface,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatChip(
                  label: 'Asistidas',
                  value: '$presentes',
                  icon: Icons.check_circle_outline,
                  color: colors.onSurface,
                ),
                _StatChip(
                  label: 'Ausentes',
                  value: '$ausentes',
                  icon: Icons.cancel_outlined,
                  color: colors.onSurface,
                ),
                _StatChip(
                  label: 'Total',
                  value: '$total',
                  icon: Icons.calendar_month_outlined,
                  color: colors.onSurface,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color.withValues(alpha: 0.7)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: color.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

class _NotasCard extends StatelessWidget {
  final NotasCursoEntity notasCurso;
  const _NotasCard({required this.notasCurso});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: notasCurso.notas
              .map(
                (n) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          n.nombre,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      Text(
                        n.nota,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

// ── Vistas auxiliares ─────────────────────────────────────────────────────────

class _SinSesionView extends StatelessWidget {
  final VoidCallback onLogin;
  const _SinSesionView({required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'Inicia sesión para ver tus cursos',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onLogin,
                icon: const Icon(Icons.login),
                label: const Text('Iniciar sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorCursos extends StatelessWidget {
  final String mensaje;
  final VoidCallback onRetry;
  const _ErrorCursos({required this.mensaje, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(mensaje, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}