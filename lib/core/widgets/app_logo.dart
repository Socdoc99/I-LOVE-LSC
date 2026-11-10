import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

/// Logo de I Love LSC (con una alternativa si la imagen no se encuentra).
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.height = 96});

  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.asset(
        'assets/images/logo.png',
        height: height,
        fit: BoxFit.contain,
        semanticLabel: '${AppConstants.appName}, un idioma universal',
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.back_hand_outlined,
          size: height,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
