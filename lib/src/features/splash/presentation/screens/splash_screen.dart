import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../config/routes_manager.dart';
import '../../../../config/theme/app_tokens.dart';
import '../../../../core/utils/app_constants.dart';
import '../../../../core/widgets/savetic_mark.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(
      const Duration(milliseconds: AppConstants.navigateTime),
      _goToDownloader,
    );
  }

  void _goToDownloader() {
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(Routes.downloader, (route) => false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final mark = SaveticMark(
      size: 88,
      color: Theme.of(context).colorScheme.primary,
    );

    return Scaffold(
      body: Center(
        child:
            reduceMotion
                ? mark
                : mark
                    .animate()
                    .fadeIn(duration: AppMotion.slow, curve: AppMotion.standard)
                    .scale(
                      begin: const Offset(0.92, 0.92),
                      duration: AppMotion.slow,
                      curve: AppMotion.emphasized,
                    ),
      ),
    );
  }
}
