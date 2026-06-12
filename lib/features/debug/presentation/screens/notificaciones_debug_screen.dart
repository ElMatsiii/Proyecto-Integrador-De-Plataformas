import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/notificaciones_service.dart';
import '../../../horario/presentation/providers/horario_provider_notif.dart';

/// Pantalla de diagnóstico de notificaciones.
/// Reúne todos los chequeos en un solo lugar: permisos, prueba inmediata,
/// prueba programada, listado de pendientes y reprogramación de la semana.
///
/// Solo se llega aquí desde el botón de debug del Horario (visible únicamente
/// en builds de debug).
class NotificacionesDebugScreen extends ConsumerStatefulWidget {
  const NotificacionesDebugScreen({super.key});

  @override
  ConsumerState<NotificacionesDebugScreen> createState() =>
      _NotificacionesDebugScreenState();
}

class _NotificacionesDebugScreenState
    extends ConsumerState<NotificacionesDebugScreen> {
  final List<String> _log = [];
  bool _ocupado = false;

  NotificacionesService get _service =>
      ref.read(notificacionesServiceProvider);

  void _agregar(String linea) {
    if (!mounted) return;
    setState(() {
      _log.insert(0, '${TimeOfDay.now().format(context)}  $linea');
    });
  }

  Future<void> _ejecutar(Future<void> Function() accion) async {
    setState(() => _ocupado = true);
    try {
      await accion();
    } catch (e) {
      _agregar('❌ Error: $e');
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  // ── Acciones ──────────────────────────────────────────────────────────────

  Future<void> _verificarPermisos() => _ejecutar(() async {
        final estado = await _service.verificarPermisos();
        _agregar(
          'Permisos → notificaciones: ${estado.notisActivas ? "✅" : "❌"}   '
          'alarmas exactas: ${estado.exactasOk ? "✅" : "❌"}',
        );
        if (!estado.notisActivas || !estado.exactasOk) {
          _agregar(
            '⚠ Si falta alguno, concédelo en Ajustes del sistema y reintenta',
          );
        }
      });

  Future<void> _pruebaInmediata() => _ejecutar(() async {
        await _service.mostrarPrueba();
        _agregar('Notificación inmediata enviada (deberías verla ya)');
      });

  Future<void> _pruebaProgramada() => _ejecutar(() async {
        await _service.programarPrueba(segundos: 10);
        _agregar(
          'Programada a 10s. Apaga la pantalla y espera — esto usa el '
          'mismo camino que una clase real',
        );
      });

  Future<void> _verPendientes() => _ejecutar(() async {
        final pendientes = await _service.obtenerPendientes();
        _agregar('Pendientes en cola: ${pendientes.length}');
        for (final p in pendientes) {
          _agregar(
            '   #${p.id}  ${p.title ?? "(sin título)"} — ${p.body ?? ""}',
          );
        }
        if (pendientes.isEmpty) {
          _agregar(
            'ℹ Vacío puede ser normal: programarSemana omite horas pasadas '
            'y solo agenda la semana actual',
          );
        }
      });

  Future<void> _reprogramarSemana() => _ejecutar(() async {
        ref.invalidate(notificacionesProgramadasProvider);
        await ref.read(notificacionesProgramadasProvider.future);
        _agregar(
          'Reprogramación disparada (requiere sesión activa y ramos de '
          'estudiante)',
        );
        final pendientes = await _service.obtenerPendientes();
        _agregar('Tras reprogramar, pendientes: ${pendientes.length}');
      });

  Future<void> _cancelarTodas() => _ejecutar(() async {
        await _service.cancelarTodas();
        _agregar('Todas las notificaciones canceladas');
      });

  // ── UI ──────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug · Notificaciones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Limpiar log',
            onPressed: () => setState(_log.clear),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _BotonAccion(
                  icon: Icons.verified_user_outlined,
                  label: '1 · Permisos',
                  onPressed: _ocupado ? null : _verificarPermisos,
                ),
                _BotonAccion(
                  icon: Icons.notifications_active_outlined,
                  label: '2 · Prueba inmediata',
                  onPressed: _ocupado ? null : _pruebaInmediata,
                ),
                _BotonAccion(
                  icon: Icons.timer_outlined,
                  label: '3 · Programar 10s',
                  onPressed: _ocupado ? null : _pruebaProgramada,
                ),
                _BotonAccion(
                  icon: Icons.list_alt_outlined,
                  label: '4 · Ver pendientes',
                  onPressed: _ocupado ? null : _verPendientes,
                ),
                _BotonAccion(
                  icon: Icons.refresh,
                  label: 'Reprogramar semana',
                  onPressed: _ocupado ? null : _reprogramarSemana,
                ),
                _BotonAccion(
                  icon: Icons.clear_all,
                  label: 'Cancelar todas',
                  onPressed: _ocupado ? null : _cancelarTodas,
                ),
              ],
            ),
          ),
          if (_ocupado) const LinearProgressIndicator(),
          const Divider(height: 1),
          Expanded(
            child: _log.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Toca una acción para empezar a diagnosticar.\n\n'
                        'Orden sugerido: 1 → 2 → 3 → 4',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _log.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: SelectableText(
                        _log[i],
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _BotonAccion extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _BotonAccion({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    // OutlinedButton (no FilledButton) para evitar el minimumSize de ancho
    // completo definido en el tema, que rompería el Wrap.
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}