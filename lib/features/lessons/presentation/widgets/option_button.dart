import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

enum OptionState { idle, selected, correct, wrong }

/// Botón de respuesta. El resultado se comunica con color **y** con ícono y
/// texto, para que no dependa solo del color.
class OptionButton extends StatelessWidget {
  const OptionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.state = OptionState.idle,
  });

  final String label;
  final VoidCallback? onPressed;
  final OptionState state;

  @override
  Widget build(BuildContext context) {
    final Color background;
    final Color foreground;
    final Color border;
    IconData? icon;
    String? stateLabel;

    switch (state) {
      case OptionState.correct:
        background = AppColors.successSurface;
        foreground = AppColors.success;
        border = AppColors.success;
        icon = Icons.check_circle;
        stateLabel = 'Correcta';
      case OptionState.wrong:
        background = AppColors.dangerSurface;
        foreground = AppColors.danger;
        border = AppColors.danger;
        icon = Icons.cancel;
        stateLabel = 'Incorrecta';
      case OptionState.selected:
        background = AppColors.mist;
        foreground = AppColors.navy;
        border = AppColors.navy;
        icon = Icons.radio_button_checked;
        stateLabel = 'Seleccionada';
      case OptionState.idle:
        background = Colors.white;
        foreground = AppColors.ink;
        border = const Color(0xFF8A94A3);
    }

    return Semantics(
      button: true,
      label: stateLabel == null ? label : '$label. $stateLabel',
      excludeSemantics: true,
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: border, width: 2),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: foreground,
                      ),
                    ),
                  ),
                  if (icon != null) Icon(icon, color: foreground),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
