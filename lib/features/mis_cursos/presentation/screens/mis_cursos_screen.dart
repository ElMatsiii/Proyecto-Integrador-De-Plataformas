import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../horario/presentation/providers/horario_provider.dart';
import '../../data/mis_cursos_datasource.dart';
import '../../domain/entities/curso_usuario_entity.dart';

class MisCursosScreen extends ConsumerWidget {
  const MisCursosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    // Si no está autenticado muestra pantalla de login
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
            ),
          );
        },
      ),
    );
  }

  void _confirmarLogout(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Quieres cerrar tu sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
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

  const _CursosList({required this.cursos, required this.semestreNombre});

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
      itemBuilder: (_, i) => _CursoCard(curso: cursos[i]),
    );
  }
}

class _CursoCard extends StatelessWidget {
  final CursoUsuarioEntity curso;
  const _CursoCard({required this.curso});

  @override
  Widget build(BuildContext context) {
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
