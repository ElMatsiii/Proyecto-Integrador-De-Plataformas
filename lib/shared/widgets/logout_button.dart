import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_provider_notif.dart';

/// IconButton de logout reutilizable para cualquier AppBar.
/// Muestra un diálogo de confirmación antes de cerrar sesión.
class LogoutButton extends ConsumerWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.logout),
      tooltip: 'Cerrar sesión',
      onPressed: () => _confirmarLogout(context, ref),
    );
  }

  void _confirmarLogout(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Quieres cerrar tu sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              ref.read(authProvider.notifier).logout();
            },
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }
}