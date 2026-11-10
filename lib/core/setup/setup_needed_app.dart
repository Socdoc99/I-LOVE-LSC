import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';

/// Pantalla que se muestra si Firebase no está configurado. Así, al abrir el
/// proyecto por primera vez, se ve la app en el emulador y se sabe qué hacer.
class SetupNeededApp extends StatelessWidget {
  const SetupNeededApp({super.key, required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Center(child: AppLogo(height: 110)),
              const SizedBox(height: 20),
              Text(
                'Falta conectar Firebase',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 12),
              const Text(
                'La app se instaló bien, pero todavía no está enlazada a tu '
                'proyecto de Firebase. Hazlo así:\n\n'
                '1. Crea un proyecto en console.firebase.google.com.\n'
                '2. Activa Authentication (correo y contraseña), Firestore y '
                'Storage.\n'
                '3. En la carpeta del proyecto ejecuta:  flutterfire configure\n'
                '4. Detén la app y vuelve a ejecutarla.\n\n'
                'Los pasos detallados están en el archivo README.md.',
                style: TextStyle(fontSize: 16, height: 1.4),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.mist,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SelectableText(
                  'Detalle técnico: $error',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
