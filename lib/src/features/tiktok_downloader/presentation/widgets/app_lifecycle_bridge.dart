import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/downloader_bloc/downloader_bloc.dart';

/// Avisa a las descargas cuando la app pasa a segundo plano y cuando vuelve,
/// para que retomen solas si el sistema les cortó la conexión.
class AppLifecycleBridge extends StatefulWidget {
  const AppLifecycleBridge({super.key, required this.child});

  final Widget child;

  @override
  State<AppLifecycleBridge> createState() => _AppLifecycleBridgeState();
}

class _AppLifecycleBridgeState extends State<AppLifecycleBridge> {
  late final AppLifecycleListener _listener;

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(onStateChange: _onChanged);
  }

  void _onChanged(AppLifecycleState state) {
    context.read<DownloaderBloc>().add(
      DownloaderAppLifecycleChanged(away: state != AppLifecycleState.resumed),
    );
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
