// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/routes.dart';
import '../../domain/value_objects/scanner_status.dart';
import '../providers/providers.dart';
import '../widgets/card_overlay_frame.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  Timer? _analysisTimer;
  bool _isInitializingCamera = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _analysisTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      controller.dispose();
      _controller = null;
      _analysisTimer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    if (_isInitializingCamera) {
      return;
    }
    _isInitializingCamera = true;
    try {
      final camera = await ref.read(rearCameraProvider.future);
      if (!mounted || camera == null) {
        ref.read(scannerNotifierProvider.notifier).setPreviewStatus(
              'Camera unavailable',
              status: ScannerStatus.error,
            );
        return;
      }

      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      await _controller?.dispose();
      _controller = controller;
      _startMockFrameAnalysis();
      setState(() {});
    } catch (_) {
      ref.read(scannerNotifierProvider.notifier).setPreviewStatus(
            'Camera unavailable',
            status: ScannerStatus.error,
          );
    } finally {
      _isInitializingCamera = false;
    }
  }

  void _startMockFrameAnalysis() {
    _analysisTimer?.cancel();
    final notifier = ref.read(scannerNotifierProvider.notifier);
    final nativeVision = ref.read(nativeVisionServiceProvider);
    var tick = 0;

    _analysisTimer = Timer.periodic(const Duration(milliseconds: 900), (_) async {
      final controller = _controller;
      if (!mounted || controller == null || !controller.value.isInitialized) {
        return;
      }
      if (ref.read(scannerNotifierProvider).status == ScannerStatus.processing ||
          ref.read(scannerNotifierProvider).status == ScannerStatus.capturing) {
        return;
      }

      tick++;
      final messages = <String>[
        'Align the card',
        'Move closer',
        'Hold steady',
      ];
      final message = messages[tick % messages.length];
      final status = message == 'Hold steady'
          ? ScannerStatus.readyToCapture
          : ScannerStatus.analyzing;

      notifier.setPreviewStatus(message, status: status);

      // Hook kept in place for future automatic quality gating via native CV.
      await nativeVision.measureImageQuality('preview-frame');
    });
  }

  Future<void> _captureCard() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || controller.value.isTakingPicture) {
      return;
    }

    try {
      final picture = await controller.takePicture();
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushNamed(AppRoutes.processing);
      unawaited(ref.read(scannerNotifierProvider.notifier).captureImage(picture.path));
    } catch (_) {
      ref.read(scannerNotifierProvider.notifier).setPreviewStatus(
            'Capture failed',
            status: ScannerStatus.error,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bootstrap = ref.watch(appBootstrapProvider);
    final scannerState = ref.watch(scannerNotifierProvider);
    final cameraAsync = ref.watch(rearCameraProvider);

    ref.listen<AsyncValue<CameraDescription?>>(rearCameraProvider, (previous, next) {
      next.whenData((camera) {
        if (camera != null && _controller == null) {
          _initializeCamera();
        }
      });
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('MTG Card Scanner'),
        actions: [
          IconButton(
            onPressed: () async {
              await Navigator.of(context).pushNamed(AppRoutes.history);
              if (mounted) {
                ref.invalidate(historyEntriesProvider);
              }
            },
            icon: const Icon(Icons.history),
          ),
        ],
      ),
      body: bootstrap.when(
        data: (_) {
          if (cameraAsync.hasError || scannerState.status == ScannerStatus.error && _controller == null) {
            return _CameraMessage(
              title: 'Camera unavailable',
              message: 'The app could not open the rear camera on this device.',
              actionLabel: 'Retry',
              onPressed: _initializeCamera,
            );
          }

          final controller = _controller;
          if (controller == null || !controller.value.isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              CameraPreview(controller),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.45),
                      Colors.transparent,
                      Colors.black.withOpacity(0.55),
                    ],
                  ),
                ),
              ),
              const CardOverlayFrame(),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          scannerState.message,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Manual capture enabled. Automatic capture hook is prepared for native CV.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: _captureCard,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Capture'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _CameraMessage(
          title: 'Database error',
          message: 'The local catalog could not be initialized.',
          actionLabel: 'Retry',
          onPressed: () => ref.invalidate(appBootstrapProvider),
        ),
      ),
    );
  }
}

class _CameraMessage extends StatelessWidget {
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onPressed;

  const _CameraMessage({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onPressed,
  });

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
