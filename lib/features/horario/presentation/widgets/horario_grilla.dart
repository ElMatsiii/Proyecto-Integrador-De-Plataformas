import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/horario_entity.dart';

/// Vista de horario por día con PageView deslizable.
class HorarioGrilla extends StatefulWidget {
  final List<HorarioItemEntity> items;
  final MasterEntity master;

  const HorarioGrilla({required this.items, required this.master, super.key});

  @override
  State<HorarioGrilla> createState() => _HorarioGrillaState();
}

class _HorarioGrillaState extends State<HorarioGrilla> {
  static const _dias = [
    'Lunes',
    'Martes',
    'Miercoles',
    'Jueves',
    'Viernes',
    'Sabado',
  ];

  late List<String> _diasConClases;
  late final PageController _pageController;
  int _paginaActual = 0;

  @override
  void initState() {
    super.initState();
    _diasConClases =
        _dias.where((d) => widget.items.any((i) => i.dia == d)).toList();

    final hoy = _diaActual();
    final indexHoy = _diasConClases.indexOf(hoy);
    _paginaActual = indexHoy >= 0 ? indexHoy : 0;
    _pageController = PageController(initialPage: _paginaActual);
  }

  @override
  void didUpdateWidget(covariant HorarioGrilla oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Si los items cambiaron (ej: el provider terminó de cargar el horario
    // completo, o se activó/desactivó el filtro "mis ramos"), recalculamos
    // qué días deben mostrarse en la grilla.
    if (oldWidget.items != widget.items) {
      final nuevosDias =
          _dias.where((d) => widget.items.any((i) => i.dia == d)).toList();

      if (!listEquals(nuevosDias, _diasConClases)) {
        final diaActualSeleccionado = _diasConClases.isNotEmpty &&
                _paginaActual < _diasConClases.length
            ? _diasConClases[_paginaActual]
            : null;

        setState(() {
          _diasConClases = nuevosDias;

          // Intentar mantener al usuario en el mismo día si sigue existiendo,
          // si no, ajustar al rango válido.
          if (diaActualSeleccionado != null &&
              _diasConClases.contains(diaActualSeleccionado)) {
            _paginaActual = _diasConClases.indexOf(diaActualSeleccionado);
          } else if (_paginaActual >= _diasConClases.length) {
            _paginaActual =
                _diasConClases.isEmpty ? 0 : _diasConClases.length - 1;
          }
        });

        if (_pageController.hasClients && _diasConClases.isNotEmpty) {
          _pageController.jumpToPage(_paginaActual);
        }
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _diaActual() {
    const mapaDias = {
      1: 'Lunes',
      2: 'Martes',
      3: 'Miercoles',
      4: 'Jueves',
      5: 'Viernes',
      6: 'Sabado',
    };
    return mapaDias[DateTime.now().weekday] ?? 'Lunes';
  }

  @override
  Widget build(BuildContext context) {
    if (_diasConClases.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        _DiaIndicador(
          dias: _diasConClases,
          paginaActual: _paginaActual,
          onDiaTap: (index) {
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
        ),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: _diasConClases.length,
            onPageChanged: (index) => setState(() => _paginaActual = index),
            itemBuilder: (_, index) {
              final dia = _diasConClases[index];
              final itemsDia = widget.items.where((i) => i.dia == dia).toList();
              final bloquesDelDia = widget.master.bloques
                  .where((b) => itemsDia.any((i) => i.bloque == b.nombre))
                  .toList();

              return _DiaPage(
                dia: dia,
                bloques: bloquesDelDia,
                items: itemsDia,
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Indicador de días ─────────────────────────────────────────────────────────

class _DiaIndicador extends StatelessWidget {
  final List<String> dias;
  final int paginaActual;
  final ValueChanged<int> onDiaTap;

  const _DiaIndicador({
    required this.dias,
    required this.paginaActual,
    required this.onDiaTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          bottom: BorderSide(color: colors.outlineVariant, width: 1),
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(dias.length, (index) {
              final seleccionado = index == paginaActual;
              return GestureDetector(
                onTap: () => onDiaTap(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: seleccionado
                        ? colors.primary
                        : colors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    dias[index].substring(0, 3).toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: seleccionado ? colors.onPrimary : colors.onSurface,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ── Página de un día ──────────────────────────────────────────────────────────

class _DiaPage extends StatelessWidget {
  final String dia;
  final List<BloqueEntity> bloques;
  final List<HorarioItemEntity> items;

  const _DiaPage({
    required this.dia,
    required this.bloques,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_available_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'Sin clases el $dia',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      itemCount: bloques.length,
      itemBuilder: (_, i) {
        final bloque = bloques[i];
        final itemsBloque =
            items.where((item) => item.bloque == bloque.nombre).toList();
        return _BloqueRow(bloque: bloque, items: itemsBloque);
      },
    );
  }
}

// ── Fila de un bloque ─────────────────────────────────────────────────────────

class _BloqueRow extends StatelessWidget {
  final BloqueEntity bloque;
  final List<HorarioItemEntity> items;

  const _BloqueRow({required this.bloque, required this.items});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      // Padding externo: separa la fila de los bordes de la pantalla
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Etiqueta del bloque — ancho fijo, pegada al borde del padding
            SizedBox(
              width: 52,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    bloque.nombre,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: colors.primary,
                    ),
                  ),
                  if (bloque.horario != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      bloque.horario!.replaceAll(' - ', '\n'),
                      style: TextStyle(
                        fontSize: 8,
                        color: colors.onSurfaceVariant,
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Tarjetas — Expanded para ocupar todo el ancho restante
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: items.map((item) => _ClaseCard(item: item)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tarjeta de una clase ──────────────────────────────────────────────────────

class _ClaseCard extends StatelessWidget {
  final HorarioItemEntity item;
  const _ClaseCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _mostrarDetalle(context, item),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nombreCorto(item.curso),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.onPrimaryContainer,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 13,
                      color: colors.onPrimaryContainer.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.profesor,
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              colors.onPrimaryContainer.withValues(alpha: 0.7),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.room_outlined,
                      size: 13,
                      color: colors.onPrimaryContainer.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.sala,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onPrimaryContainer.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _nombreCorto(String nombreCompleto) {
    final match = RegExp(r'^(.+?)\s*\(').firstMatch(nombreCompleto);
    return match?.group(1)?.trim() ?? nombreCompleto;
  }

  void _mostrarDetalle(BuildContext context, HorarioItemEntity item) {
    showDialog<void>(
      context: context,
      builder: (_) => _ClaseDetalleDialog(item: item),
    );
  }
}

// ── Diálogo de detalle ────────────────────────────────────────────────────────

class _ClaseDetalleDialog extends StatelessWidget {
  final HorarioItemEntity item;
  const _ClaseDetalleDialog({required this.item});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(item.curso, style: const TextStyle(fontSize: 15)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetalleRow(icon: Icons.person_outline, label: item.profesor),
          _DetalleRow(icon: Icons.room_outlined, label: item.sala),
          _DetalleRow(icon: Icons.business_outlined, label: item.area),
          _DetalleRow(icon: Icons.tag, label: 'NRC: ${item.nrc}'),
          if (item.carreras.isNotEmpty)
            _DetalleRow(
              icon: Icons.school_outlined,
              label: item.carreras
                  .map((c) => '${c.nombre} (sem. ${c.semestre})')
                  .join(', '),
            ),
          if (item.comentario.isNotEmpty)
            _DetalleRow(
              icon: Icons.comment_outlined,
              label: item.comentario,
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}

class _DetalleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _DetalleRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}