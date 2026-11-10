import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../domain/course_catalog.dart';
import '../domain/learning_unit.dart';
import '../domain/lesson.dart';
import '../domain/sign.dart';
import 'seed_content.dart';

/// Lee el contenido del curso desde Firestore y los videos desde Cloud
/// Storage. La lógica de la app no depende de Firebase: solo de esta clase.
class ContentRepository {
  ContentRepository({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  })  : _firestore = firestore,
        _storage = storage;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  /// Unidades, señas y **solo las lecciones publicadas**.
  Future<CourseCatalog> fetchCatalog() async {
    final results = await Future.wait([
      _firestore.collection('units').get(),
      _firestore
          .collection('lessons')
          .where('published', isEqualTo: true)
          .get(),
      _firestore.collection('signs').get(),
    ]);
    return CourseCatalog(
      units: results[0].docs.map(_unitFromDoc).toList(),
      lessons: results[1].docs.map(lessonFromDoc).toList(),
      signs: results[2].docs.map(_signFromDoc).toList(),
    );
  }

  /// URL de descarga de un video (por ejemplo `videos/saludos/hola.mp4`).
  /// Si la ruta ya es una dirección `http(s)`, se usa tal cual.
  Future<String> videoUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Future<String>.value(path);
    }
    return _storage.ref(path).getDownloadURL();
  }

  // --------------------------------------------------- Administración

  /// Todas las lecciones, publicadas o no (solo para administradores).
  Future<List<Lesson>> fetchAllLessons() async {
    final snapshot = await _firestore.collection('lessons').get();
    final lessons = snapshot.docs.map(lessonFromDoc).toList()
      ..sort((a, b) {
        final byUnit = a.unitId.compareTo(b.unitId);
        return byUnit != 0 ? byUnit : a.order.compareTo(b.order);
      });
    return lessons;
  }

  Future<List<LearningUnit>> fetchAllUnits() async {
    final snapshot = await _firestore.collection('units').get();
    return snapshot.docs.map(_unitFromDoc).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  /// Marca una lección como validada y/o publicada. Una lección no puede
  /// publicarse sin estar validada (también lo exigen las reglas de Firestore).
  Future<void> setLessonState({
    required String lessonId,
    required bool validated,
    required bool published,
    required String adminUid,
  }) {
    final isPublished = validated && published;
    return _firestore.collection('lessons').doc(lessonId).update({
      'validated': validated,
      'published': isPublished,
      'reviewedBy': adminUid,
      'reviewedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Carga el contenido de ejemplo (`SeedContent`). Si ya existía, lo
  /// sobrescribe.
  ///
  /// * [testMode] = `false`: las lecciones quedan como borrador (sin validar
  ///   ni publicar) y los videos apuntan a Cloud Storage.
  /// * [testMode] = `true`: SOLO para pruebas en desarrollo. Marca las
  ///   lecciones como validadas y publicadas y usa un video de muestra.
  Future<void> seedSampleContent({required bool testMode}) async {
    final batch = _firestore.batch();

    for (final unit in SeedContent.units) {
      batch.set(_firestore.collection('units').doc(unit.id), {
        'title': unit.title,
        'order': unit.order,
        'description': unit.description,
        'iconKey': unit.iconKey,
        'culturalNote': unit.culturalNote,
      });
    }
    for (final sign in SeedContent.signs) {
      batch.set(_firestore.collection('signs').doc(sign.id), {
        'word': sign.word,
        'unitId': sign.unitId,
        'videoPath': testMode ? SeedContent.testVideoUrl : sign.videoPath,
        'context': sign.context,
      });
    }
    for (final lesson in SeedContent.lessons) {
      batch.set(_firestore.collection('lessons').doc(lesson.id), {
        'unitId': lesson.unitId,
        'title': lesson.title,
        'order': lesson.order,
        'signIds': lesson.signIds,
        'validated': testMode,
        'published': testMode,
      });
    }
    await batch.commit();
  }
}

LearningUnit _unitFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
  final data = doc.data();
  return LearningUnit(
    id: doc.id,
    title: (data['title'] as String?) ?? doc.id,
    order: (data['order'] as num?)?.toInt() ?? 0,
    description: (data['description'] as String?) ?? '',
    iconKey: (data['iconKey'] as String?) ?? '',
    culturalNote: (data['culturalNote'] as String?) ?? '',
  );
}

Lesson lessonFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
  final data = doc.data();
  return Lesson(
    id: doc.id,
    unitId: (data['unitId'] as String?) ?? '',
    title: (data['title'] as String?) ?? doc.id,
    order: (data['order'] as num?)?.toInt() ?? 0,
    signIds: List<String>.from((data['signIds'] as List?) ?? const []),
    published: (data['published'] as bool?) ?? false,
    validated: (data['validated'] as bool?) ?? false,
  );
}

Sign _signFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
  final data = doc.data();
  return Sign(
    id: doc.id,
    word: (data['word'] as String?) ?? doc.id,
    unitId: (data['unitId'] as String?) ?? '',
    videoPath: (data['videoPath'] as String?) ?? '',
    context: (data['context'] as String?) ?? '',
  );
}
