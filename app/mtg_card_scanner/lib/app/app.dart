// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter/material.dart';
import '../features/card_scanner/presentation/widgets/scanner_flow_listener.dart';
import 'routes.dart';

class MtgCardScannerApp extends StatelessWidget {
  const MtgCardScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MTG Card Scanner',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2C6E49),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF101418),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.camera,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      builder: (context, child) {
        if (child == null) {
          return const SizedBox.shrink();
        }
        return ScannerFlowListener(child: child);
      },
    );
  }
}
