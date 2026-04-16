// SPDX-License-Identifier: GPL-3.0-or-later

import 'magic_card.dart';

class CardCandidate {
  final MagicCard card;
  final double nameScore;
  final double collectorScore;
  final double setScore;
  final double finalScore;

  const CardCandidate({
    required this.card,
    required this.nameScore,
    required this.collectorScore,
    required this.setScore,
    required this.finalScore,
  });
}
