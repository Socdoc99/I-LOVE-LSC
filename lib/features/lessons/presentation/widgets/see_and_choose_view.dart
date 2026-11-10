import 'package:flutter/material.dart';

import '../../domain/exercise.dart';
import 'option_button.dart';
import 'sign_video_player.dart';

/// «Ver y elegir»: se observa la seña y se elige su significado.
class SeeAndChooseView extends StatefulWidget {
  const SeeAndChooseView({
    super.key,
    required this.exercise,
    required this.onAnswer,
    required this.onDone,
  });

  final SeeAndChooseExercise exercise;

  /// Se llama con cada respuesta: si fue correcta y el id de la seña.
  final void Function(bool correct, String signId) onAnswer;

  /// Se llama cuando el ejercicio termina y se puede continuar.
  final VoidCallback onDone;

  @override
  State<SeeAndChooseView> createState() => _SeeAndChooseViewState();
}

class _SeeAndChooseViewState extends State<SeeAndChooseView> {
  String? _selected;

  bool get _answered => _selected != null;

  void _choose(String option) {
    if (_answered) return;
    final correct = option == widget.exercise.sign.word;
    setState(() => _selected = option);
    widget.onAnswer(correct, widget.exercise.sign.id);
    widget.onDone();
  }

  OptionState _stateOf(String option) {
    if (!_answered) return OptionState.idle;
    final isCorrect = option == widget.exercise.sign.word;
    if (isCorrect) return OptionState.correct;
    if (option == _selected) return OptionState.wrong;
    return OptionState.idle;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Semantics(
          header: true,
          child: Text(
            '¿Qué significa esta seña?',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: 12),
        SignVideoPlayer(
          key: ValueKey('see-${widget.exercise.sign.id}'),
          sign: widget.exercise.sign,
          showWordWhenUnavailable: false,
        ),
        const SizedBox(height: 16),
        for (final option in widget.exercise.options) ...[
          OptionButton(
            label: option,
            state: _stateOf(option),
            onPressed: _answered ? null : () => _choose(option),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}
