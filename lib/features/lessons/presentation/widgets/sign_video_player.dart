import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../content/application/content_providers.dart';
import '../../../content/domain/sign.dart';

/// Reproduce el video de una seña desde Cloud Storage, con opción de pausar y
/// repetir (controles de Chewie, que incluyen velocidad de reproducción).
///
/// Si el video aún no existe o no se puede cargar, muestra un aviso en lugar
/// de fallar. Usa `key: ValueKey(sign.id)` al cambiar de seña.
class SignVideoPlayer extends ConsumerStatefulWidget {
  const SignVideoPlayer({
    super.key,
    required this.sign,
    this.autoPlay = true,
    this.looping = true,

    /// Si es `false`, no se muestra la palabra en el aviso de video no
    /// disponible (por ejemplo en «Ver y elegir», donde sería la respuesta).
    this.showWordWhenUnavailable = true,
  });

  final Sign sign;
  final bool autoPlay;
  final bool looping;
  final bool showWordWhenUnavailable;

  @override
  ConsumerState<SignVideoPlayer> createState() => _SignVideoPlayerState();
}

class _SignVideoPlayerState extends ConsumerState<SignVideoPlayer> {
  static const double _maxHeight = 320;

  VideoPlayerController? _video;
  ChewieController? _chewie;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final path = widget.sign.videoPath;
    if (path.isEmpty) {
      _failed = true; // Se ejecuta de forma síncrona dentro de initState.
      return;
    }
    try {
      final url = await ref.read(signVideoUrlProvider(path).future);
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      final chewie = ChewieController(
        videoPlayerController: controller,
        autoPlay: widget.autoPlay,
        looping: widget.looping,
        allowFullScreen: false,
        allowMuting: false,
      );
      setState(() {
        _video = controller;
        _chewie = chewie;
      });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _chewie?.dispose();
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chewie = _chewie;
    final video = _video;

    if (_failed) {
      return _Placeholder(
        sign: widget.sign,
        showWord: widget.showWordWhenUnavailable,
      );
    }
    if (chewie == null || video == null) {
      return const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final ratio = video.value.aspectRatio <= 0 ? 16 / 9 : video.value.aspectRatio;
    return Semantics(
      label: 'Video de la seña. Usa los controles para pausar o repetir.',
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: _maxHeight),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: ratio,
            child: Chewie(controller: chewie),
          ),
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.sign, required this.showWord});

  final Sign sign;
  final bool showWord;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'El video de esta seña aún no está disponible',
      child: Container(
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.mist,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam_off_outlined, size: 48, color: AppColors.navy),
            const SizedBox(height: 8),
            const Text(
              'Video no disponible todavía',
              style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
            ),
            if (showWord) ...[
              const SizedBox(height: 4),
              Text(
                sign.word,
                style: const TextStyle(fontSize: 20, color: AppColors.ink),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
