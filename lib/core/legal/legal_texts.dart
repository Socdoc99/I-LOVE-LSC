/// Textos legales de la app.
///
/// IMPORTANTE: son BORRADORES redactados a partir de la ficha técnica para el
/// prototipo. Deben ser revisados y completados por el equipo (y, de ser
/// posible, por asesoría jurídica) antes de publicar la app. Los puntos
/// marcados con [POR DEFINIR] requieren una decisión del equipo.
class LegalSection {
  const LegalSection(this.title, this.body);

  final String title;
  final String body;
}

class LegalTexts {
  const LegalTexts._();

  static const String draftNotice =
      'Borrador para el prototipo. Será revisado antes de la publicación '
      'de la app.';

  static const List<LegalSection> terms = [
    LegalSection(
      '1. Qué es I Love LSC',
      'I Love LSC es una plataforma digital educativa e interactiva para '
          'aprender Lengua de Señas Colombiana (LSC), conocer la cultura de la '
          'comunidad sorda y promover la inclusión comunicativa y social. '
          'Esta versión es un prototipo para validación con usuarios.',
    ),
    LegalSection(
      '2. Uso de la app',
      'El uso del prototipo es gratuito. Te comprometes a usar la app de '
          'forma respetuosa, a no compartir tu cuenta y a no copiar, '
          'redistribuir ni modificar los videos y demás contenidos sin '
          'autorización de I Love LSC y de las personas que aparecen en ellos.',
    ),
    LegalSection(
      '3. Contenido creado con la comunidad sorda',
      'Los contenidos se crean, graban y validan con la participación de '
          'personas sordas, quienes reciben una remuneración por su trabajo. '
          'Los videos muestran a personas reales: su imagen se usa con su '
          'consentimiento informado y solo para los fines de la plataforma.',
    ),
    LegalSection(
      '4. La constancia o insignia digital',
      'Al completar el recorrido recibes una constancia o insignia digital. '
          'No es un certificado de aptitud ocupacional ni un título '
          'académico (Decreto 1075 de 2015, art. 2.6.6.8).',
    ),
    LegalSection(
      '5. Cuentas y colaboradores',
      'Las personas aprendices crean una cuenta con alias, correo y '
          'contraseña. Las personas sordas que deseen colaborar envían una '
          'solicitud que el equipo verifica manualmente; la colaboración se '
          'formaliza con un acuerdo firmado por fuera de la app.',
    ),
    LegalSection(
      '6. Disponibilidad y cambios',
      'Al ser un prototipo, la app puede cambiar, tener errores o '
          'interrumpirse. Podemos actualizar estos términos; te avisaremos '
          'dentro de la app cuando haya cambios importantes. [POR DEFINIR: '
          'canal y plazo de aviso].',
    ),
    LegalSection(
      '7. Contacto y ley aplicable',
      'Para preguntas, quejas y reclamos escribe a love25universal@gmail.com. '
          'Estos términos se rigen por las leyes de Colombia.',
    ),
  ];

  static const List<LegalSection> dataPolicy = [
    LegalSection(
      '1. Responsable del tratamiento',
      'I Love LSC, Pereira, Risaralda, Colombia. Correo: '
          'love25universal@gmail.com. Teléfono y WhatsApp: +57 312 2697240.',
    ),
    LegalSection(
      '2. Datos que tratamos',
      'Personas aprendices: alias, correo electrónico, contraseña (gestionada '
          'de forma segura por Firebase Authentication), foto de perfil '
          '(opcional), progreso en las lecciones (XP, racha, vidas, repasos), '
          'respuestas a la encuesta de experiencia, token de notificaciones '
          '(si activas los recordatorios) y datos de uso de la app.\n\n'
          'Personas colaboradoras sordas: nombre completo, correo, teléfono, '
          'rol, experiencia o vínculo con la comunidad sorda y consentimiento '
          'para el uso de su imagen y de los videos grabados.',
    ),
    LegalSection(
      '3. Para qué los usamos',
      'Para crear y administrar tu cuenta, mostrar y guardar tu progreso, '
          'enviarte recordatorios de práctica (solo si los activas), evaluar '
          'y mejorar el prototipo con la encuesta y las métricas de uso, y '
          'gestionar la colaboración con personas sordas.',
    ),
    LegalSection(
      '4. Autorización',
      'Tratamos tus datos con tu autorización previa, expresa e informada, '
          'que das al registrarte (Ley 1581 de 2012). Solo pedimos la '
          'información necesaria. Para usar la imagen de las personas '
          'colaboradoras se pide, además, un consentimiento informado '
          'específico.',
    ),
    LegalSection(
      '5. Tus derechos',
      'Puedes conocer, actualizar y rectificar tus datos, solicitar prueba '
          'de la autorización, ser informado del uso que se les da, presentar '
          'quejas ante la Superintendencia de Industria y Comercio, revocar '
          'la autorización y pedir la supresión de tus datos. Dentro de la '
          'app puedes eliminar tu cuenta y tus datos desde Perfil → Eliminar '
          'mi cuenta. También puedes escribir a love25universal@gmail.com.',
    ),
    LegalSection(
      '6. Seguridad y terceros',
      'Los datos se almacenan en servicios administrados de Google Firebase '
          '(Authentication, Firestore, Storage, Cloud Messaging y Analytics). '
          'No vendemos tus datos. El código fuente de la app es público, pero '
          'los videos, los datos personales y las llaves de acceso no se '
          'guardan en el repositorio.',
    ),
    LegalSection(
      '7. Menores de edad',
      '[POR DEFINIR] El equipo debe decidir la edad mínima de uso y el '
          'procedimiento de autorización de padres o representantes legales '
          'para menores de 18 años.',
    ),
    LegalSection(
      '8. Conservación',
      '[POR DEFINIR] Tiempo de conservación de los datos tras finalizar el '
          'piloto. Mientras tanto, conservamos los datos mientras tu cuenta '
          'esté activa y los eliminamos cuando solicites la supresión.',
    ),
  ];
}
