import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_logo.dart';
import '../application/onboarding_provider.dart';

class _Page {
  const _Page(this.icon, this.title, this.text);

  final IconData icon;
  final String title;
  final String text;
}

const List<_Page> _pages = [
  _Page(
    Icons.waving_hand_outlined,
    '¡Bienvenido a I Love LSC!',
    'Aprende Lengua de Señas Colombiana con videos en LSC y conoce la '
        'cultura de la comunidad sorda. La LSC es una lengua y parte de la '
        'identidad de las personas sordas.',
  ),
  _Page(
    Icons.map_outlined,
    'Un recorrido por unidades',
    'Tu aprendizaje está organizado en tres unidades temáticas. Cada lección '
        'se desbloquea cuando completas la anterior.',
  ),
  _Page(
    Icons.extension_outlined,
    'Practica de tres formas',
    '«Ver y elegir»: observas una seña y eliges su significado.\n'
        '«Palabra a seña»: lees una palabra y eliges el video correcto.\n'
        '«Parejas»: unes videos con palabras.',
  ),
  _Page(
    Icons.local_fire_department_outlined,
    'Gana XP y mantén tu racha',
    'Cada acierto suma puntos de experiencia (XP) y practicar cada día '
        'mantiene tu racha. Tienes 5 vidas: si te equivocas pierdes una, y '
        'esas señas pasan a tu repaso. Al terminar el recorrido recibes una '
        'constancia digital.',
  ),
];

/// Introducción breve que se ve una sola vez después del registro.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  bool get _isLast => _index == _pages.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() {
    ref.read(onboardingSeenProvider.notifier).markSeen();
  }

  void _next() {
    if (_isLast) {
      _finish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finish,
                child: const Text('Omitir'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (value) => setState(() => _index = value),
                itemBuilder: (context, i) {
                  final page = _pages[i];
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        if (i == 0) ...[
                          const AppLogo(height: 90),
                          const SizedBox(height: 16),
                        ],
                        Icon(page.icon, size: 96, color: AppColors.navy),
                        const SizedBox(height: 24),
                        Semantics(
                          header: true,
                          child: Text(
                            page.title,
                            textAlign: TextAlign.center,
                            style: textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          page.text,
                          textAlign: TextAlign.center,
                          style: textTheme.bodyLarge?.copyWith(height: 1.4),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Semantics(
              label: 'Página ${_index + 1} de ${_pages.length}',
              excludeSemantics: true,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _pages.length; i++)
                    Container(
                      width: i == _index ? 24 : 10,
                      height: 10,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: i == _index ? AppColors.navy : AppColors.mist,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: FilledButton(
                onPressed: _next,
                child: Text(_isLast ? 'Comenzar' : 'Siguiente'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
