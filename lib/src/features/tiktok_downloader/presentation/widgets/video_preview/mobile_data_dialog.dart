import 'package:flutter/material.dart';

import '../../../../../core/helpers/network_info.dart';
import '../../../../../core/utils/app_strings.dart';
import '../../../../../core/utils/formatters.dart';
import '../../models/app_settings.dart';

/// Antes de descargar, avisa si se va a gastar datos móviles según la
/// preferencia del usuario. Devuelve `true` si la descarga puede seguir.
Future<bool> confirmMobileData(
  BuildContext context, {
  required MobileDataPolicy policy,
  required int? bytes,
}) async {
  // Con «permitir siempre» ni se consulta la red.
  if (policy == MobileDataPolicy.allow) return true;
  final metered = await NetworkInfo.isMetered();
  if (!policy.needsConfirmation(metered: metered, bytes: bytes)) return true;
  if (!context.mounted) return false;

  final size = bytes == null ? null : formatMegabytes(bytes);
  final body =
      policy == MobileDataPolicy.wifiOnly
          ? context.strings.mobileDataBodyWifiOnly
          : context.strings.mobileDataBodyHeavy(size!);
  final confirmed = await showDialog<bool>(
    context: context,
    builder:
        (context) => AlertDialog(
          title: Text(context.strings.mobileDataTitle),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(context.strings.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(context.strings.downloadAnyway),
            ),
          ],
        ),
  );
  return confirmed ?? false;
}
