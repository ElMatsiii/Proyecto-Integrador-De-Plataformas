import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/accessibility_settings_button.dart';
import '../providers/auth_provider_notif.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usuarioCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usuarioCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authProvider.notifier).login(
          _usuarioCtrl.text.trim(),
          _passwordCtrl.text,
        );
  }

  Future<void> _loginConGoogle() async {
    await ref.read(authProvider.notifier).loginConGoogle();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (_, next) {
      if (next is AuthAuthenticated) {
        context.goNamed(AppRoutes.misCursosName);
      }
    });

    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthLoading;
    final errorMsg = authState is AuthError ? (authState).message : null;

    // No mostrar el error cuando el usuario simplemente cerró el selector
    // de cuentas de Google — no es un error real.
    final errorVisible =
        errorMsg != null && errorMsg != 'Inicio de sesión cancelado';

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned(
              top: 4,
              right: 4,
              child: AccessibilitySettingsButton(),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo / encabezado
                        const _LoginHeader(),
                        const SizedBox(height: 40),

                        // Campo usuario
                        TextFormField(
                          controller: _usuarioCtrl,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          decoration: const InputDecoration(
                            labelText: 'Correo o RUT',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Ingresa tu usuario'
                              : null,
                        ),
                        const SizedBox(height: 12),

                        // Campo contraseña
                        TextFormField(
                          controller: _passwordCtrl,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _login(),
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                          ),
                          validator: (v) => v == null || v.isEmpty
                              ? 'Ingresa tu contraseña'
                              : null,
                        ),
                        const SizedBox(height: 8),

                        // Mensaje de error
                        if (errorVisible) ...[
                          const SizedBox(height: 8),
                          _ErrorBanner(mensaje: errorMsg!),
                        ],

                        const SizedBox(height: 24),

                        // Botón ingresar con usuario/contraseña
                        FilledButton(
                          onPressed: isLoading ? null : _login,
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Ingresar'),
                        ),
                        const SizedBox(height: 12),

                        // Divisor "o"
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'o',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Botón de Google
                        OutlinedButton.icon(
                          onPressed: isLoading ? null : _loginConGoogle,
                          icon: const _GoogleIcon(),
                          label: const Text('Continuar con Google'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Continuar sin cuenta
                        OutlinedButton(
                          onPressed: () =>
                              context.goNamed(AppRoutes.horarioName),
                          child: const Text('Ver horario sin iniciar sesión'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Ícono de Google dibujado con Canvas (sin depender de imágenes externas) ───

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GoogleIconPainter()),
    );
  }
}

class _GoogleIconPainter extends CustomPainter {
  const _GoogleIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius * 0.75);
    final stroke = size.width * 0.18;

    // Arco rojo
    canvas.drawArc(
      rect, -0.35, 1.6, false,
      Paint()
        ..color = const Color(0xFFEA4335)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt,
    );
    // Arco amarillo
    canvas.drawArc(
      rect, 1.25, 0.75, false,
      Paint()
        ..color = const Color(0xFFFBBC05)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt,
    );
    // Arco verde
    canvas.drawArc(
      rect, 2.0, 0.75, false,
      Paint()
        ..color = const Color(0xFF34A853)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt,
    );
    // Arco azul
    canvas.drawArc(
      rect, 2.75, 1.2, false,
      Paint()
        ..color = const Color(0xFF4285F4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt,
    );
    // Barra horizontal del "G"
    canvas.drawLine(
      Offset(center.dx, center.dy),
      Offset(center.dx + radius * 0.75, center.dy),
      Paint()
        ..color = const Color(0xFF4285F4)
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Widgets sin cambios respecto al original ──────────────────────────────────

class _LoginHeader extends StatelessWidget {
  const _LoginHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            Icons.school_rounded,
            size: 44,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Tongoy UCN',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Ingresa con tu cuenta UCN',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String mensaje;
  const _ErrorBanner({required this.mensaje});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              mensaje,
              style: TextStyle(color: colors.onErrorContainer, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}