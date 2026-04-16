// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/route_args.dart';
import '../../../../app/routes.dart';
import '../../../card_scanner/presentation/providers/providers.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyEntriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Scan History')),
      body: historyAsync.when(
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(child: Text('No scans yet'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(historyEntriesProvider);
              await ref.read(historyEntriesProvider.future);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: entries.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final entry = entries[index];
                final formattedDate =
                    '${entry.scannedAt.day.toString().padLeft(2, '0')}/'
                    '${entry.scannedAt.month.toString().padLeft(2, '0')}/'
                    '${entry.scannedAt.year} '
                    '${entry.scannedAt.hour.toString().padLeft(2, '0')}:'
                    '${entry.scannedAt.minute.toString().padLeft(2, '0')}';
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  title: Text(entry.cardName),
                  subtitle: Text(formattedDate),
                  trailing: entry.selectedManually ? const Icon(Icons.touch_app) : null,
                  onTap: entry.cardId == null
                      ? null
                      : () {
                          Navigator.of(context).pushNamed(
                            AppRoutes.result,
                            arguments: CardResultRouteArgs(
                              cardId: entry.cardId,
                              imagePath: entry.imagePath,
                              selectedManually: entry.selectedManually,
                            ),
                          );
                        },
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: FilledButton(
            onPressed: () => ref.invalidate(historyEntriesProvider),
            child: const Text('Retry'),
          ),
        ),
      ),
    );
  }
}
