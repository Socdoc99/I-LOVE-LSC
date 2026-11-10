/// Una seña de la LSC con su palabra en español y la ruta de su video en
/// Cloud Storage (por ejemplo `videos/saludos/hola.mp4`).
class Sign {
  const Sign({
    required this.id,
    required this.word,
    required this.unitId,
    this.videoPath = '',
    this.context = '',
  });

  final String id;
  final String word;
  final String unitId;
  final String videoPath;

  /// Situación comunicativa en la que se usa la seña.
  final String context;
}
