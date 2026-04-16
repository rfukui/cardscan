// SPDX-License-Identifier: GPL-3.0-or-later

class ImageQualityMetrics {
  final double blurScore;
  final double brightnessScore;
  final double glareScore;
  final bool isAcceptable;

  const ImageQualityMetrics({
    required this.blurScore,
    required this.brightnessScore,
    required this.glareScore,
    required this.isAcceptable,
  });
}
