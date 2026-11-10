import 'package:flutter/material.dart';

import '../../domain/exercise.dart';
import 'option_button.dart';
import 'sign_video_player.dart';

/// «Parejas»: se emparejan videos con palabras.
///
/// Se elige una seña (se reproduce su video) y luego la palabra que le
/// corresponde. Cada error se reporta con `onAnswer(false, …)`.
class PairsView extends StatefulWidget {
  const PairsView({
    super.key,
    required this.exercise,
    required this.onAnswer,
    required this.onDone,
  });

  final PairsExercise exercise;
  final void Function(bool correct, String signId) onAnswer;
  final VoidCallback onDone;

  @override
  State<PairsView> createState() => _PairsViewState();
}

class _PairsViewState extends State<PairsView> {
  final Set<String> _matchedSignIds = <String>{};
  int _selectedIndex = 0;
  String? _wrongWord;

  List<int> get _unmatchedIndexes => [
        for (var i = 0; i < widget.exercise.signs.length; i++)
          if (!_matchedSignIds.contains(widget.exercise.signs[i].id)) i,
      ];

  void _chooseWord(String word) {
    final sign = widget.exercise.signs[_selectedIndex];
    if (_matchedSignIds.contains(sign.id)) return;

    if (sign.word == word) {
      setState(() {
        _matchedSignIds.add(sign.id);
        _wrongWord = null;
        final remaining = _unmatchedIndexes;
        if (remaining.isNotEmpty) _selectedIndex = remaining.first;
      });
      widget.onAnswer(true, sign.id);
      if (_matchedSignIds.length == widget.exercise.signs.length) {
        widget.onDone();
      }
    } else {
      setState(() => _wrongWord = word);
      widget.onAnswer(false, sign.id);
    }
  }

  bool _isWordMatched(String word) {
    for (final sign in widget.exercise.signs) {
      if (sign.word == word && _matchedSignIds.contains(sign.id)) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final signs = widget.exercise.signs;
    final selected = signs[_selectedIndex];
    final finished = _matchedSignIds.length == signs.length;
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Semantics(
          header: true,
          child: Text('Une cada seña con su palabra', style: textTheme.titleLarge),
        ),
        const SizedBox(height: 12),
        SignVideoPlayer(
          key: ValueKey('pair-${selected.id}'),
          sign: selected,
          showWordWhenUnavailable: false,
        ),
        const SizedBox(height: 12),
        Text('Señas', style: textTheme.titleSmall),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < signs.length; i++)
              ChoiceChip(
                label: Text('Seña ${i + 1}'),
                avatar: _matchedSignIds.contains(signs[i].id)
                    ? const Icon(Icons.check_circle, size: 18)
                    : null,
                selected: i == _selectedIndex,
                onSelected: _matchedSignIds.contains(signs[i].id)
                    ? null
                    : (_) => setState(() {
                          _selectedIndex = i;
                          _wrongWord = null;
                        }),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          finished
              ? '¡Todas las parejas están completas!'
              : 'Elige la palabra de la Seña ${_selectedIndex + 1}',
          style: textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        for (final word in widget.exercise.words) ...[
          OptionButton(
            label: word,
            state: _isWordMatched(word)
                ? OptionState.correct
                : (word == _wrongWord ? OptionState.wrong : OptionState.idle),
            onPressed:
                (finished || _isWordMatched(word)) ? null : () => _chooseWord(word),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
