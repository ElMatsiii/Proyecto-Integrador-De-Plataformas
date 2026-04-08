import 'package:flutter/material.dart';
import '../../domain/entities/horario_entity.dart';

/// Grilla tipo tabla: filas = bloques horarios, columnas = días de la semana.
class HorarioGrilla extends StatelessWidget {
  final List<HorarioItemEntity> items;
  final MasterEntity master;

  const HorarioGrilla({super.key, required this.items, required this.master});

  static const _dias = ['Lunes', 'Martes', 'Miercoles', 'Jueves', 'Viernes', 'Sabado'];

  @override
  Widget build(BuildContext context) {
    // Determina qué días tienen al menos un bloque para mostrar
    final diasConClases = _dias
        .where((d) => items.any((i) => i.dia == d))
        .toList();

    // Determina los bloques únicos ordenados
    final bloquesUsados = master.bloques
        .where((b) => items.any((i) => i.bloque == b.nombre))
        .toList();

    if (diasConClases.isEmpty || bloquesUsados.isEmpty) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderRow(dias: diasConClases),
            ...bloquesUsados.map(
              (bloque) => _BloqueRow(
                bloque: bloque,
                dias: diasConClases,
                items: items
                    .where((i) => i.bloque == bloque.nombre)
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Fila encabezado ───────────────────────────────────────────────────────────

class _HeaderRow extends StatelessWidget {
  final List<String> dias;
  const _HeaderRow({required this.dias});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        _Cell(
          width: 72,
          child: const SizedBox.shrink(),
          color: colors.surfaceContainerHighest,
        ),
        ...dias.map(
          (dia) => _Cell(
            color: colors.primary,
            child: Text(
              dia.substring(0, 3).toUpperCase(),
              style: TextStyle(
                color: colors.onPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Fila de un bloque ─────────────────────────────────────────────────────────

class _BloqueRow extends StatelessWidget {
  final BloqueEntity bloque;
  final List<String> dias;
  final List<HorarioItemEntity> items;

  const _BloqueRow({
    required this.bloque,
    required this.dias,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Etiqueta del bloque
        _Cell(
          width: 72,
          height: null,
          color: colors.surfaceContainerHighest,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                bloque.nombre,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: colors.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
              if (bloque.horario != null)
                Text(
                  bloque.horario!.replaceAll(' ', '\n'),
                  style: TextStyle(
                    fontSize: 9,
                    color: colors.onSurfaceVariant.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
        // Una celda por día
        ...dias.map((dia) {
          final item = items.where((i) => i.dia == dia).firstOrNull;
          return item != null
              ? _ClaseCell(item: item)
              : _Cell(child: const SizedBox.shrink());
        }),
      ],
    );
  }
}

// ── Celda con clase ───────────────────────────────────────────────────────────

class _ClaseCell extends StatelessWidget {
  final HorarioItemEntity item;
  const _ClaseCell({required this.item});

  @override
  Widget build(BuildContext context) {
    return _Cell(
      height: null,
      color: Theme.of(context).colorScheme.primaryContainer,
      child: InkWell(
        onTap: () => _mostrarDetalle(context, item),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _nombreCorto(item.curso),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                item.sala,
                style: TextStyle(
                  fontSize: 9,
                  color: Theme.of(context)
                      .colorScheme
                      .onPrimaryContainer
                      .withOpacity(0.7),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Extrae solo el nombre limpio del curso sin código ni sección.
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

// ── Diálogo de detalle de clase ────────────────────────────────────────────────

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
          Icon(icon,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ── Celda base ────────────────────────────────────────────────────────────────

class _Cell extends StatelessWidget {
  final Widget child;
  final double width;
  final double? height;
  final Color? color;

  const _Cell({
    required this.child,
    this.width = 120,
    this.height = 80,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      constraints: const BoxConstraints(minHeight: 70),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(4),
      child: Center(child: child),
    );
  }
}
