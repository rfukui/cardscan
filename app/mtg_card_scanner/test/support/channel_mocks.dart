// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mtg_card_scanner/core/channels/native_vision_channel.dart';

const _textRecognizerChannel = MethodChannel('google_mlkit_text_recognizer');

Future<void> mockNativeVisionChannel({
  String rectifiedPath = 'rectified.jpg',
}) async {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    NativeVisionChannel.channel,
    (call) async {
      switch (call.method) {
        case 'rectifyCard':
          return rectifiedPath;
        case 'detectCard':
          return null;
        case 'extractRegions':
          return <String>[rectifiedPath];
        case 'measureImageQuality':
          return <String, dynamic>{
            'blurScore': 0.1,
            'brightnessScore': 0.6,
            'glareScore': 0.1,
            'isAcceptable': true,
          };
      }
      return null;
    },
  );
}

Future<void> mockTextRecognizerChannel({
  required Map<int, List<Map<String, dynamic>>> scriptLines,
}) async {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    _textRecognizerChannel,
    (call) async {
      if (call.method == 'vision#closeTextRecognizer') {
        return null;
      }

      final script = (call.arguments as Map<dynamic, dynamic>)['script'] as int;
      final lines = scriptLines[script] ?? const <Map<String, dynamic>>[];
      return <String, dynamic>{
        'text': lines.map((line) => line['text']).join('\n'),
        'blocks': [
          {
            'text': lines.map((line) => line['text']).join('\n'),
            'rect': {'left': 0, 'top': 0, 'right': 400, 'bottom': 600},
            'recognizedLanguages': const <String>[],
            'points': const <Map<String, int>>[],
            'lines': lines,
          },
        ],
      };
    },
  );
}

Future<void> clearTestChannels() async {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(_textRecognizerChannel, null);
  messenger.setMockMethodCallHandler(NativeVisionChannel.channel, null);
}

Map<String, dynamic> makeTextLine({
  required String text,
  required int top,
  int bottom = 40,
}) {
  return {
    'text': text,
    'rect': {
      'left': 0,
      'top': top,
      'right': 300,
      'bottom': top + bottom,
    },
    'recognizedLanguages': const <String>[],
    'points': const <Map<String, int>>[],
    'elements': const <Map<String, dynamic>>[],
    'confidence': 0.99,
    'angle': 0.0,
  };
}
