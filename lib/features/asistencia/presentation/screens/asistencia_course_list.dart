part of 'asistencia_screen.dart';

//lista de cursos para ver asistencia

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
        ...cursos.map(
          (c) => _CursoAsistenciaTile(
            curso: c,
            asistencia: map['${c.codigo}|${c.seccion}'],
            onTap: () => onCursoTap(c),
          ),
        ),
      ],
    );
  }
}


class _CursoAsistenciaTile extends ConsumerWidget {
  final CursoUsuarioEntity curso;
  final AsistenciaCursoEntity? asistencia;
  final VoidCallback onTap;

  const _CursoAsistenciaTile({
    required this.curso,
    required this.asistencia,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final stateColors = _attendanceColors(context, ref);
    final pct = asistencia?.porcentaje ?? 0;
    final tieneData = asistencia != null;

    final barColor =
        !tieneData ? colors.outlineVariant : stateColors.forPorcentaje(pct);

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
                      tieneData ? '$pct%' : '0%',
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
                      '${curso.codigo} - Seccion ${curso.seccion}',
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
                            color: _stateContainer(
                              stateColors.presente,
                              colors.surface,
                            ),
                            textColor: _readableStateText(
                              stateColors.presente,
                              Theme.of(context).brightness,
                            ),
                          ),
                          const SizedBox(width: 6),
                          _MiniChip(
                            label: '${asistencia!.ausentes} aus.',
                            color: _stateContainer(
                              stateColors.ausente,
                              colors.surface,
                            ),
                            textColor: _readableStateText(
                              stateColors.ausente,
                              Theme.of(context).brightness,
                            ),
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
  const _MiniChip({
    required this.label,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
