import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/text_prompt_dialog.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/app_user.dart';
import '../../notifications/notification_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(appUserProvider);
    final remindersOn = ref.watch(remindersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      body: userAsync.when(
        loading: () => const LoadingView(),
        error: (error, stack) =>
            const ErrorView(message: 'No pudimos cargar tu perfil.'),
        data: (user) {
          if (user == null) return const LoadingView();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Header(user: user),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Cambiar nombre o alias'),
                onTap: () => _editName(context, ref, user),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Cambiar foto de perfil'),
                onTap: () => _changePhoto(context, ref, user),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.notifications_active_outlined),
                title: const Text('Recordatorios de práctica'),
                subtitle: const Text('Te avisamos para mantener tu racha diaria.'),
                value: remindersOn,
                onChanged: (value) => _toggleReminders(context, ref, value),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.rate_review_outlined),
                title: const Text('Encuesta de experiencia'),
                subtitle: const Text('Ayúdanos a mejorar el prototipo.'),
                onTap: () => context.push('/encuesta'),
              ),
              ListTile(
                leading: const Icon(Icons.volunteer_activism_outlined),
                title: const Text('Quiero colaborar'),
                subtitle: const Text(
                  'Para personas sordas: modelo de señas, validación u orientación cultural.',
                ),
                onTap: () => context.push('/colaborar'),
              ),
              if (user.role == UserRole.admin)
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings_outlined),
                  title: const Text('Administración de contenidos'),
                  onTap: () => context.push('/admin'),
                ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('Términos de uso'),
                onTap: () => context.push('/terminos'),
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Política de tratamiento de datos'),
                onTap: () => context.push('/politica-datos'),
              ),
              const ListTile(
                leading: Icon(Icons.support_agent_outlined),
                title: Text('Soporte'),
                subtitle: Text(
                  '${AppConstants.supportEmail}\nHorario de atención: 8:00 am a 6:00 pm (Bogotá)',
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Cerrar sesión'),
                onTap: () => ref.read(authRepositoryProvider).signOut(),
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: AppColors.danger),
                title: const Text(
                  'Eliminar mi cuenta y mis datos',
                  style: TextStyle(color: AppColors.danger),
                ),
                onTap: () => _deleteAccount(context, ref),
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  'I Love LSC · Prototipo 1.0.1',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _editName(BuildContext context, WidgetRef ref, AppUser user) async {
    final alias = await showDialog<String>(
      context: context,
      builder: (_) => TextPromptDialog(
        title: 'Nombre o alias',
        label: 'Nombre o alias',
        initialValue: user.displayName,
        confirmLabel: 'Guardar',
        validator: Validators.alias,
      ),
    );
    if (alias == null) return;
    if (!context.mounted) return;
    try {
      await ref
          .read(authRepositoryProvider)
          .updateDisplayName(uid: user.uid, alias: alias);
      if (!context.mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(const SnackBar(content: Text('Nombre actualizado.')));
    } catch (_) {
      if (!context.mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('No pudimos guardar el cambio.')),
      );
    }
  }

  Future<void> _changePhoto(BuildContext context, WidgetRef ref, AppUser user) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      await ref
          .read(authRepositoryProvider)
          .updateProfilePhoto(uid: user.uid, bytes: bytes);
      messenger.showSnackBar(const SnackBar(content: Text('Foto actualizada.')));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No pudimos actualizar la foto.')),
      );
    }
  }

  Future<void> _toggleReminders(BuildContext context, WidgetRef ref, bool value) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final ok = await ref.read(remindersProvider.notifier).setEnabled(value);
      if (!ok && value) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'No se concedió el permiso de notificaciones. Puedes activarlo '
              'en los ajustes del teléfono.',
            ),
          ),
        );
      }
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No pudimos cambiar los recordatorios.')),
      );
    }
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Eliminar tu cuenta?'),
        content: const Text(
          'Se borrarán tu perfil, tu foto, tu progreso y tus respuestas. '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
    if (sure != true || !context.mounted) return;

    final password = await showDialog<String>(
      context: context,
      builder: (_) => TextPromptDialog(
        title: 'Confirma tu contraseña',
        message: 'Por seguridad, escribe tu contraseña para eliminar la cuenta.',
        label: 'Contraseña',
        obscure: true,
        confirmLabel: 'Eliminar cuenta',
        validator: (value) =>
            Validators.requiredField(value, message: 'Escribe tu contraseña'),
      ),
    );
    if (password == null) return;

    if (!context.mounted) return;
    try {
      await ref.read(authRepositoryProvider).deleteAccount(password: password);
      // Al borrarse la cuenta, el router lleva al inicio de sesión.
    } on AuthFailure catch (e) {
      if (!context.mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final photoUrl = user.photoUrl;
    return Column(
      children: [
        Semantics(
          label: 'Foto de perfil de ${user.displayName}',
          child: CircleAvatar(
            radius: 48,
            backgroundImage: photoUrl == null ? null : NetworkImage(photoUrl),
            child: photoUrl == null ? const Icon(Icons.person, size: 48) : null,
          ),
        ),
        const SizedBox(height: 12),
        Semantics(
          header: true,
          child: Text(
            user.displayName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        Text(user.email),
      ],
    );
  }
}
