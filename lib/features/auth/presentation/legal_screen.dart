import 'package:flutter/material.dart';

import '../../../core/legal/legal_texts.dart';
import '../../../core/theme/app_theme.dart';

/// Muestra los términos de uso o la política de tratamiento de datos.
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.title, required this.sections});

  const LegalScreen.terms({super.key})
      : title = 'Términos de uso',
        sections = LegalTexts.terms;

  const LegalScreen.dataPolicy({super.key})
      : title = 'Política de tratamiento de datos',
        sections = LegalTexts.dataPolicy;

  final String title;
  final List<LegalSection> sections;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.mist,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.navy),
                SizedBox(width: 8),
                Expanded(child: Text(LegalTexts.draftNotice)),
              ],
            ),
          ),
          for (final section in sections) ...[
            const SizedBox(height: 20),
            Semantics(
              header: true,
              child: Text(
                section.title,
                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 6),
            Text(section.body, style: textTheme.bodyLarge),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
