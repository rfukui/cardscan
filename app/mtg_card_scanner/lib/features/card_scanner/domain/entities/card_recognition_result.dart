// SPDX-License-Identifier: GPL-3.0-or-later

import 'card_candidate.dart';
import 'magic_card.dart';

class CardRecognitionResult {
  final MagicCard? bestMatch;
  final List<CardCandidate> candidates;
  final bool requiresManualSelection;

  const CardRecognitionResult({
    this.bestMatch,
    required this.candidates,
    required this.requiresManualSelection,
  });
}
