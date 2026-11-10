import 'package:cloud_firestore/cloud_firestore.dart';

/// Respuesta a la encuesta de experiencia del piloto.
class SurveyResponse {
  const SurveyResponse({
    required this.ease,
    required this.videoClarity,
    required this.usefulness,
    required this.wouldRecommend,
    this.comment = '',
  });

  /// Calificaciones de 1 (muy mal) a 5 (muy bien).
  final int ease;
  final int videoClarity;
  final int usefulness;

  /// `si`, `tal_vez` o `no`.
  final String wouldRecommend;
  final String comment;
}

class SurveyRepository {
  SurveyRepository(this._firestore);

  final FirebaseFirestore _firestore;

  Future<void> submit({required String uid, required SurveyResponse response}) {
    return _firestore.collection('encuestas').add({
      'uid': uid,
      'facilidad': response.ease,
      'claridadVideos': response.videoClarity,
      'utilidad': response.usefulness,
      'recomendaria': response.wouldRecommend,
      'comentario': response.comment.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
