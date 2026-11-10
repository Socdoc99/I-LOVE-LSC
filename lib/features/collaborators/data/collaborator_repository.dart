import 'package:cloud_firestore/cloud_firestore.dart';

/// Roles que puede solicitar una persona sorda colaboradora.
enum CollaboratorRole {
  signModel('Modelo de señas'),
  linguisticValidator('Validador lingüístico'),
  culturalGuide('Orientador cultural');

  const CollaboratorRole(this.label);

  final String label;
}

/// Solicitud para ser colaborador sordo o validador de contenido. El equipo
/// la verifica manualmente; los documentos firmados (acuerdo de colaboración
/// y autorización de uso de imagen) se gestionan por fuera de la app.
class CollaboratorApplication {
  const CollaboratorApplication({
    required this.id,
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    required this.experience,
    required this.status,
    this.createdAt,
  });

  final String id;
  final String uid;
  final String fullName;
  final String email;
  final String phone;
  final String role;
  final String experience;

  /// `pendiente`, `aprobada` o `rechazada`.
  final String status;
  final DateTime? createdAt;
}

class CollaboratorRepository {
  CollaboratorRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('solicitudesColaborador');

  Future<void> submit({
    required String uid,
    required String fullName,
    required String email,
    required String phone,
    required CollaboratorRole role,
    required String experience,
  }) {
    return _collection.add({
      'uid': uid,
      'nombreCompleto': fullName.trim(),
      'correo': email.trim(),
      'telefono': phone.trim(),
      'rol': role.label,
      'experiencia': experience.trim(),
      'consentimientoImagen': true,
      'autorizacionDatos': true,
      'status': 'pendiente',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Solicitudes en tiempo real (solo administradores).
  Stream<List<CollaboratorApplication>> watchAll() {
    return _collection.orderBy('createdAt', descending: true).snapshots().map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return CollaboratorApplication(
              id: doc.id,
              uid: (data['uid'] as String?) ?? '',
              fullName: (data['nombreCompleto'] as String?) ?? '',
              email: (data['correo'] as String?) ?? '',
              phone: (data['telefono'] as String?) ?? '',
              role: (data['rol'] as String?) ?? '',
              experience: (data['experiencia'] as String?) ?? '',
              status: (data['status'] as String?) ?? 'pendiente',
              createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
            );
          }).toList(),
        );
  }

  Future<void> setStatus(String id, String status) =>
      _collection.doc(id).update({'status': status});
}
