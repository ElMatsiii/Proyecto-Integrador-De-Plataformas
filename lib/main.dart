import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/network/dio_client.dart';
import 'core/router/app_router.dart';
import 'core/services/notificaciones_service.dart';
import 'shared/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DioClient.init();

  // Inicializar el servicio de notificaciones locales
  final notifService = NotificacionesService();
  await notifService.init();

  runApp(
    ProviderScope(
      overrides: [
        // Inyectamos la instancia ya inicializada
        notificacionesServiceProvider.overrideWithValue(notifService),
      ],
      child: const TongoyApp(),
    ),
  );
}

class TongoyApp extends ConsumerWidget {
  const TongoyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Tongoy UCN',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}