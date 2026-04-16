// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/routes.dart';
import '../providers/providers.dart';
import '../providers/scanner_route_target.dart';

class ScannerFlowListener extends ConsumerStatefulWidget {
  const ScannerFlowListener({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  ConsumerState<ScannerFlowListener> createState() =>
      _ScannerFlowListenerState();
}

class _ScannerFlowListenerState extends ConsumerState<ScannerFlowListener> {
  @override
  Widget build(BuildContext context) {
    ref.listen<ScannerRouteTarget?>(
      scannerNotifierProvider.select((state) => state.pendingRoute),
      (previous, next) {
        if (next == null) {
          return;
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          _navigate(next);
          ref.read(scannerNotifierProvider.notifier).consumePendingRoute();
        });
      },
    );

    return widget.child;
  }

  void _navigate(ScannerRouteTarget target) {
    final navigator = Navigator.of(context);
    switch (target) {
      case ScannerRouteTarget.camera:
        navigator.pushNamedAndRemoveUntil(AppRoutes.camera, (route) => false);
        return;
      case ScannerRouteTarget.processing:
        navigator.pushNamed(AppRoutes.processing);
        return;
      case ScannerRouteTarget.result:
        navigator.pushReplacementNamed(AppRoutes.result);
        return;
      case ScannerRouteTarget.candidateSelection:
        navigator.pushReplacementNamed(AppRoutes.candidateSelection);
        return;
    }
  }
}
