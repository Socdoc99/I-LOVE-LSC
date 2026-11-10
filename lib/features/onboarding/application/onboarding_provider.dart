import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';

/// Recuerda si la persona ya vio la bienvenida en este dispositivo.
class OnboardingController extends Notifier<bool> {
  static const String _key = 'bienvenida_vista';

  @override
  bool build() => ref.watch(sharedPreferencesProvider).getBool(_key) ?? false;

  Future<void> markSeen() async {
    await ref.read(sharedPreferencesProvider).setBool(_key, true);
    state = true;
  }
}

final onboardingSeenProvider =
    NotifierProvider<OnboardingController, bool>(OnboardingController.new);
