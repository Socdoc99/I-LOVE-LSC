import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/exercise.dart';
import 'option_button.dart';
import 'sign_video_player.dart';

/// «Palabra a seña»: se lee una palabra y se elige el video correcto.
///
/// Para no abrir varios videos a la vez, se muestran las opciones como
/// «Seña 1…4»: al tocar una se reproduce su video y luego se confirma.
class WordToSignView extends StatefulWidget {
  const WordToSignView({
    super.key,
    required this.exercise,
    required this.onAnswer,
    required this.onDone,
  });

  final WordToSignExercise exercise;
  final void Function(bool correct, String signId) onAnswer;
  final VoidCallback onDone;

  @override
  State<WordToSignView> createState() => _WordToSignViewState();
}

class _WordToSignViewState extends State<WordToSignView> {
  int _previewIndex = 0;
  int? _confirmedIndex;

  bool get _answered => _confirmedIndex != null;

  bool _isCorrect(int index) =>
      widget.exercise.options[index].id == widget.exercise.target.id;

  void _confirm() {
    if (_answered) return;
    final correct = _isCorrect(_previewIndex);
    setState(() => _confirmedIndex = _previewIndex);
    widget.onAnswer(correct, widget.exercise.target.id);
    widget.onDone();
  }

  OptionState _stateOf(int index) {
    if (_answered) {
      if (_isCorrect(index)) return OptionState.correct;
      if (index == _confirmedIndex) return OptionState.wrong;
      return OptionState.idle;
    }
    return index == _previewIndex ? OptionState.selected : OptionState.idle;
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.exercise.options;
    final previewSign = options[_previewIndex];
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('¿Cuál es la seña de…?', style: textTheme.titleMedium),
        const SizedBox(height: 4),
        Semantics(
          header: true,
          child: Text(
            widget.exercise.target.word,
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SignVideoPlayer(
          key: ValueKey('word-$_previewIndex-${previewSign.id}'),
          sign: previewSign,
          showWordWhenUnavailable: false,
        ),
        const SizedBox(height: 12),
        Text(
          'Toca cada opción para ver su seña y luego confirma tu respuesta.',
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < options.length; i++) ...[
          OptionButton(
            label: 'Seña ${i + 1}',
            state: _stateOf(i),
            onPressed: _answered ? null : () => setState(() => _previewIndex = i),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 4),
        FilledButton(
          onPressed: _answered ? null : _confirm,
          child: Text('Confirmar seña ${_previewIndex + 1}'),
        ),
      ],
    );
  }
}
