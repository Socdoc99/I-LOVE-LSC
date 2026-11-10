import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/state_views.dart';
import '../../auth/application/auth_providers.dart';
import '../application/progress_providers.dart';

/// Constancia o insignia digital al completar el recorrido. NO es un
/// certificado académico ni de aptitud ocupacional.
class BadgeScreen extends ConsumerWidget {
  const BadgeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(progressSummaryProvider);
    final user = ref.watch(appUserProvider).valueOrNull;
    final completedAt = summary?.progress.completedAt;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Mi insignia')),
      body: summary == null
          ? const LoadingView()
          : completedAt == null
              ? const EmptyView(
                  icon: Icons.workspace_premium_outlined,
                  message: 'Tu insignia aparece cuando completas todas las '
                      'lecciones del recorrido.',
                )
              : ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Semantics(
                      container: true,
                      label: 'Constancia digital de ${user?.displayName ?? 'la persona aprendiz'}, '
                          'emitida el ${formatLongDate(completedAt)}',
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.gold, width: 4),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.workspace_premium,
                              size: 96,
                              color: AppColors.gold,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Constancia digital',
                              style: textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.navy,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text('Se otorga a'),
                            const SizedBox(height: 4),
                            Text(
                              user?.displayName ?? 'Aprendiz',
                              textAlign: TextAlign.center,
                              style: textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'por completar el recorrido de aprendizaje de '
                              'Lengua de Señas Colombiana (LSC) en '
                              '${AppConstants.appName}.',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              formatLongDate(completedAt),
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            Text('${summary.xp} XP acumulados'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Esta constancia o insignia es un reconocimiento de '
                      'participación. No es un certificado de aptitud '
                      'ocupacional ni un título académico '
                      '(Decreto 1075 de 2015, art. 2.6.6.8).',
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
    );
  }
}
