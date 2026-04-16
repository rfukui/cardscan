// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter/services.dart';
import '../../../../core/channels/native_vision_channel.dart';
import '../../domain/entities/detected_card.dart';
import '../../domain/entities/image_quality_metrics.dart';

class NativeVisionService {
  Future<DetectedCard?> detectCard(String imagePath) async {
    try {
      final result = await NativeVisionChannel.channel.invokeMapMethod<String, dynamic>(
        'detectCard',
        {'imagePath': imagePath},
      );
      if (result == null) {
        return null;
      }
      final corners = (result['corners'] as List<dynamic>?) ?? <dynamic>[];
      return DetectedCard(
        corners: corners.map<Offset>((item) {
          final map = item as Map<dynamic, dynamic>;
          return map.containsKey('x') && map.containsKey('y')
              ? Offset((map['x'] as num).toDouble(), (map['y'] as num).toDouble())
              : Offset.zero;
        }).toList(),
        boundingBox: null,
        aspectRatioScore: (result['aspectRatioScore'] as num?)?.toDouble() ?? 1.0,
        isStable: (result['isStable'] as bool?) ?? true,
      );
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  Future<String> rectifyCard(String imagePath) async {
    try {
      final result = await NativeVisionChannel.channel.invokeMethod<String>(
        'rectifyCard',
        {'imagePath': imagePath},
      );
      return result ?? imagePath;
    } on MissingPluginException {
      return imagePath;
    } on PlatformException {
      return imagePath;
    }
  }

  Future<List<String>> extractRegions(String imagePath) async {
    try {
      final result = await NativeVisionChannel.channel.invokeListMethod<String>(
        'extractRegions',
        {'imagePath': imagePath},
      );
      return result ?? [imagePath];
    } on MissingPluginException {
      return [imagePath];
    } on PlatformException {
      return [imagePath];
    }
  }

  Future<ImageQualityMetrics> measureImageQuality(String imagePath) async {
    try {
      final result = await NativeVisionChannel.channel.invokeMapMethod<String, dynamic>(
        'measureImageQuality',
        {'imagePath': imagePath},
      );
      return ImageQualityMetrics(
        blurScore: (result?['blurScore'] as num?)?.toDouble() ?? 0.2,
        brightnessScore: (result?['brightnessScore'] as num?)?.toDouble() ?? 0.5,
        glareScore: (result?['glareScore'] as num?)?.toDouble() ?? 0.2,
        isAcceptable: (result?['isAcceptable'] as bool?) ?? true,
      );
    } on MissingPluginException {
      return ImageQualityMetrics(
        blurScore: 0.2,
        brightnessScore: 0.5,
        glareScore: 0.2,
        isAcceptable: true,
      );
    } on PlatformException {
      return ImageQualityMetrics(
        blurScore: 0.2,
        brightnessScore: 0.5,
        glareScore: 0.2,
        isAcceptable: true,
      );
    }
  }
}
