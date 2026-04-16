// SPDX-License-Identifier: GPL-3.0-or-later

class AppException implements Exception {
  final String message;
  AppException(this.message);

  @override
  String toString() => 'AppException: $message';
}
