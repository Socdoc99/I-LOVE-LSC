import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class LoveLscApp extends ConsumerStatefulWidget {
  const LoveLscApp({super.key});

  @override
  ConsumerState<LoveLscApp> createState() => _LoveLscAppState();
}

class _LoveLscAppState extends ConsumerState<LoveLscApp> {
  StreamSubscription<RemoteMessage>? _messages;

  @override
  void initState() {
    super.initState();
    // Con la app abierta, FCM no muestra la notificación del sistema:
    // se muestra como aviso dentro de la app.
    _messages = FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;
      final text = notification.body ?? notification.title ?? '';
      if (text.isEmpty) return;
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(text)),
      );
    });
  }

  @override
  void dispose() {
    _messages?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
      scaffoldMessengerKey: scaffoldMessengerKey,
      locale: const Locale('es'),
      supportedLocales: const [Locale('es'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    );
  }
}
