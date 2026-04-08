import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/horario_provider.dart';

class HorarioFiltrosSheet extends ConsumerWidget {
  const HorarioFiltrosSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final master = ref.watch(masterProvider);
    final filtro = ref.watch(horarioFiltroProvider);
    final notifier = ref.read(horarioFiltroProvider.notifier);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (_, controller) => Column(
        children: [
          // Handle
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Encabezado
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
            child: Row(
              children: [
                Text('Filtros',
                    style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    notifier.reset();
                    Navigator.pop(context);
                  },
                  child: const Text('Limpiar'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: master.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  Center(child: Text('Error: $e')),
              data: (m) => ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  // Semestre
                  _FiltroDropdown<int>(
                    label: 'Semestre',
                    icon: Icons.calendar_month_outlined,
                    value: filtro.semestre == -1 ? null : filtro.semestre,
                    items: m.semestres
                        .map((s) =>
                            DropdownMenuItem(value: s.id, child: Text(s.nombre)))
                        .toList(),
                    onChanged: (v) => notifier.setSemestre(v ?? -1),
                  ),
                  // Área
                  _FiltroDropdown<int>(
                    label: 'Área',
                    icon: Icons.business_outlined,
                    value: filtro.area == -1 ? null : filtro.area,
                    items: m.areas
                        .map((a) =>
                            DropdownMenuItem(value: a.id, child: Text(a.nombre)))
                        .toList(),
                    onChanged: (v) => notifier.setArea(v ?? -1),
                  ),
                  // Profesor
                  _FiltroDropdown<int>(
                    label: 'Profesor',
                    icon: Icons.person_outline,
                    value: filtro.profesor == -1 ? null : filtro.profesor,
                    items: m.profesores
                        .map((p) =>
                            DropdownMenuItem(value: p.id, child: Text(p.nombre)))
                        .toList(),
                    onChanged: (v) => notifier.setProfesor(v ?? -1),
                  ),
                  // Sala
                  _FiltroDropdown<int>(
                    label: 'Sala',
                    icon: Icons.room_outlined,
                    value: filtro.sala == -1 ? null : filtro.sala,
                    items: m.salas
                        .map((s) =>
                            DropdownMenuItem(value: s.id, child: Text(s.nombre)))
                        .toList(),
                    onChanged: (v) => notifier.setSala(v ?? -1),
                  ),
                  // Curso
                  _FiltroDropdown<int>(
                    label: 'Curso',
                    icon: Icons.book_outlined,
                    value: filtro.curso == -1 ? null : filtro.curso,
                    items: m.cursos
                        .map((c) =>
                            DropdownMenuItem(value: c.id, child: Text(c.nombre)))
                        .toList(),
                    onChanged: (v) => notifier.setCurso(v ?? -1),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Aplicar filtros'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FiltroDropdown<T> extends StatelessWidget {
  final String label;
  final IconData icon;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _FiltroDropdown({
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
        ),
        isExpanded: true,
        hint: Text('Todos'),
        items: [
          DropdownMenuItem<T>(
            value: null,
            child: Text('Todos', style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            )),
          ),
          ...items,
        ],
        onChanged: onChanged,
      ),
    );
  }
}
