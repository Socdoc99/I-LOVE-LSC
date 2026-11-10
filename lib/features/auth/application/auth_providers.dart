import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/auth_repository.dart';
import '../domain/app_user.dart';
import '../domain/auth_user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    auth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
    storage: ref.watch(firebaseStorageProvider),
  );
});

/// Sesión actual: `null` si no hay sesión iniciada.
final authStateProvider = StreamProvider<AuthUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

/// Perfil de la persona con sesión iniciada.
final appUserProvider = StreamProvider<AppUser?>((ref) {
  final authUser = ref.watch(authStateProvider).valueOrNull;
  if (authUser == null) return Stream<AppUser?>.value(null);
  return ref.watch(authRepositoryProvider).watchAppUser(authUser);
});

final isAdminProvider = Provider<bool>((ref) {
  return ref.watch(appUserProvider).valueOrNull?.role == UserRole.admin;
});
