/// Persona con sesión iniciada (datos mínimos que expone Firebase Auth).
class AuthUser {
  const AuthUser({
    required this.uid,
    required this.email,
    required this.displayName,
  });

  final String uid;
  final String email;
  final String displayName;
}
