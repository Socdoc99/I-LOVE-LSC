import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../auth/application/auth_providers.dart';
import 'notification_service.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(
    messaging: FirebaseMessaging.instance,
    firestore: ref.watch(firestoreProvider),
    preferences: ref.watch(sharedPreferencesProvider),
  );
});

/// Estado del interruptor de recordatorios de práctica.
class RemindersController extends Notifier<bool> {
  @override
  bool build() => ref.watch(notificationServiceProvider).isEnabled;

  /// Activa o desactiva los recordatorios. Devuelve `false` si la persona
  /// rechazó el permiso de notificaciones.
  Future<bool> setEnabled(bool enabled) async {
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return false;
    final service = ref.read(notificationServiceProvider);
    if (enabled) {
      final granted = await service.enable(uid);
      state = granted;
      return granted;
    }
    await service.disable(uid);
    state = false;
    return true;
  }
}

final remindersProvider =
    NotifierProvider<RemindersController, bool>(RemindersController.new);
