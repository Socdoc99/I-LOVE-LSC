import 'package:flutter/material.dart';

/// Ícono de una unidad según su `iconKey` en Firestore.
IconData unitIconFor(String key) {
  switch (key) {
    case 'saludos':
      return Icons.waving_hand_outlined;
    case 'familia':
      return Icons.family_restroom;
    case 'cotidiano':
      return Icons.home_outlined;
    default:
      return Icons.back_hand_outlined;
  }
}
