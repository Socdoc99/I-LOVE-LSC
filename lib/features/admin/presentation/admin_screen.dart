import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/state_views.dart';
import '../../auth/application/auth_providers.dart';
import '../../collaborators/application/collaborator_providers.dart';
import '../../collaborators/data/collaborator_repository.dart';
import '../../content/application/content_providers.dart';
import '../../content/domain/learning_unit.dart';
import '../../content/domain/lesson.dart';

/// Administración de contenidos (solo rol `admin`): validar y publicar
/// lecciones, y revisar solicitudes de colaboradores.
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Administración'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Lecciones'),
              Tab(text: 'Solicitudes'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_LessonsTab(), _ApplicationsTab()],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------- Lecciones

class _LessonsTab extends ConsumerWidget {
  const _LessonsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonsAsync = ref.watch(adminLessonsProvider);
    final unitsAsync = ref.watch(adminUnitsProvider);
    final units = unitsAsync.valueOrNull ?? <LearningUnit>[];
    final unitTitles = <String, String>{
      for (final unit in units) unit.id: unit.title,
    };

    return lessonsAsync.when(
      loading: () => const LoadingView(),
      error: (error, stack) => ErrorView(
        message: 'No pudimos cargar las lecciones.\n$error',
        onRetry: () => ref.invalidate(adminLessonsProvider),
      ),
      data: (lessons) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Una lección solo se puede publicar después de ser validada por '
            'personas sordas (validación lingüística y cultural).',
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _seed(context, ref),
            icon: const Icon(Icons.upload_file),
            label: const Text('Cargar contenido de ejemplo'),
          ),
          const SizedBox(height: 12),
          if (lessons.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Todavía no hay lecciones. Carga el contenido de ejemplo para '
                'probar la app.',
                textAlign: TextAlign.center,
              ),
            ),
          for (final lesson in lessons)
            _LessonCard(
              lesson: lesson,
              unitTitle: unitTitles[lesson.unitId] ?? lesson.unitId,
            ),
        ],
      ),
    );
  }

  Future<void> _seed(BuildContext context, WidgetRef ref) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cargar contenido de ejemplo'),
        content: const Text(
          'Crea 3 unidades, 25 señas y 7 lecciones de ejemplo. Si ya existían, '
          'se sobrescriben (y se pierde su estado de validación).\n\n'
          '• Borrador: las lecciones quedan SIN validar ni publicar y los '
          'videos se esperan en Cloud Storage (videos/…).\n\n'
          '• Modo pruebas: SOLO para desarrollo. Marca todo como validado y '
          'publicado y usa un video de muestra que NO es una seña real.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop('borrador'),
            child: const Text('Borrador'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop('pruebas'),
            child: const Text('Modo pruebas'),
          ),
        ],
      ),
    );
    if (choice == null) return;

    try {
      await ref
          .read(contentRepositoryProvider)
          .seedSampleContent(testMode: choice == 'pruebas');
      if (!context.mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      ref.invalidate(adminLessonsProvider);
      ref.invalidate(adminUnitsProvider);
      ref.invalidate(catalogProvider);
      messenger.showSnackBar(
        const SnackBar(content: Text('Contenido de ejemplo cargado.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(content: Text('No se pudo cargar el contenido: $e')),
      );
    }
  }
}

class _LessonCard extends ConsumerWidget {
  const _LessonCard({required this.lesson, required this.unitTitle});

  final Lesson lesson;
  final String unitTitle;

  Future<void> _update(
    BuildContext context,
    WidgetRef ref, {
    required bool validated,
    required bool published,
  }) async {
    final adminUid = ref.read(authStateProvider).valueOrNull?.uid;
    if (adminUid == null) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(contentRepositoryProvider).setLessonState(
            lessonId: lesson.id,
            validated: validated,
            published: published,
            adminUid: adminUid,
          );
      ref.invalidate(adminLessonsProvider);
      ref.invalidate(catalogProvider);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('No se pudo actualizar la lección: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: Text(
                lesson.title,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text('$unitTitle · ${lesson.signIds.length} señas'),
            ),
            SwitchListTile(
              title: const Text('Validada por personas sordas'),
              value: lesson.validated,
              onChanged: (value) => _update(
                context,
                ref,
                validated: value,
                published: value ? lesson.published : false,
              ),
            ),
            SwitchListTile(
              title: const Text('Publicada'),
              subtitle: lesson.validated
                  ? null
                  : const Text('Primero debe estar validada'),
              value: lesson.published,
              onChanged: lesson.validated
                  ? (value) => _update(
                        context,
                        ref,
                        validated: true,
                        published: value,
                      )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------- Solicitudes

class _ApplicationsTab extends ConsumerWidget {
  const _ApplicationsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applications = ref.watch(collaboratorApplicationsProvider);
    return applications.when(
      loading: () => const LoadingView(),
      error: (error, stack) => ErrorView(
        message: 'No pudimos cargar las solicitudes.\n$error',
        onRetry: () => ref.invalidate(collaboratorApplicationsProvider),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const EmptyView(
            icon: Icons.inbox_outlined,
            message: 'No hay solicitudes de colaboradores.',
          );
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final application in items) _ApplicationCard(application: application),
          ],
        );
      },
    );
  }
}

class _ApplicationCard extends ConsumerWidget {
  const _ApplicationCard({required this.application});

  final CollaboratorApplication application;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final createdAt = application.createdAt;
    final repository = ref.read(collaboratorRepositoryProvider);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    application.fullName,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
                Chip(label: Text(application.status)),
              ],
            ),
            Text('${application.role} · ${application.email} · ${application.phone}'),
            if (createdAt != null) Text('Enviada: ${formatLongDate(createdAt)}'),
            const SizedBox(height: 8),
            Text(application.experience),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton(
                  onPressed: () => repository.setStatus(application.id, 'aprobada'),
                  child: const Text('Aprobar'),
                ),
                TextButton(
                  onPressed: () => repository.setStatus(application.id, 'rechazada'),
                  child: const Text(
                    'Rechazar',
                    style: TextStyle(color: AppColors.danger),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
