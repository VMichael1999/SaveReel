import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savetic/src/config/theme/app_theme.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/bloc/library_cubit/library_cubit.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/bloc/locale_cubit/locale_cubit.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/bloc/settings_cubit/settings_cubit.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/screens/settings_screen.dart';
import 'package:savetic/src/localization/app_texts.dart';

import '../support/fake_library.dart';

void main() {
  tearDown(() => AppTexts.active = AppLanguages.fallback);

  testWidgets('elegir English en Ajustes cambia la pantalla y se guarda', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final store = MemoryLanguageStore();
    final locale = LocaleCubit(
      store: store,
      deviceLocale: () => const Locale('es'),
    );
    await locale.load();
    final library = fakeLibraryCubit(FakeSavedVideosRepo());
    await library.load();

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<LibraryCubit>.value(value: library),
          BlocProvider<SettingsCubit>.value(value: fakeSettingsCubit()),
          BlocProvider<LocaleCubit>.value(value: locale),
        ],
        child: BlocBuilder<LocaleCubit, Locale>(
          builder:
              (context, current) => AppLocaleScope(
                code: current.languageCode,
                child: MaterialApp(
                  theme: AppTheme.dark,
                  locale: current,
                  home: const SettingsScreen(),
                ),
              ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Ajustes'), findsOneWidget);

    await tester.tap(find.text('Idioma'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Ajustes'), findsNothing);
    expect(store.saved, 'en');
  });
}
