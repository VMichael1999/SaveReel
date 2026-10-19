import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/layout/duo_context.dart';
import '../../../../core/layout/duo_layout.dart';
import '../../../../core/utils/app_strings.dart';
import '../bloc/duo_pane_cubit/duo_pane_cubit.dart';
import '../widgets/downloads_screen/downloads_screen_body.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  bool _handedOver = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Con el teléfono abierto, las descargas viven en la mitad derecha del
    // inicio: esta pantalla se cierra y le pasa el relevo.
    if (_handedOver || context.duoLayout != DuoLayout.openLandscape) return;
    _handedOver = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<DuoPaneCubit>().showDownloads();
      Navigator.of(context).maybePop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.strings.downloads)),
      body: const DownloadsScreenBody(),
    );
  }
}
