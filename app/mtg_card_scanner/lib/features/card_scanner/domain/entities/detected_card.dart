// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:ui';

class DetectedCard {
  final List<Offset> corners;
  final Rect? boundingBox;
  final double aspectRatioScore;
  final bool isStable;

  const DetectedCard({
    required this.corners,
    this.boundingBox,
    required this.aspectRatioScore,
    required this.isStable,
  });
}
