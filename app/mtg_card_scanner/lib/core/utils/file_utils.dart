// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:io';

Future<String> ensureTempFilePath(String fileName) async {
  final directory = Directory.systemTemp;
  final filePath = '${directory.path}/$fileName';
  return filePath;
}
