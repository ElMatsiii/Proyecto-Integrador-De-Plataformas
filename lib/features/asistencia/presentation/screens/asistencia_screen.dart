import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../horario/presentation/providers/horario_provider.dart';
import '../../../mis_cursos/data/mis_cursos_datasource.dart';
import '../../../mis_cursos/domain/entities/curso_usuario_entity.dart';
import '../../data/asistencia_datasource.dart';

// ── Pantalla principal ────────────────────────────────────────────────────────

class AsistenciaScreen extends ConsumerStatefulWidget {
  const AsistenciaScreen({super.key});

  @override
  ConsumerState<AsistenciaScreen> createState() => _AsistenciaScreenState();
}

class _AsistenciaScreenState extends ConsumerState<AsistenciaScreen> {
  CursoUsuarioEntity? _cursoSeleccionado;

  @override
  Widget build(BuildContext context) {
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
                onPressed: () {},
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _cursoSeleccionado != null
              ? _cursoSeleccionado!.nombre
              : 'Asistencia',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: _cursoSeleccionado != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _cursoSeleccionado = null),
              )
            : null,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirEscaner(context),
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Pasar asistencia'),
      ),
      body: master.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (masterData) {
          final semestreActual = masterData.semestres.firstWhere(
            (s) => s.esActual,
            orElse: () => masterData.semestres.first,
          );

          if (_cursoSeleccionado == null) {
            return _ListaCursos(
              usuario: usuario.rut,
              semestreId: semestreActual.id,
              onCursoTap: (curso) =>
                  setState(() => _cursoSeleccionado = curso),
            );
          }

          return _DetalleAsistencia(
            curso: _cursoSeleccionado!,
            semestreId: semestreActual.id,
            rutEstudiante: usuario.rut,
          );
        },
      ),
    );
  }

  void _abrirEscaner(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _QrScannerSheet(),
    );
  }
}

// ── Lista de cursos ───────────────────────────────────────────────────────────

class _ListaCursos extends ConsumerWidget {
  final String usuario;
  final int semestreId;
  final ValueChanged<CursoUsuarioEntity> onCursoTap;

  const _ListaCursos({
    required this.usuario,
    required this.semestreId,
    required this.onCursoTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cursosAsync = ref.watch(
      misCursosProvider((usuario: usuario, semestre: semestreId)),
    );

    return cursosAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (cursos) {
        if (cursos.isEmpty) {
          return const Center(
            child: Text('No tienes cursos registrados'),
          );
        }

        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                'Selecciona un ramo',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
            ...cursos.map(
              (c) => _CursoAsistenciaTile(curso: c, onTap: () => onCursoTap(c)),
            ),
          ],
        );
      },
    );
  }
}

class _CursoAsistenciaTile extends StatelessWidget {
  final CursoUsuarioEntity curso;
  final VoidCallback onTap;

  const _CursoAsistenciaTile({required this.curso, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.fact_check_outlined),
      title: Text(curso.nombre),
      subtitle: Text('${curso.codigo} · ${curso.seccion}'),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

// ── Detalle de asistencia del curso ──────────────────────────────────────────

class _DetalleAsistencia extends ConsumerWidget {
  final CursoUsuarioEntity curso;
  final int semestreId;
  final String rutEstudiante;

  const _DetalleAsistencia({
    required this.curso,
    required this.semestreId,
    required this.rutEstudiante,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asistenciaAsync = ref.watch(
      asistenciaEstudianteProvider((
        curso: curso.id,
        semestre: semestreId,
        rut: rutEstudiante,
      )),
    );

    return asistenciaAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (clases) {
        if (clases.isEmpty) {
          return const Center(
            child: Text('Sin registros de asistencia aún'),
          );
        }

        final presentes = clases.where((c) => c.estado == 1).length;
        final ausentes = clases.where((c) => c.estado == 0).length;
        final justificados = clases.where((c) => c.estado == 3).length;
        final atrasados = clases.where((c) => c.estado == -1).length;
        final total = clases.length;
        final porcentaje = total > 0 ? (presentes / total * 100).round() : 0;

        return Column(
          children: [
            // Resumen
            _ResumenCard(
              presentes: presentes,
              ausentes: ausentes,
              justificados: justificados,
              atrasados: atrasados,
              total: total,
              porcentaje: porcentaje,
            ),
            // Lista de clases
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: clases.length,
                itemBuilder: (_, i) => _ClaseTile(clase: clases[i]),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Tarjeta de resumen ────────────────────────────────────────────────────────

class _ResumenCard extends StatelessWidget {
  final int presentes;
  final int ausentes;
  final int justificados;
  final int atrasados;
  final int total;
  final int porcentaje;

  const _ResumenCard({
    required this.presentes,
    required this.ausentes,
    required this.justificados,
    required this.atrasados,
    required this.total,
    required this.porcentaje,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = porcentaje >= 75
        ? colors.primaryContainer
        : porcentaje >= 50
            ? colors.secondaryContainer
            : colors.errorContainer;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                '$porcentaje%',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Asistencia general',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: porcentaje / 100,
                      backgroundColor: colors.surface.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(valor: presentes, label: 'Presentes', icon: Icons.check_circle_outline),
              _StatItem(valor: ausentes, label: 'Ausentes', icon: Icons.cancel_outlined),
              _StatItem(valor: justificados, label: 'Justif.', icon: Icons.verified_outlined),
              _StatItem(valor: atrasados, label: 'Atrasados', icon: Icons.schedule_outlined),
              _StatItem(valor: total, label: 'Total', icon: Icons.calendar_month_outlined),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final int valor;
  final String label;
  final IconData icon;

  const _StatItem({
    required this.valor,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return Column(
      children: [
        Icon(icon, size: 16, color: color.withValues(alpha: 0.6)),
        const SizedBox(height: 2),
        Text(
          '$valor',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: color.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

// ── Fila de una clase ─────────────────────────────────────────────────────────

class _ClaseTile extends StatelessWidget {
  final AsistenciaClaseEntity clase;
  const _ClaseTile({required this.clase});

  Color _color(ColorScheme colors) => switch (clase.estado) {
        1 => colors.primaryContainer,
        0 => colors.errorContainer,
        3 => colors.tertiaryContainer,
        -1 => colors.secondaryContainer,
        _ => colors.surfaceContainerHighest,
      };

  IconData _icon() => switch (clase.estado) {
        1 => Icons.check_circle_outline,
        0 => Icons.cancel_outlined,
        3 => Icons.verified_outlined,
        -1 => Icons.schedule_outlined,
        _ => Icons.help_outline,
      };

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _color(colors),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(_icon(), size: 20, color: colors.onSurface),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    clase.fecha,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Bloque ${clase.bloque}',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colors.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                clase.estadoTexto,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Escáner QR ────────────────────────────────────────────────────────────────

class _QrScannerSheet extends StatefulWidget {
  const _QrScannerSheet();

  @override
  State<_QrScannerSheet> createState() => _QrScannerSheetState();
}

class _QrScannerSheetState extends State<_QrScannerSheet> {
  final MobileScannerController _controller = MobileScannerController();
  bool _detectado = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_detectado) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null) return;

    final raw = barcode.rawValue ?? '';
    if (raw.isEmpty) return;

    _detectado = true;
    await _controller.stop();

    if (!mounted) return;
    Navigator.of(context).pop();

    // Intentar abrir la URL detectada
    final uri = Uri.tryParse(raw);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } else {
      // Si no es URL, mostrar el contenido en un snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('QR: $raw')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
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
            padding: const EdgeInsets.all(16),
            child: Text(
              'Escanea el código QR',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
              child: MobileScanner(
                controller: _controller,
                onDetect: _onDetect,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Apunta la cámara al QR del profesor para registrar tu asistencia',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}