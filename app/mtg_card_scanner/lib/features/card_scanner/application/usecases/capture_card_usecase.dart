// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class CaptureCardUseCase {
  Future<String> saveCapturedImage(List<int> bytes, String prefix) async {
    final dir = await getTemporaryDirectory();
    final file = File(p.join(
        dir.path, '$prefix-${DateTime.now().millisecondsSinceEpoch}.jpg'));
    await file.writeAsBytes(bytes);
    return file.path;
  }
}
