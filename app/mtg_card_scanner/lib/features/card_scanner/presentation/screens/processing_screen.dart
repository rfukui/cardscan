// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/routes.dart';
import '../../domain/value_objects/scanner_status.dart';
import '../providers/providers.dart';
import '../providers/scanner_state.dart';

class ProcessingScreen extends ConsumerStatefulWidget {
  const ProcessingScreen({super.key});

  @override
  ConsumerState<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends ConsumerState<ProcessingScreen> {
  bool _errorSnackVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final state = ref.read(scannerNotifierProvider);
      _handleInitialState(state);
    });
  }

  void _handleInitialState(ScannerState state) {
    if (state.status == ScannerStatus.result && state.recognitionResult != null) {
      _goToNextScreen(state);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ScannerState>(scannerNotifierProvider, (previous, next) {
      if (next.status == ScannerStatus.result && next.recognitionResult != null) {
        _goToNextScreen(next);
      } else if (next.status == ScannerStatus.error && !_errorSnackVisible) {
        _errorSnackVisible = true;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(next.message)))
            .closed
            .then((_) {
          _errorSnackVisible = false;
        });
      }
    });

    final state = ref.watch(scannerNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Processing')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (state.capturedImagePath != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    File(state.capturedImagePath!),
                    height: 180,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 20),
              ],
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                'Identifying card locally',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                state.message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
              if (state.status == ScannerStatus.error) ...[
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    _errorSnackVisible = false;
                    ref.invalidate(scannerNotifierProvider);
                    Navigator.of(context).popUntil(
                      (route) => route.settings.name == AppRoutes.camera || route.isFirst,
                    );
                  },
                  child: const Text('Try again'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _goToNextScreen(ScannerState state) {
    final route = state.recognitionResult!.requiresManualSelection
        ? AppRoutes.candidateSelection
        : AppRoutes.result;
    Navigator.of(context).pushReplacementNamed(route);
  }
}
