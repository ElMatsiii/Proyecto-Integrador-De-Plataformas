import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tongoy_app/shared/theme/app_theme.dart';

// Router mínimo para el smoke test — sin dependencias de red ni DioClient.
final _testRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => const Scaffold(body: Text('test')),
    ),
  ],
);

class _TestApp extends StatelessWidget {
  const _TestApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Tongoy UCN',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: _testRouter,
    );
  }
}

void main() {
  testWidgets('TongoyApp arranca sin errores', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: _TestApp()),
    );
    expect(find.byType(Router), findsOneWidget);
  });
}