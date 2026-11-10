import 'package:flutter/material.dart';

import '../../../content/domain/sign.dart';
import 'sign_video_player.dart';

/// Presentación de una seña nueva: video, palabra y situación de uso.
class IntroView extends StatelessWidget {
  const IntroView({super.key, required this.sign});

  final Sign sign;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Seña nueva', style: textTheme.titleMedium),
        const SizedBox(height: 12),
        SignVideoPlayer(key: ValueKey('intro-${sign.id}'), sign: sign),
        const SizedBox(height: 20),
        Semantics(
          header: true,
          child: Text(
            sign.word,
            textAlign: TextAlign.center,
            style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        if (sign.context.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            sign.context,
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge,
          ),
        ],
      ],
    );
  }
}
