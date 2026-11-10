import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../analytics/analytics_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../application/collaborator_providers.dart';
import '../data/collaborator_repository.dart';

/// Solicitud de una persona sorda para colaborar (modelo de señas, validador
/// lingüístico u orientador cultural). El equipo la verifica manualmente.
class CollaboratorFormScreen extends ConsumerStatefulWidget {
  const CollaboratorFormScreen({super.key});

  @override
  ConsumerState<CollaboratorFormScreen> createState() =>
      _CollaboratorFormScreenState();
}

class _CollaboratorFormScreenState
    extends ConsumerState<CollaboratorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  final _phone = TextEditingController();
  final _experience = TextEditingController();

  CollaboratorRole? _role;
  bool _imageConsent = false;
  bool _dataConsent = false;
  bool _showErrors = false;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(appUserProvider).valueOrNull;
    _name = TextEditingController();
    _email = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _experience.dispose();
    super.dispose();
  }

  bool get _choicesComplete => _role != null && _imageConsent && _dataConsent;

  Future<void> _submit() async {
    final valid = _formKey.currentState?.validate() ?? false;
    setState(() => _showErrors = true);
    if (!valid || !_choicesComplete) return;
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;

    setState(() => _sending = true);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      await ref.read(collaboratorRepositoryProvider).submit(
            uid: uid,
            fullName: _name.text,
            email: _email.text,
            phone: _phone.text,
            role: _role!,
            experience: _experience.text,
          );
      ref.read(analyticsProvider).collaboratorApplicationSent();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Solicitud enviada. El equipo la revisará y te contactará.'),
        ),
      );
      router.pop();
    } catch (_) {
      if (mounted) setState(() => _sending = false);
      messenger.showSnackBar(
        const SnackBar(content: Text('No pudimos enviar la solicitud. Inténtalo de nuevo.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;
    return Scaffold(
      appBar: AppBar(title: const Text('Quiero colaborar')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.mist,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Los contenidos de I Love LSC se crean con la participación '
                'remunerada de personas sordas. Si quieres colaborar, completa '
                'este formulario: el equipo verificará tu solicitud '
                'manualmente. El acuerdo de colaboración y la autorización de '
                'uso de imagen se firman por fuera de la app.',
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _name,
              textInputAction: TextInputAction.next,
              validator: Validators.fullName,
              decoration: const InputDecoration(
                labelText: 'Nombre completo',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: Validators.email,
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              validator: Validators.phone,
              decoration: const InputDecoration(
                labelText: 'Número de teléfono',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Semantics(
              header: true,
              child: Text('Rol', style: Theme.of(context).textTheme.titleMedium),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final role in CollaboratorRole.values)
                  ChoiceChip(
                    label: Text(role.label),
                    selected: _role == role,
                    onSelected: (_) => setState(() => _role = role),
                  ),
              ],
            ),
            if (_showErrors && _role == null)
              Text('Elige un rol.', style: TextStyle(color: errorColor)),
            const SizedBox(height: 20),
            TextFormField(
              controller: _experience,
              maxLines: 4,
              validator: (value) => Validators.requiredField(
                value,
                message: 'Cuéntanos tu experiencia en LSC o tu vínculo con la comunidad sorda',
              ),
              decoration: const InputDecoration(
                labelText: 'Experiencia en LSC o vínculo con la comunidad sorda '
                    '(por ejemplo, asociación o colectivo)',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _imageConsent,
              onChanged: (v) => setState(() => _imageConsent = v ?? false),
              title: const Text(
                'Doy mi consentimiento informado para el uso de mi imagen y de '
                'los videos grabados en I Love LSC.',
              ),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _dataConsent,
              onChanged: (v) => setState(() => _dataConsent = v ?? false),
              title: const Text(
                'Autorizo el tratamiento de mis datos personales (Ley 1581 de 2012).',
              ),
            ),
            if (_showErrors && (!_imageConsent || !_dataConsent))
              Semantics(
                liveRegion: true,
                child: Text(
                  'Debes aceptar ambas autorizaciones para enviar la solicitud.',
                  style: TextStyle(color: errorColor, fontWeight: FontWeight.w700),
                ),
              ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _sending ? null : _submit,
              child: _sending
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    )
                  : const Text('Enviar solicitud'),
            ),
          ],
        ),
      ),
    );
  }
}
