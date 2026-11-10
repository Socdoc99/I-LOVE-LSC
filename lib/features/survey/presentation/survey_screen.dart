import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../analytics/analytics_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../application/survey_providers.dart';
import '../data/survey_repository.dart';

/// Encuesta de experiencia del piloto (Sprint 5).
class SurveyScreen extends ConsumerStatefulWidget {
  const SurveyScreen({super.key});

  @override
  ConsumerState<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends ConsumerState<SurveyScreen> {
  final _comment = TextEditingController();
  int _ease = 0;
  int _clarity = 0;
  int _usefulness = 0;
  String? _recommend;
  bool _sending = false;
  bool _showMissing = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  bool get _complete =>
      _ease > 0 && _clarity > 0 && _usefulness > 0 && _recommend != null;

  Future<void> _submit() async {
    if (!_complete) {
      setState(() => _showMissing = true);
      return;
    }
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;
    setState(() => _sending = true);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      await ref.read(surveyRepositoryProvider).submit(
            uid: uid,
            response: SurveyResponse(
              ease: _ease,
              videoClarity: _clarity,
              usefulness: _usefulness,
              wouldRecommend: _recommend!,
              comment: _comment.text,
            ),
          );
      ref.read(analyticsProvider).surveySubmitted();
      messenger.showSnackBar(const SnackBar(content: Text('¡Gracias por tu opinión!')));
      router.pop();
    } catch (_) {
      if (mounted) setState(() => _sending = false);
      messenger.showSnackBar(
        const SnackBar(content: Text('No pudimos enviar la encuesta. Inténtalo de nuevo.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Encuesta de experiencia')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Tu opinión nos ayuda a mejorar I Love LSC. Son 4 preguntas y un '
            'comentario opcional.',
          ),
          const SizedBox(height: 20),
          _RatingQuestion(
            question: '¿Qué tan fácil fue usar la app?',
            lowLabel: '1 = Nada fácil',
            highLabel: '5 = Muy fácil',
            value: _ease,
            onChanged: (v) => setState(() => _ease = v),
          ),
          _RatingQuestion(
            question: '¿Qué tan claros fueron los videos de las señas?',
            lowLabel: '1 = Nada claros',
            highLabel: '5 = Muy claros',
            value: _clarity,
            onChanged: (v) => setState(() => _clarity = v),
          ),
          _RatingQuestion(
            question: '¿Qué tan útil te pareció para aprender LSC?',
            lowLabel: '1 = Nada útil',
            highLabel: '5 = Muy útil',
            value: _usefulness,
            onChanged: (v) => setState(() => _usefulness = v),
          ),
          Semantics(
            header: true,
            child: Text(
              '¿Recomendarías la app a otras personas?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            emptySelectionAllowed: true,
            segments: const [
              ButtonSegment(value: 'si', label: Text('Sí')),
              ButtonSegment(value: 'tal_vez', label: Text('Tal vez')),
              ButtonSegment(value: 'no', label: Text('No')),
            ],
            selected: _recommend == null ? <String>{} : {_recommend!},
            onSelectionChanged: (selection) => setState(
              () => _recommend = selection.isEmpty ? null : selection.first,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _comment,
            maxLines: 4,
            maxLength: 500,
            decoration: const InputDecoration(
              labelText: 'Comentarios (opcional)',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          if (_showMissing && !_complete)
            Semantics(
              liveRegion: true,
              child: Text(
                'Responde las cuatro preguntas para enviar.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _sending ? null : _submit,
            child: _sending
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  )
                : const Text('Enviar'),
          ),
        ],
      ),
    );
  }
}

class _RatingQuestion extends StatelessWidget {
  const _RatingQuestion({
    required this.question,
    required this.lowLabel,
    required this.highLabel,
    required this.value,
    required this.onChanged,
  });

  final String question;
  final String lowLabel;
  final String highLabel;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(question, style: Theme.of(context).textTheme.titleMedium),
          ),
          const SizedBox(height: 4),
          Text('$lowLabel · $highLabel', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (var i = 1; i <= 5; i++)
                ChoiceChip(
                  label: Text('$i'),
                  selected: value == i,
                  onSelected: (_) => onChanged(i),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
