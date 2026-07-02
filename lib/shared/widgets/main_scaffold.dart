import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/shell_navigation_provider.dart';

class MainScaffold extends ConsumerStatefulWidget {
  final StatefulNavigationShell shell;
  const MainScaffold({required this.shell, super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncIndex());
  }

  @override
  void didUpdateWidget(covariant MainScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncIndex());
  }

  void _syncIndex() {
    if (!mounted) return;
    final current = ref.read(currentShellIndexProvider);
    if (current != widget.shell.currentIndex) {
      ref.read(currentShellIndexProvider.notifier).state =
          widget.shell.currentIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Cubre también el primer build (antes de que exista un "old widget").
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncIndex());

    return Scaffold(
      body: widget.shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.shell.currentIndex,
        onDestinationSelected: (index) => widget.shell.goBranch(
          index,
          initialLocation: index == widget.shell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Horario',
          ),
          NavigationDestination(
            icon: Icon(Icons.book_outlined),
            selectedIcon: Icon(Icons.book),
            label: 'Mis Cursos',
          ),
          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check),
            label: 'Asistencia',
          ),
        ],
      ),
    );
  }
}