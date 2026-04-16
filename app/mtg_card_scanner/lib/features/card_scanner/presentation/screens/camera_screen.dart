// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/routes.dart';
import '../../../../core/errors/app_exception.dart';
import '../providers/providers.dart';
import '../widgets/manual_capture_camera_view.dart';

class CameraScreen extends ConsumerWidget {
  const CameraScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrap = ref.watch(appBootstrapProvider);
    final scannerState = ref.watch(scannerNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MTG Card Scanner'),
        actions: [
          IconButton(
            onPressed: () async {
              await Navigator.of(context).pushNamed(AppRoutes.history);
              ref.invalidate(historyEntriesProvider);
            },
            icon: const Icon(Icons.history),
          ),
        ],
      ),
      body: bootstrap.when(
        data: (_) => ManualCaptureCameraView(
          statusMessage: scannerState.message,
          onStatusChanged:
              ref.read(scannerNotifierProvider.notifier).setPreviewStatus,
          onCaptureRequested: (imagePath) => ref
              .read(scannerNotifierProvider.notifier)
              .captureImage(imagePath),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) {
          var message = 'The local catalog could not be initialized.';
          if (error is MissingCatalogAssetException) {
            message = 'The SQLite asset is missing.\n\n'
                'Run these commands from the repository root:\n'
                '1. cd tools/mtg_data_extractor\n'
                '2. python3 -m mtg_data_extractor.cli build\n'
                '3. python3 -m mtg_data_extractor.cli sync';
          } else if (error is AppException) {
            message = error.message;
          }

          return _CameraMessage(
            title: 'Database initialization failed',
            message: message,
            actionLabel: 'Retry',
            onPressed: () => ref.invalidate(appBootstrapProvider),
          );
        },
      ),
    );
  }
}

class _CameraMessage extends StatelessWidget {
  const _CameraMessage({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onPressed,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onPressed,
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
