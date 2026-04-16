// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/routes.dart';
import '../providers/providers.dart';

class CandidateSelectionScreen extends ConsumerWidget {
  const CandidateSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scannerNotifierProvider);
    final candidates = state.recognitionResult?.candidates ?? const [];

    return Scaffold(
      appBar: AppBar(title: const Text('Select Card')),
      body: candidates.isEmpty
          ? Center(
              child: FilledButton(
                onPressed: () {
                  ref.read(scannerNotifierProvider.notifier).reset();
                  Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.camera, (route) => false);
                },
                child: const Text('Back to camera'),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: candidates.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final candidate = candidates[index];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: candidate.card.imageThumbPath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(candidate.card.imageThumbPath!),
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const SizedBox(
                            width: 48,
                            height: 48,
                            child: Icon(Icons.style),
                          ),
                    title: Text(candidate.card.name),
                    subtitle: Text(
                      '${candidate.card.setCode ?? '-'} • ${candidate.card.collectorNumber ?? '-'}',
                    ),
                    trailing: Text(candidate.finalScore.toStringAsFixed(2)),
                    onTap: () async {
                      await ref.read(scannerNotifierProvider.notifier).selectCandidate(candidate);
                      Navigator.of(context).pushReplacementNamed(AppRoutes.result);
                    },
                  ),
                );
              },
            ),
    );
  }
}
