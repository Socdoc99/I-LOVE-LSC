import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/admin_screen.dart';
import '../../features/auth/application/auth_providers.dart';
import '../../features/auth/presentation/legal_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/collaborators/presentation/collaborator_form_screen.dart';
import '../../features/home/presentation/main_shell.dart';
import '../../features/learn/presentation/learn_screen.dart';
import '../../features/lessons/presentation/lesson_screen.dart';
import '../../features/lessons/presentation/review_screen.dart';
import '../../features/onboarding/application/onboarding_provider.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/progress/presentation/badge_screen.dart';
import '../../features/progress/presentation/progress_screen.dart';
import '../../features/survey/presentation/survey_screen.dart';
import '../widgets/state_views.dart';

/// Rutas que se pueden ver sin iniciar sesión.
const Set<String> _publicRoutes = {
  '/login',
  '/registro',
  '/terminos',
  '/politica-datos',
};

final routerProvider = Provider<GoRouter>((ref) {
  // Avisa al router cuando cambia la sesión o la bienvenida, para que
  // vuelva a evaluar las redirecciones.
  final refresh = ValueNotifier<int>(0);
  ref.onDispose(refresh.dispose);
  ref.listen(authStateProvider, (previous, next) => refresh.value++);
  ref.listen(onboardingSeenProvider, (previous, next) => refresh.value++);
  ref.listen(appUserProvider, (previous, next) => refresh.value++);

  final router = GoRouter(
    initialLocation: '/aprender',
    refreshListenable: refresh,
    redirect: (context, state) {
      final location = state.matchedLocation;
      final auth = ref.read(authStateProvider);

      if (auth.isLoading && !auth.hasValue) {
        return location == '/cargando' ? null : '/cargando';
      }

      final loggedIn = auth.valueOrNull != null;
      if (!loggedIn) {
        return _publicRoutes.contains(location) ? null : '/login';
      }

      final seenWelcome = ref.read(onboardingSeenProvider);
      if (!seenWelcome) {
        return location == '/bienvenida' ||
                location == '/terminos' ||
                location == '/politica-datos'
            ? null
            : '/bienvenida';
      }

      const authOnly = {'/login', '/registro', '/cargando', '/bienvenida'};
      if (authOnly.contains(location)) return '/aprender';

      if (location == '/admin') {
        final profile = ref.read(appUserProvider);
        if (profile.isLoading) return null;
        if (!ref.read(isAdminProvider)) return '/aprender';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/cargando',
        builder: (context, state) => const Scaffold(body: LoadingView()),
      ),
      GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
      GoRoute(path: '/registro', builder: (c, s) => const RegisterScreen()),
      GoRoute(path: '/terminos', builder: (c, s) => const LegalScreen.terms()),
      GoRoute(
        path: '/politica-datos',
        builder: (c, s) => const LegalScreen.dataPolicy(),
      ),
      GoRoute(
        path: '/bienvenida',
        builder: (c, s) => const OnboardingScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/aprender', builder: (c, s) => const LearnScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/progreso',
                builder: (c, s) => const ProgressScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/perfil', builder: (c, s) => const ProfileScreen()),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/leccion/:id',
        builder: (c, s) => LessonScreen(lessonId: s.pathParameters['id']!),
      ),
      GoRoute(path: '/repaso', builder: (c, s) => const ReviewScreen()),
      GoRoute(path: '/insignia', builder: (c, s) => const BadgeScreen()),
      GoRoute(path: '/encuesta', builder: (c, s) => const SurveyScreen()),
      GoRoute(
        path: '/colaborar',
        builder: (c, s) => const CollaboratorFormScreen(),
      ),
      GoRoute(path: '/admin', builder: (c, s) => const AdminScreen()),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(),
      body: const EmptyView(
        icon: Icons.search_off,
        message: 'No encontramos esta pantalla.',
      ),
    ),
  );
  ref.onDispose(router.dispose);
  return router;
});
