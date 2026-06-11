// DESPUÉS (smoke test real):
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongoy_app/main.dart';

void main() {
  testWidgets('TongoyApp arranca sin errores', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: TongoyApp(),
      ),
    );
    // Verifica que el árbol de widgets se construyó
    expect(find.byType(MaterialApp), findsNothing); // usa MaterialApp.router
    expect(find.byType(Router), findsOneWidget);
  });
}