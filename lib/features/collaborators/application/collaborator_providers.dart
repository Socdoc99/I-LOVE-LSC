import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/collaborator_repository.dart';

final collaboratorRepositoryProvider = Provider<CollaboratorRepository>(
  (ref) => CollaboratorRepository(ref.watch(firestoreProvider)),
);

/// Solicitudes de colaboradores (solo administradores).
final collaboratorApplicationsProvider =
    StreamProvider.autoDispose<List<CollaboratorApplication>>((ref) {
  return ref.watch(collaboratorRepositoryProvider).watchAll();
});
