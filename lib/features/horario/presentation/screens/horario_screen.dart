import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/horario_entity.dart';
import '../providers/horario_provider.dart';
import '../widgets/horario_filtros_sheet.dart';
import '../widgets/horario_grilla.dart';
import '../widgets/horario_search_bar.dart';

class HorarioScreen extends ConsumerStatefulWidget {
  const HorarioScreen({super.key});

  @override
  ConsumerState<HorarioScreen> createState() => _HorarioScreenState();
}

class _HorarioScreenState extends ConsumerState<HorarioScreen> {
  final _searchController = TextEditingController();

  /// Evita que el listener active ":" más de una vez por sesión.
  /// Se resetea a false al hacer logout, permitiendo que el próximo
  /// login (o reinicio con sesión activa) vuelva a activarlo.
  bool _misRamosActivado = false;

  @override
  void initState() {
    super.initState();
    // Caso: la pantalla se monta cuando auth ya resolvió (AuthAuthenticated).
    // Esto ocurre si el usuario navega de vuelta a Horario después de loguearse,
    // o si StatefulShellRoute restaura el estado con sesión ya activa.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authProvider);
      if (authState is AuthAuthenticated && !_misRamosActivado) {
        _activarMisRamos();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _activarMisRamos() {
    _misRamosActivado = true;
    _searchController.text = ':';
    ref.read(horarioSearchProvider.notifier).state = ':';
  }

  void _desactivarMisRamos() {
    _misRamosActivado = false;
    _searchController.clear();
    ref.read(horarioSearchProvider.notifier).state = '';
    ref.read(horarioFiltroProvider.notifier).reset();
  }

  @override
  Widget build(BuildContext context) {
    final horario = ref.watch(horarioFiltradoProvider);
    final master = ref.watch(masterProvider);

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is AuthAuthenticated && !_misRamosActivado) {
        // El flag garantiza que solo se activa UNA vez por sesión,
        // sin importar cuántas veces AuthLoading → AuthAuthenticated
        // dispare el listener (reinicio con sesión o login manual).
        _activarMisRamos();
      } else if (next is AuthUnauthenticated || next is AuthError) {
        if (_misRamosActivado) _desactivarMisRamos();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Horario'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: () {
              ref
                ..invalidate(masterProvider)
                ..invalidate(horarioProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Filtros',
            onPressed: () => _mostrarFiltros(context, ref),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: HorarioSearchBar(
              controller: _searchController,
              onChanged: (text) =>
                  ref.read(horarioSearchProvider.notifier).state = text,
            ),
          ),
        ),
      ),
      body: master.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(
          mensaje: e.toString(),
          onRetry: () => ref.invalidate(masterProvider),
        ),
        data: (masterData) => _HorarioBody(
          horario: horario,
          master: masterData,
          onRetry: () => ref.invalidate(horarioProvider),
        ),
      ),
    );
  }

  void _mostrarFiltros(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const HorarioFiltrosSheet(),
    );
  }
}

// ── Cuerpo con la grilla ──────────────────────────────────────────────────────

class _HorarioBody extends StatelessWidget {
  final AsyncValue<List<HorarioItemEntity>> horario;
  final MasterEntity master;
  final VoidCallback onRetry;

  const _HorarioBody({
    required this.horario,
    required this.master,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return horario.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorView(mensaje: e.toString(), onRetry: onRetry),
      data: (items) => items.isEmpty
          ? const _EmptyView()
          : HorarioGrilla(items: items, master: master),
    );
  }
}

// ── Vistas auxiliares ─────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String mensaje;
  final VoidCallback onRetry;

  const _ErrorView({required this.mensaje, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 64, color: colors.error),
            const SizedBox(height: 16),
            Text(
              'No se pudo cargar el horario',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              mensaje,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: colors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
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

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.event_busy_rounded,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Sin resultados',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Ajusta los filtros para ver el horario',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}