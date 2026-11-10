import 'package:flutter/material.dart';

/// Diálogo con un campo de texto. Devuelve el texto escrito o `null` si se
/// cancela. Maneja su propio controlador para liberarlo correctamente.
class TextPromptDialog extends StatefulWidget {
  const TextPromptDialog({
    super.key,
    required this.title,
    required this.label,
    this.message,
    this.initialValue = '',
    this.obscure = false,
    this.confirmLabel = 'Aceptar',
    this.keyboardType,
    this.validator,
  });

  final String title;
  final String label;
  final String? message;
  final String initialValue;
  final bool obscure;
  final String confirmLabel;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  State<TextPromptDialog> createState() => _TextPromptDialogState();
}

class _TextPromptDialogState extends State<TextPromptDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.of(context).pop(_controller.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.message != null) ...[
              Text(widget.message!),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _controller,
              autofocus: true,
              obscureText: widget.obscure,
              keyboardType: widget.keyboardType,
              validator: widget.validator,
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: widget.label,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        TextButton(onPressed: _submit, child: Text(widget.confirmLabel)),
      ],
    );
  }
}
