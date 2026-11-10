import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/content_repository.dart';
import '../domain/course_catalog.dart';
import '../domain/learning_unit.dart';
import '../domain/lesson.dart';

final contentRepositoryProvider = Provider<ContentRepository>((ref) {
  return ContentRepository(
    firestore: ref.watch(firestoreProvider),
    storage: ref.watch(firebaseStorageProvider),
  );
});

/// Unidades, señas y lecciones publicadas. Se recarga con
/// `ref.invalidate(catalogProvider)`.
final catalogProvider = FutureProvider<CourseCatalog>((ref) {
  return ref.watch(contentRepositoryProvider).fetchCatalog();
});

/// URL de descarga de un video, por su ruta en Cloud Storage. Se guarda en
/// caché mientras la app está abierta.
final signVideoUrlProvider = FutureProvider.family<String, String>((ref, path) {
  return ref.watch(contentRepositoryProvider).videoUrl(path);
});

/// Todas las lecciones (solo pantalla de administración).
final adminLessonsProvider = FutureProvider.autoDispose<List<Lesson>>((ref) {
  return ref.watch(contentRepositoryProvider).fetchAllLessons();
});

final adminUnitsProvider = FutureProvider.autoDispose<List<LearningUnit>>((ref) {
  return ref.watch(contentRepositoryProvider).fetchAllUnits();
});
