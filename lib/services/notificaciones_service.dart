import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../../features/horario/domain/entities/horario_entity.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final notificacionesServiceProvider = Provider<NotificacionesService>((ref) {
  return NotificacionesService();
});

// ── Servicio ──────────────────────────────────────────────────────────────────

class NotificacionesService {
  static const _channelId = 'tongoy_clases';
  static const _channelName = 'Clases UCN';
  static const _channelDesc = 'Avisos de clases próximas a iniciar';
  static const _minutosAntes = 15;

  // Zona horaria de Chile continental
  static const _zonaHoraria = 'America/Santiago';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Inicializa el plugin. Llamar una sola vez en main().
  Future<void> init() async {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(_zonaHoraria));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    // Solicitar permisos en Android 13+
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Cancela todas las notificaciones programadas y reprograma
  /// las de la semana actual basándose en los items del horario.
  ///
  /// [items] son los bloques del usuario (ya filtrados: solo sus ramos).
  /// [bloques] es el maestro de bloques para obtener el horario exacto.
  Future<void> programarSemana({
    required List<HorarioItemEntity> items,
    required List<BloqueEntity> bloques,
  }) async {
    await _plugin.cancelAll();

    final ahora = tz.TZDateTime.now(tz.local);
    final lunesDeEstaSemana = _lunesDe(ahora);

    // Mapa de nombre de bloque → hora de inicio
    final horarioBloque = <String, _HoraBloque>{};
    for (final b in bloques) {
      final hora = _parsearHorario(b.horario);
      if (hora != null) {
        horarioBloque[b.nombre] = hora;
      }
    }

    // Mapa de nombre de día → offset desde el lunes (0=lun, 1=mar...)
    const offsetDia = {
      'Lunes': 0,
      'Martes': 1,
      'Miercoles': 2,
      'Jueves': 3,
      'Viernes': 4,
      'Sabado': 5,
    };

    var notifId = 0;

    for (final item in items) {
      final offset = offsetDia[item.dia];
      final hora = horarioBloque[item.bloque];
      if (offset == null || hora == null) continue;

      // Fecha del día de clase en esta semana
      final diaClase = lunesDeEstaSemana.add(Duration(days: offset));
      final fechaClase = tz.TZDateTime(
        tz.local,
        diaClase.year,
        diaClase.month,
        diaClase.day,
        hora.hora,
        hora.minuto,
      );

      // Programar 15 minutos antes
      final fechaNotif =
          fechaClase.subtract(const Duration(minutes: _minutosAntes));

      // No programar notificaciones en el pasado
      if (fechaNotif.isBefore(ahora)) continue;

      final nombreCorto = _nombreCorto(item.curso);

      await _plugin.zonedSchedule(
        notifId++,
        '📚 Clase en $_minutosAntes minutos',
        '$nombreCorto · Bloque ${item.bloque} · ${item.sala}',
        fechaNotif,
        _detalles(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  /// Cancela todas las notificaciones (al hacer logout).
  Future<void> cancelarTodas() => _plugin.cancelAll();

  // ── Diagnóstico / pruebas ───────────────────────────────────────────────────
  //
  // Estos métodos son utilidades para verificar que las notificaciones
  // funcionan. No se usan en el flujo normal de la app.

  /// Verifica (y opcionalmente solicita) los permisos necesarios en Android.
  /// En iOS los permisos se piden en init(), aquí se asume concedido.
  ///
  /// - notisActivas: el usuario permite notificaciones (Android 13+).
  /// - exactasOk: el sistema permite alarmas exactas (necesario para
  ///   zonedSchedule con exactAllowWhileIdle). Si esto es false en Android 12+,
  ///   programarSemana falla silenciosamente.
  Future<({bool notisActivas, bool exactasOk})> verificarPermisos({
    bool solicitarSiFaltan = true,
  }) async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    // No es Android (ej: iOS): init() ya pidió permisos.
    if (android == null) {
      return (notisActivas: true, exactasOk: true);
    }

    var notis = await android.areNotificationsEnabled() ?? false;
    var exactas = await android.canScheduleExactNotifications() ?? false;

    if (solicitarSiFaltan && !notis) {
      await android.requestNotificationsPermission();
      notis = await android.areNotificationsEnabled() ?? false;
    }
    if (solicitarSiFaltan && !exactas) {
      await android.requestExactAlarmsPermission();
      exactas = await android.canScheduleExactNotifications() ?? false;
    }

    return (notisActivas: notis, exactasOk: exactas);
  }

  /// Dispara una notificación inmediata. Verifica de una vez que el plugin
  /// esté inicializado, que el canal exista, que el ícono cargue y que haya
  /// permiso. Es la prueba más rápida de "¿funciona algo?".
  Future<void> mostrarPrueba() async {
    await _plugin.show(
      9999,
      '🔔 Notificación de prueba',
      'Si ves esto, el plugin y el canal funcionan correctamente',
      _detalles(),
    );
  }

  /// Programa una notificación a [segundos] en el futuro usando el mismo
  /// camino (zonedSchedule + alarmas exactas + timezone) que las
  /// notificaciones reales de clase. Si esta llega, el pipeline completo sirve.
  Future<void> programarPrueba({int segundos = 10}) async {
    final cuando = tz.TZDateTime.now(tz.local).add(Duration(seconds: segundos));
    await _plugin.zonedSchedule(
      9998,
      '⏰ Prueba programada',
      'Programada hace $segundos segundos (mismo camino que una clase)',
      cuando,
      _detalles(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Lista las notificaciones en cola (programadas y aún no disparadas).
  /// Sirve para confirmar qué agendó realmente programarSemana.
  Future<List<PendingNotificationRequest>> obtenerPendientes() {
    return _plugin.pendingNotificationRequests();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Detalles compartidos por todas las notificaciones (canal, ícono, etc.).
  NotificationDetails _detalles() => const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

  /// Retorna el lunes de la semana a la que pertenece [fecha].
  tz.TZDateTime _lunesDe(tz.TZDateTime fecha) {
    final diasDesdeElLunes = fecha.weekday - 1; // weekday: 1=lun, 7=dom
    return tz.TZDateTime(
      tz.local,
      fecha.year,
      fecha.month,
      fecha.day,
    ).subtract(Duration(days: diasDesdeElLunes));
  }

  /// Parsea "08:10 - 09:40" y retorna la hora de inicio.
  _HoraBloque? _parsearHorario(String? horario) {
    if (horario == null) return null;
    final partes = horario.split(' - ');
    if (partes.isEmpty) return null;
    final tiempoInicio = partes[0].trim().split(':');
    if (tiempoInicio.length < 2) return null;
    final hora = int.tryParse(tiempoInicio[0]);
    final minuto = int.tryParse(tiempoInicio[1]);
    if (hora == null || minuto == null) return null;
    return _HoraBloque(hora, minuto);
  }

  String _nombreCorto(String nombreCompleto) {
    final match = RegExp(r'^(.+?)\s*\(').firstMatch(nombreCompleto);
    return match?.group(1)?.trim() ?? nombreCompleto;
  }
}

class _HoraBloque {
  final int hora;
  final int minuto;
  const _HoraBloque(this.hora, this.minuto);
}