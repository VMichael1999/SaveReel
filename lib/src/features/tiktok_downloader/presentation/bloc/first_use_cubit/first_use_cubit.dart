import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/helpers/onboarding_store.dart';

/// Si la guía de primer uso ya se descartó. Hasta que se lee del
/// almacenamiento no se sabe, y la guía no debe parpadear antes de tiempo.
class FirstUseState extends Equatable {
  const FirstUseState({this.loaded = false, this.dismissed = false});

  final bool loaded;
  final bool dismissed;

  @override
  List<Object?> get props => [loaded, dismissed];
}

class FirstUseCubit extends Cubit<FirstUseState> {
  FirstUseCubit({required this.store}) : super(const FirstUseState());

  final OnboardingStore store;

  Future<void> load() async {
    final dismissed = await store.isDismissed();
    if (!isClosed) emit(FirstUseState(loaded: true, dismissed: dismissed));
  }

  Future<void> dismiss() async {
    emit(const FirstUseState(loaded: true, dismissed: true));
    await store.dismiss();
  }
}
