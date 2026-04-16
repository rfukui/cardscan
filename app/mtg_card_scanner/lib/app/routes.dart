// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter/material.dart';
import 'route_args.dart';
import '../features/card_scanner/presentation/screens/camera_screen.dart';
import '../features/card_scanner/presentation/screens/processing_screen.dart';
import '../features/card_scanner/presentation/screens/card_result_screen.dart';
import '../features/card_scanner/presentation/screens/candidate_selection_screen.dart';
import '../features/history/presentation/screens/history_screen.dart';

class AppRoutes {
  static const camera = '/';
  static const processing = '/processing';
  static const result = '/result';
  static const candidateSelection = '/candidate_selection';
  static const history = '/history';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case camera:
        return MaterialPageRoute<void>(
          builder: (_) => const CameraScreen(),
          settings: settings,
        );
      case processing:
        return MaterialPageRoute<void>(
          builder: (_) => const ProcessingScreen(),
          settings: settings,
        );
      case result:
        final args = settings.arguments as CardResultRouteArgs?;
        return MaterialPageRoute<void>(
          builder: (_) => CardResultScreen(args: args),
          settings: settings,
        );
      case candidateSelection:
        return MaterialPageRoute<void>(
          builder: (_) => const CandidateSelectionScreen(),
          settings: settings,
        );
      case history:
        return MaterialPageRoute<void>(
          builder: (_) => const HistoryScreen(),
          settings: settings,
        );
      default:
        return MaterialPageRoute<void>(
          builder: (_) => const CameraScreen(),
          settings: settings,
        );
    }
  }
}
