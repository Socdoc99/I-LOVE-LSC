import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/app_constants.dart';
import '../domain/app_user.dart';
import '../domain/auth_user.dart';

/// Error de autenticación o de cuenta con un mensaje listo para mostrar.
class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Cuentas (Firebase Authentication), perfiles (Cloud Firestore) y fotos
/// (Cloud Storage).
class AuthRepository {
  AuthRepository({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  })  : _auth = auth,
        _firestore = firestore,
        _storage = storage;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  Stream<AuthUser?> authStateChanges() {
    return _auth.authStateChanges().map((user) {
      if (user == null) return null;
      return AuthUser(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? '',
      );
    });
  }

  /// Perfil en tiempo real. Si el documento aún no existe se arma uno básico
  /// con los datos de la cuenta.
  Stream<AppUser> watchAppUser(AuthUser authUser) {
    return _users.doc(authUser.uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      final fallbackName =
          authUser.displayName.isEmpty ? 'Aprendiz' : authUser.displayName;
      if (data == null) {
        return AppUser(
          uid: authUser.uid,
          displayName: fallbackName,
          email: authUser.email,
        );
      }
      return AppUser(
        uid: authUser.uid,
        displayName: (data['displayName'] as String?) ?? fallbackName,
        email: (data['email'] as String?) ?? authUser.email,
        role: UserRole.parse(data['role'] as String?),
        photoUrl: data['photoUrl'] as String?,
      );
    });
  }

  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_messageFor(e.code));
    }
  }

  /// Crea la cuenta de una persona aprendiz y su perfil. Quien llama debe
  /// haber verificado que se aceptaron los términos y la política de datos.
  Future<void> register({
    required String alias,
    required String email,
    required String password,
    Uint8List? photoBytes,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AuthFailure('No se pudo crear la cuenta. Inténtalo de nuevo.');
      }
      final cleanAlias = alias.trim();
      await user.updateDisplayName(cleanAlias);
      await _users.doc(user.uid).set({
        'displayName': cleanAlias,
        'email': email.trim(),
        'role': 'aprendiz',
        'photoUrl': null,
        'acceptedDataPolicy': true,
        'policyVersion': AppConstants.policyVersion,
        'acceptedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (photoBytes != null) {
        try {
          await updateProfilePhoto(uid: user.uid, bytes: photoBytes);
        } catch (e) {
          // La foto es opcional: si falla, la cuenta ya quedó creada.
          debugPrint('No se pudo subir la foto de perfil: $e');
        }
      }
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_messageFor(e.code));
    } on FirebaseException catch (e) {
      throw AuthFailure(
        'Tu cuenta se creó, pero no pudimos guardar tu perfil (${e.code}). '
        'Cierra sesión e inténtalo de nuevo.',
      );
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_messageFor(e.code));
    }
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> updateDisplayName({
    required String uid,
    required String alias,
  }) async {
    final cleanAlias = alias.trim();
    await _users.doc(uid).update({'displayName': cleanAlias});
    await _auth.currentUser?.updateDisplayName(cleanAlias);
  }

  /// Sube la foto de perfil y guarda su URL en el perfil.
  Future<String> updateProfilePhoto({
    required String uid,
    required Uint8List bytes,
  }) async {
    final ref = _storage.ref('profile_photos/$uid.jpg');
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    final url = await ref.getDownloadURL();
    await _users.doc(uid).update({'photoUrl': url});
    return url;
  }

  /// Elimina la cuenta y los datos personales (derecho de supresión, Ley 1581
  /// de 2012): progreso, perfil, foto, encuestas y solicitudes de la persona.
  Future<void> deleteAccount({required String password}) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      throw const AuthFailure('No hay una sesión activa.');
    }
    try {
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: email, password: password),
      );
      final uid = user.uid;
      await _deleteOwnDocuments('encuestas', uid);
      await _deleteOwnDocuments('solicitudesColaborador', uid);
      await _firestore.collection('progress').doc(uid).delete();
      await _users.doc(uid).delete();
      try {
        await _storage.ref('profile_photos/$uid.jpg').delete();
      } catch (_) {
        // Puede no existir una foto.
      }
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_messageFor(e.code));
    } on FirebaseException catch (e) {
      throw AuthFailure('No se pudo eliminar la cuenta (${e.code}).');
    }
  }

  Future<void> _deleteOwnDocuments(String collection, String uid) async {
    final snapshot = await _firestore
        .collection(collection)
        .where('uid', isEqualTo: uid)
        .get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  String _messageFor(String code) {
    switch (code) {
      case 'invalid-email':
        return 'El correo electrónico no es válido.';
      case 'user-disabled':
        return 'Esta cuenta está deshabilitada. Escríbenos a '
            '${AppConstants.supportEmail}.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Correo o contraseña incorrectos.';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con ese correo.';
      case 'weak-password':
        return 'La contraseña es muy débil. Usa al menos 8 caracteres.';
      case 'too-many-requests':
        return 'Demasiados intentos. Espera unos minutos e inténtalo de nuevo.';
      case 'network-request-failed':
        return 'Sin conexión a internet. Revisa tu red e inténtalo de nuevo.';
      case 'requires-recent-login':
        return 'Por seguridad, vuelve a iniciar sesión e inténtalo de nuevo.';
      default:
        return 'Ocurrió un error inesperado ($code). Inténtalo de nuevo.';
    }
  }
}
