import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/asistencia/presentation/screens/asistencia_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/horario/presentation/screens/horario_screen.dart';
import '../../features/mis_cursos/presentation/screens/mis_cursos_screen.dart';
import '../../shared/widgets/main_scaffold.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.horario,
    debugLogDiagnostics: false,
    routes: [
      // Shell con bottom navigation bar
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainScaffold(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.horario,
              name: AppRoutes.horarioName,
              builder: (_, __) => const HorarioScreen(),
            ),
          ],),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.misCursos,
              name: AppRoutes.misCursosName,
              builder: (_, __) => const MisCursosScreen(),
            ),
          ],),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.asistencia,
              name: AppRoutes.asistenciaName,
              builder: (_, __) => const AsistenciaScreen(),
            ),
          ],),
        ],
      ),
      GoRoute(
        path: AppRoutes.login,
        name: AppRoutes.loginName,
        builder: (_, __) => const LoginScreen(),
      ),
    ],
  );
});

abstract class AppRoutes {
  static const horario = '/horario';
  static const horarioName = 'horario';
  static const misCursos = '/mis-cursos';
  static const misCursosName = 'mis-cursos';
  static const asistencia = '/asistencia';
  static const asistenciaName = 'asistencia';
  static const login = '/login';
  static const loginName = 'login';
}
