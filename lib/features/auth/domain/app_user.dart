/// Tipo de cuenta. El rol `admin` (administrador de contenidos del equipo)
/// solo se asigna desde la consola de Firebase, nunca desde la app.
enum UserRole {
  aprendiz,
  colaborador,
  admin;

  static UserRole parse(String? value) {
    switch (value) {
      case 'admin':
        return UserRole.admin;
      case 'colaborador':
        return UserRole.colaborador;
      default:
        return UserRole.aprendiz;
    }
  }
}

/// Perfil guardado en Firestore (`users/{uid}`).
class AppUser {
  const AppUser({
    required this.uid,
    required this.displayName,
    this.email = '',
    this.role = UserRole.aprendiz,
    this.photoUrl,
  });

  final String uid;
  final String displayName;
  final String email;
  final UserRole role;
  final String? photoUrl;
}
