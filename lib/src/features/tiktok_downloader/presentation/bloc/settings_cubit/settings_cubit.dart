import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/helpers/settings_store.dart';
import '../../models/app_settings.dart';
import '../../models/download_format.dart';

/// Los ajustes de la app. Cada cambio se aplica al momento y se guarda.
class SettingsCubit extends Cubit<AppSettings> {
  SettingsCubit({required this.store}) : super(const AppSettings());

  final SettingsStore store;

  Future<void> load() async {
    final saved = AppSettings.fromJson(await store.read());
    if (!isClosed) emit(saved);
  }

  Future<void> setDefaultFormat(DownloadFormat format) =>
      _apply(state.copyWith(defaultFormat: format));

  Future<void> setSaveToGallery(bool value) =>
      _apply(state.copyWith(saveToGallery: value));

  Future<void> setTheme(AppThemeChoice theme) =>
      _apply(state.copyWith(theme: theme));

  Future<void> setMobileData(MobileDataPolicy policy) =>
      _apply(state.copyWith(mobileData: policy));

  Future<void> _apply(AppSettings next) async {
    emit(next);
    await store.write(next.toJson());
  }
}
