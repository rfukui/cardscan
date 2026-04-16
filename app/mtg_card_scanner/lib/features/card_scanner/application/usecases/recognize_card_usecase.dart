// SPDX-License-Identifier: GPL-3.0-or-later

import '../../domain/entities/card_recognition_result.dart';
import '../services/recognition_pipeline_service.dart';

class RecognizeCardUseCase {
  final RecognitionPipelineService pipeline;

  RecognizeCardUseCase(this.pipeline);

  Future<CardRecognitionResult> execute(String imagePath) async {
    return pipeline.recognize(imagePath);
  }
}
