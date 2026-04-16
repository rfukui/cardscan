// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/value_objects/scanner_status.dart';
import '../providers/providers.dart';
import 'card_overlay_frame.dart';

typedef ScannerStatusCallback = void Function(
  String message, {
  ScannerStatus status,
});

class ManualCaptureCameraView extends ConsumerStatefulWidget {
  const ManualCaptureCameraView({
    super.key,
    required this.statusMessage,
    required this.onStatusChanged,
    required this.onCaptureRequested,
  });

  final String statusMessage;
  final ScannerStatusCallback onStatusChanged;
  final Future<void> Function(String imagePath) onCaptureRequested;

  @override
  ConsumerState<ManualCaptureCameraView> createState() =>
      _ManualCaptureCameraViewState();
}

class _ManualCaptureCameraViewState
    extends ConsumerState<ManualCaptureCameraView> with WidgetsBindingObserver {
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

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<CameraDescription?>>(rearCameraProvider,
        (previous, next) {
      next.whenData((camera) {
        if (camera != null && _controller == null) {
          _initializeCamera();
        }
      });
    });

    final scannerState = ref.watch(scannerNotifierProvider);
    final cameraAsync = ref.watch(rearCameraProvider);

    if (cameraAsync.hasError ||
        scannerState.status == ScannerStatus.error && _controller == null) {
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
                Colors.black.withValues(alpha: 0.45),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.55),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    widget.statusMessage,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Manual capture mode. Tap capture when the card is readable in the frame.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _captureCard,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Capture'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _initializeCamera() async {
    if (_isInitializingCamera) {
      return;
    }

    _isInitializingCamera = true;
    try {
      final camera = await ref.read(rearCameraProvider.future);
      if (!mounted || camera == null) {
        widget.onStatusChanged(
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
      _startPreviewHealthCheck();
      widget.onStatusChanged(
        'Position the card inside the frame',
        status: ScannerStatus.readyToCapture,
      );
      setState(() {});
    } catch (_) {
      widget.onStatusChanged(
        'Camera unavailable',
        status: ScannerStatus.error,
      );
    } finally {
      _isInitializingCamera = false;
    }
  }

  void _startPreviewHealthCheck() {
    _analysisTimer?.cancel();
    final nativeVision = ref.read(nativeVisionServiceProvider);

    _analysisTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      final controller = _controller;
      if (!mounted || controller == null || !controller.value.isInitialized) {
        return;
      }

      final status = ref.read(scannerNotifierProvider).status;
      if (status == ScannerStatus.processing ||
          status == ScannerStatus.capturing) {
        return;
      }

      await nativeVision.measureImageQuality('preview-frame');
    });
  }

  Future<void> _captureCard() async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isTakingPicture) {
      return;
    }

    try {
      final picture = await controller.takePicture();
      if (!mounted) {
        return;
      }
      await widget.onCaptureRequested(picture.path);
    } catch (_) {
      widget.onStatusChanged(
        'Capture failed',
        status: ScannerStatus.error,
      );
    }
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
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
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
