import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Índice de la rama (tab) actualmente activa en el [MainScaffold].
///
/// Se actualiza cada vez que el usuario cambia de pestaña. Las pantallas de
/// cada rama pueden escuchar este provider (con `ref.listen`) para detectar
/// cuándo dejan de estar visibles y así reiniciar su estado interno
/// (por ejemplo, volver a la vista principal de la sección en lugar de
/// mantener la última vista mostrada).
final currentShellIndexProvider = StateProvider<int>((ref) => 0);