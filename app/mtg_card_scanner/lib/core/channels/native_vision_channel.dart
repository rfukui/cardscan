// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter/services.dart';
import '../constants/app_constants.dart';

class NativeVisionChannel {
  static final MethodChannel channel = MethodChannel(AppConstants.nativeVisionChannel);
}
