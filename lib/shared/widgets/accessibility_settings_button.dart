import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/accessibility_settings.dart';

class AccessibilitySettingsButton extends StatelessWidget {
  const AccessibilitySettingsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Accesibilidad',
      icon: const Icon(Icons.accessibility_new_outlined),
      onPressed: () => showAccessibilitySettingsSheet(context),
    );
  }
}

void showAccessibilitySettingsSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    // isScrollControlled + el SingleChildScrollView de abajo permiten que el
    // sheet crezca y se pueda scrollear si el fontScale hace que el
    // contenido no entre en la altura por defecto (evita que el slider de
    // tamaño de letra quede recortado fuera de la pantalla).
    isScrollControlled: true,
    builder: (_) => const _AccessibilitySettingsSheet(),
  );
}

class _AccessibilitySettingsSheet extends ConsumerWidget {
  const _AccessibilitySettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(accessibilitySettingsProvider);
    final notifier = ref.read(accessibilitySettingsProvider.notifier);

    // El sheet controla el fontScale de TODA la app (incluyéndose a sí
    // mismo, porque cuelga del mismo MediaQuery global de main.dart). Si no
    // le ponemos un techo propio, subir el tamaño de letra al máximo hace
    // que el propio panel de accesibilidad se vuelva difícil de usar. Lo
    // limitamos a un valor razonable, independiente del que el usuario
    // elija para el resto de la app.
    const maxOwnScale = 1.25;
    final ownScale = settings.fontScale.clamp(0.9, maxOwnScale).toDouble();

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(ownScale),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          // SingleChildScrollView: si aun así el contenido no entra en la
          // altura del sheet (pantallas chicas, fuente del sistema grande),
          // queda scrolleable en vez de recortado.
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Accesibilidad',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Tema',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        icon: Icon(Icons.brightness_auto_outlined),
                        label: Text('Sistema'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: Icon(Icons.light_mode_outlined),
                        label: Text('Claro'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode_outlined),
                        label: Text('Oscuro'),
                      ),
                    ],
                    selected: {settings.themeMode},
                    onSelectionChanged: (value) =>
                        notifier.setThemeMode(value.first),
                  ),
                ),
                const SizedBox(height: 18),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.visibility_outlined),
                  title: const Text('Modo daltonico'),
                  subtitle: const Text('Usa paleta Okabe-Ito en toda la app'),
                  value: settings.colorBlindMode,
                  onChanged: notifier.setColorBlindMode,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.format_size_outlined),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Tamano de fuente',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    Text('${(settings.fontScale * 100).round()}%'),
                    // Salida rápida de un toque: si el usuario quedó con la
                    // fuente al máximo y le cuesta manejar el slider, puede
                    // volver a 100% sin depender de arrastrarlo.
                    IconButton(
                      tooltip: 'Restablecer tamaño de fuente',
                      icon: const Icon(Icons.restart_alt),
                      onPressed: settings.fontScale == 1.0
                          ? null
                          : () => notifier.setFontScale(1.0),
                    ),
                  ],
                ),
                Slider(
                  min: 0.9,
                  max: 1.6,
                  divisions: 7,
                  label: '${(settings.fontScale * 100).round()}%',
                  value: settings.fontScale,
                  onChanged: notifier.setFontScale,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}