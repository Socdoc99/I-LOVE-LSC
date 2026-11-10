import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../application/progress_providers.dart';

/// Barra con racha, XP y vidas. Cada dato lleva texto y ícono (no depende
/// solo del color) y una etiqueta para lectores de pantalla.
class StatsBar extends ConsumerWidget {
  const StatsBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(progressSummaryProvider);
    final streak = summary?.streak ?? 0;
    final xp = summary?.xp ?? 0;
    final lives = summary?.lives ?? GamificationConfig.maxLives;
    final minutes = summary?.minutesToNextLife;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatChip(
                icon: Icons.local_fire_department,
                value: '$streak',
                semanticLabel:
                    'Racha: $streak ${streak == 1 ? 'día' : 'días'} seguidos',
                color: const Color(0xFF9A3412),
              ),
              _StatChip(
                icon: Icons.bolt,
                value: '$xp XP',
                semanticLabel: 'Puntos de experiencia: $xp',
                color: AppColors.navy,
              ),
              _StatChip(
                icon: Icons.favorite,
                value: '$lives/${GamificationConfig.maxLives}',
                semanticLabel:
                    'Vidas: $lives de ${GamificationConfig.maxLives}',
                color: AppColors.danger,
              ),
            ],
          ),
          if (minutes != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Próxima vida en $minutes min',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.value,
    required this.semanticLabel,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String semanticLabel;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.mist, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 6),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
