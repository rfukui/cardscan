// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/value_objects/scanner_status.dart';
import '../providers/providers.dart';

class ProcessingScreen extends ConsumerWidget {
  const ProcessingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              if (state.status == ScannerStatus.error)
                const Icon(Icons.error_outline,
                    size: 42, color: Colors.orangeAccent)
              else
                const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                state.status == ScannerStatus.error
                    ? 'Card identification failed'
                    : 'Identifying card locally',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                state.message,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.white70),
              ),
              if (state.status == ScannerStatus.error) ...[
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: ref
                      .read(scannerNotifierProvider.notifier)
                      .restartScanFlow,
                  child: const Text('Try again'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
