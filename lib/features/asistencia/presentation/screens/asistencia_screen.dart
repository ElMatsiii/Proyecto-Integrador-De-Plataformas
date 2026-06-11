import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../auth/presentation/providers/auth_provider_notif.dart';
import '../../../horario/presentation/providers/horario_provider_notif.dart';
import '../../../mis_cursos/data/mis_cursos_datasource.dart';
import '../../../mis_cursos/data/notas_datasource.dart';
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
                onPressed: () => context.push('/login'),
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
            // El rut del usuario autenticado es la clave exacta en el JSON
            // de asist_marcar4.php (ej: "216542363" o "18758339K")
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

// ── Lista de cursos con resumen de asistencia ─────────────────────────────────

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
    // Mismo provider que Mis Cursos → porcentajes oficiales correctos
    final asistenciasAsync = ref.watch(asistenciasProvider(semestreId));

    return cursosAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (cursos) {
        if (cursos.isEmpty) {
          return const Center(child: Text('No tienes cursos registrados'));
        }
        return asistenciasAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _buildList(context, cursos, {}),
          data: (asistencias) {
            final map = <String, AsistenciaCursoEntity>{};
            for (final a in asistencias) {
              map['${a.codigo}|${a.seccion}'] = a;
            }
            return _buildList(context, cursos, map);
          },
        );
      },
    );
  }

  Widget _buildList(
    BuildContext context,
    List<CursoUsuarioEntity> cursos,
    Map<String, AsistenciaCursoEntity> map,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 80),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Text(
            'Toca un ramo para ver el registro diario',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        ...cursos.map((c) => _CursoAsistenciaTile(
              curso: c,
              asistencia: map['${c.codigo}|${c.seccion}'],
              onTap: () => onCursoTap(c),
            ),),
      ],
    );
  }
}

// ── Tile de curso ─────────────────────────────────────────────────────────────

class _CursoAsistenciaTile extends StatelessWidget {
  final CursoUsuarioEntity curso;
  final AsistenciaCursoEntity? asistencia;
  final VoidCallback onTap;

  const _CursoAsistenciaTile({
    required this.curso,
    required this.asistencia,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final pct = asistencia?.porcentaje ?? 0;
    final tieneData = asistencia != null;

    final barColor = !tieneData
        ? colors.outlineVariant
        : pct >= 75
            ? colors.primary
            : pct >= 50
                ? colors.secondary
                : colors.error;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: tieneData ? pct / 100 : 0,
                      backgroundColor: colors.surfaceContainerHighest,
                      color: barColor,
                      strokeWidth: 5,
                    ),
                    Text(
                      tieneData ? '$pct%' : '—',
                      style: TextStyle(
                        fontSize: tieneData ? 11 : 16,
                        fontWeight: FontWeight.w700,
                        color: barColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      curso.nombre,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${curso.codigo} · Sección ${curso.seccion}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    if (tieneData) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _MiniChip(
                            label: '${asistencia!.presentes} pres.',
                            color: colors.primaryContainer,
                            textColor: colors.onPrimaryContainer,
                          ),
                          const SizedBox(width: 6),
                          _MiniChip(
                            label: '${asistencia!.ausentes} aus.',
                            color: colors.errorContainer,
                            textColor: colors.onErrorContainer,
                          ),
                          const SizedBox(width: 6),
                          _MiniChip(
                            label: '${asistencia!.total} total',
                            color: colors.surfaceContainerHighest,
                            textColor: colors.onSurface,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  const _MiniChip({required this.label, required this.color, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: textColor),
      ),
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
    final asistenciasAsync = ref.watch(asistenciasProvider(semestreId));
    final detalleAsync = ref.watch(
      asistenciaEstudianteProvider((
        curso: curso.id,
        semestre: semestreId,
        // Usamos el rut string exacto del usuario autenticado,
        // que coincide con las claves del JSON de asist_marcar4.php
        rut: rutEstudiante,
      ),),
    );

    return asistenciasAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error resumen: $e')),
      data: (asistencias) {
        final resumen = asistencias
            .where((a) =>
                a.codigo == curso.codigo && a.seccion == curso.seccion,)
            .firstOrNull;

        return detalleAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Column(
            children: [
              if (resumen != null)
                _ResumenCard(resumen: resumen, clases: const []),
              Expanded(
                child: Center(child: Text('No se pudo cargar el detalle: $e')),
              ),
            ],
          ),
          data: (clases) => _VistaDetalle(resumen: resumen, clases: clases),
        );
      },
    );
  }
}

// ── Vista principal: resumen + lista por fecha ────────────────────────────────

class _VistaDetalle extends StatelessWidget {
  final AsistenciaCursoEntity? resumen;
  final List<AsistenciaClaseEntity> clases;

  const _VistaDetalle({required this.resumen, required this.clases});

  Map<String, List<AsistenciaClaseEntity>> _agruparPorFecha() {
    final mapa = <String, List<AsistenciaClaseEntity>>{};
    for (final c in clases) {
      mapa.putIfAbsent(c.fecha, () => []).add(c);
    }
    for (final lista in mapa.values) {
      lista.sort((a, b) => a.bloque.compareTo(b.bloque));
    }
    final fechasOrdenadas = mapa.keys.toList()..sort((a, b) => b.compareTo(a));
    return {for (final f in fechasOrdenadas) f: mapa[f]!};
  }

  String _formatFecha(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return DateFormat("EEE d 'de' MMM yyyy", 'es').format(dt);
    } catch (_) {
      return iso;
    }
  }

  String _diaSemana(String iso) {
    try {
      return DateFormat('EEEE', 'es').format(DateTime.parse(iso));
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final porFecha = _agruparPorFecha();

    return Column(
      children: [
        _ResumenCard(resumen: resumen, clases: clases),
        if (clases.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                Icon(Icons.calendar_month_outlined,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,),
                const SizedBox(width: 6),
                Text(
                  'Registro de clases (${clases.length} bloques)',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        if (clases.isEmpty)
          const Expanded(
            child: Center(child: Text('Sin registros de asistencia aún')),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
              itemCount: porFecha.length,
              itemBuilder: (_, i) {
                final fecha = porFecha.keys.elementAt(i);
                final bloques = porFecha[fecha]!;
                return _FechaCard(
                  fecha: fecha,
                  fechaFormateada: _formatFecha(fecha),
                  diaSemana: _diaSemana(fecha),
                  bloques: bloques,
                );
              },
            ),
          ),
      ],
    );
  }
}

// ── Tarjeta por fecha ─────────────────────────────────────────────────────────

class _FechaCard extends StatelessWidget {
  final String fecha;
  final String fechaFormateada;
  final String diaSemana;
  final List<AsistenciaClaseEntity> bloques;

  const _FechaCard({
    required this.fecha,
    required this.fechaFormateada,
    required this.diaSemana,
    required this.bloques,
  });

  bool get _esHoy {
    try {
      final dt = DateTime.parse(fecha);
      final hoy = DateTime.now();
      return dt.year == hoy.year &&
          dt.month == hoy.month &&
          dt.day == hoy.day;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hayAusente = bloques.any((b) => b.estado == 0);
    final hayAtrasado = bloques.any((b) => b.estado == -1);
    final todosPresentes =
        bloques.every((b) => b.estado == 1 || b.estado == 3);

    final borderColor = hayAusente
        ? colors.error
        : hayAtrasado
            ? colors.secondary
            : todosPresentes
                ? colors.primary
                : colors.outlineVariant;

    final estadoLabel = hayAusente
        ? 'Ausente'
        : hayAtrasado
            ? 'Atrasado'
            : 'Presente';

    final estadoIcon = hayAusente
        ? Icons.cancel_outlined
        : hayAtrasado
            ? Icons.schedule_outlined
            : Icons.check_circle_outline;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: borderColor.withValues(alpha: 0.4), width: 1.5),
        color: colors.surface,
      ),
      child: Column(
        children: [
          // Encabezado
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: borderColor.withValues(alpha: 0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: borderColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(estadoIcon, size: 20, color: borderColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            fechaFormateada,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: colors.onSurface,
                            ),
                          ),
                          if (_esHoy) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1,),
                              decoration: BoxDecoration(
                                color: colors.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Hoy',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: colors.onPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        diaSemana,
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // Estado del día
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: borderColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    estadoLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: borderColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Bloques
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: bloques.map((b) => _BloquePill(bloque: b)).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pill de un bloque ─────────────────────────────────────────────────────────

class _BloquePill extends StatelessWidget {
  final AsistenciaClaseEntity bloque;
  const _BloquePill({required this.bloque});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final (bg, fg, icon) = switch (bloque.estado) {
      1 => (
          colors.primaryContainer,
          colors.onPrimaryContainer,
          Icons.check_circle_outline
        ),
      0 => (
          colors.errorContainer,
          colors.onErrorContainer,
          Icons.cancel_outlined
        ),
      3 => (
          colors.tertiaryContainer,
          colors.onTertiaryContainer,
          Icons.verified_outlined
        ),
      -1 => (
          colors.secondaryContainer,
          colors.onSecondaryContainer,
          Icons.schedule_outlined
        ),
      _ => (
          colors.surfaceContainerHighest,
          colors.onSurface,
          Icons.help_outline
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: fg),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Bloque ${bloque.bloque}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
              Text(
                bloque.estadoTexto,
                style: TextStyle(
                  fontSize: 10,
                  color: fg.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Tarjeta de resumen ────────────────────────────────────────────────────────

class _ResumenCard extends StatelessWidget {
  final AsistenciaCursoEntity? resumen;
  final List<AsistenciaClaseEntity> clases;

  const _ResumenCard({required this.resumen, required this.clases});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final pct = resumen?.porcentaje ?? 0;
    final presentes =
        resumen?.presentes ?? clases.where((c) => c.estado == 1).length;
    final ausentes =
        resumen?.ausentes ?? clases.where((c) => c.estado == 0).length;
    final total = resumen?.total ?? clases.length;
    final justificados = clases.where((c) => c.estado == 3).length;
    final atrasados = clases.where((c) => c.estado == -1).length;

    final cardColor = pct >= 75
        ? colors.primaryContainer
        : pct >= 50
            ? colors.secondaryContainer
            : colors.errorContainer;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                '$pct%',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
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
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct / 100,
                        minHeight: 8,
                        backgroundColor: colors.surface.withValues(alpha: 0.5),
                        color: pct >= 75
                            ? colors.primary
                            : pct >= 50
                                ? colors.secondary
                                : colors.error,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pct >= 75
                          ? '✓ Cumple asistencia mínima'
                          : pct >= 50
                              ? '⚠ En riesgo de reprobar por inasistencia'
                              : '✗ No cumple asistencia mínima',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _Stat(
                valor: presentes,
                label: 'Presentes',
                icon: Icons.check_circle_outline,
              ),
              _Stat(
                valor: ausentes,
                label: 'Ausentes',
                icon: Icons.cancel_outlined,
              ),
              if (justificados > 0)
                _Stat(
                  valor: justificados,
                  label: 'Justif.',
                  icon: Icons.verified_outlined,
                ),
              if (atrasados > 0)
                _Stat(
                  valor: atrasados,
                  label: 'Atrasados',
                  icon: Icons.schedule_outlined,
                ),
              _Stat(
                valor: total,
                label: 'Total',
                icon: Icons.calendar_month_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final int valor;
  final String label;
  final IconData icon;
  const _Stat({required this.valor, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.onSurface;
    return Column(
      children: [
        Icon(icon, size: 15, color: c.withValues(alpha: 0.6)),
        const SizedBox(height: 2),
        Text(
          '$valor',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: c),
        ),
        Text(label,
            style: TextStyle(fontSize: 10, color: c.withValues(alpha: 0.6)),),
      ],
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

  // Dominios autorizados para QR de asistencia
  static const _dominiosPermitidos = {'losvilos.ucn.cl'};

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
    final uri = Uri.tryParse(raw);
    final dominioPermitido =
        uri != null && _dominiosPermitidos.contains(uri.host);
    if (uri != null && uri.scheme == 'https' && dominioPermitido) {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR no reconocido o dominio no autorizado')),
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
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(16)),
              child: MobileScanner(
                  controller: _controller, onDetect: _onDetect,),
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