// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/route_args.dart';
import '../../domain/entities/magic_card.dart';
import '../providers/providers.dart';

class CardResultScreen extends ConsumerWidget {
  final CardResultRouteArgs? args;

  const CardResultScreen({super.key, this.args});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (args?.cardId != null) {
      final cardAsync = ref.watch(cardByIdProvider(args!.cardId!));
      return cardAsync.when(
        data: (card) => _ResultScaffold(
          card: card,
          imagePath: args?.imagePath,
          selectedManually: args?.selectedManually ?? false,
        ),
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (_, __) => const Scaffold(
            body: Center(child: Text('Unable to load card result'))),
      );
    }

    final state = ref.watch(scannerNotifierProvider);

    return _ResultScaffold(
      card: state.resolvedCard,
      imagePath: state.capturedImagePath,
      selectedManually: state.selectedManually,
    );
  }
}

class _ResultScaffold extends ConsumerWidget {
  final MagicCard? card;
  final String? imagePath;
  final bool selectedManually;

  const _ResultScaffold({
    required this.card,
    required this.imagePath,
    required this.selectedManually,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveCandidates =
        ref.watch(scannerNotifierProvider).recognitionResult?.candidates ??
            const [];

    return Scaffold(
      appBar: AppBar(title: const Text('Card Result')),
      body: card == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('No card match available'),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        ref
                            .read(scannerNotifierProvider.notifier)
                            .restartScanFlow();
                      },
                      child: const Text('Back to camera'),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (imagePath != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.file(
                        File(imagePath!),
                        height: 220,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(card!.name,
                              style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 8),
                          if (selectedManually)
                            Text(
                              'Selected manually',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.amberAccent),
                            ),
                          const SizedBox(height: 12),
                          _FieldRow(label: 'Set code', value: card!.setCode),
                          _FieldRow(label: 'Set name', value: card!.setName),
                          _FieldRow(
                              label: 'Collector number',
                              value: card!.collectorNumber),
                          _FieldRow(label: 'Mana cost', value: card!.manaCost),
                          _FieldRow(label: 'Type line', value: card!.typeLine),
                          _FieldRow(
                              label: 'Oracle text', value: card!.oracleText),
                          _FieldRow(label: 'Rarity', value: card!.rarity),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      ref
                          .read(scannerNotifierProvider.notifier)
                          .restartScanFlow();
                    },
                    child: const Text('Scan another card'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: liveCandidates.length > 1
                        ? ref
                            .read(scannerNotifierProvider.notifier)
                            .reopenCandidateSelection
                        : null,
                    child: const Text('Not this card'),
                  ),
                ],
              ),
            ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  final String label;
  final String? value;

  const _FieldRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: Colors.white70)),
          const SizedBox(height: 2),
          Text(value?.isNotEmpty == true ? value! : '-',
              style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
