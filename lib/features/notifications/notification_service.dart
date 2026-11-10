import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';

/// Recordatorios de práctica con Firebase Cloud Messaging.
///
/// La app pide permiso y suscribe el dispositivo al tema
/// [AppConstants.reminderTopic]; los mensajes se envían desde la consola de
/// Firebase (campañas de notificaciones) o desde una Cloud Function.
class NotificationService {
  NotificationService({
    required FirebaseMessaging messaging,
    required FirebaseFirestore firestore,
    required SharedPreferences preferences,
  })  : _messaging = messaging,
        _firestore = firestore,
        _preferences = preferences;

  static const String _enabledKey = 'recordatorios_activados';

  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;
  final SharedPreferences _preferences;

  bool get isEnabled => _preferences.getBool(_enabledKey) ?? false;

  /// Pide el permiso del sistema y activa los recordatorios.
  /// Devuelve `false` si la persona no concedió el permiso.
  Future<bool> enable(String uid) async {
    final settings = await _messaging.requestPermission();
    final granted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;
    if (!granted) return false;

    await _messaging.subscribeToTopic(AppConstants.reminderTopic);
    try {
      final token = await _messaging.getToken();
      await _firestore.collection('users').doc(uid).update({
        'notificationsEnabled': true,
        if (token != null) 'fcmToken': token,
      });
    } catch (e) {
      debugPrint('No se pudo guardar el token de notificaciones: $e');
    }
    await _preferences.setBool(_enabledKey, true);
    return true;
  }

  Future<void> disable(String uid) async {
    await _messaging.unsubscribeFromTopic(AppConstants.reminderTopic);
    try {
      await _firestore.collection('users').doc(uid).update({
        'notificationsEnabled': false,
        'fcmToken': FieldValue.delete(),
      });
    } catch (e) {
      debugPrint('No se pudo actualizar el perfil: $e');
    }
    await _preferences.setBool(_enabledKey, false);
  }
}
