import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/helpers/shared_link_receiver.dart';

/// El enlace que llegó desde «Compartir» y aún no se usó. `serial` distingue
/// dos veces el mismo enlace.
class SharedLinkState extends Equatable {
  const SharedLinkState({
    this.pending,
    this.serial = 0,
    this.missingSerial = 0,
  });

  final String? pending;
  final int serial;

  /// Cuenta las veces que se pidió usar el enlace copiado y no había ninguno.
  final int missingSerial;

  @override
  List<Object?> get props => [pending, serial, missingSerial];
}

class SharedLinkCubit extends Cubit<SharedLinkState> {
  SharedLinkCubit({required this.receiver}) : super(const SharedLinkState());

  final SharedLinkReceiver receiver;
  StreamSubscription<String>? _subscription;
  StreamSubscription<void>? _missingSubscription;

  /// Escucha lo compartido: lo que abrió la app y lo que llega después.
  Future<void> start() async {
    _subscription = receiver.links.listen(_receive);
    _missingSubscription = receiver.missingLinks.listen((_) => _missing());
    final initial = await receiver.initialLink();
    if (initial != null) _receive(initial);
  }

  void _receive(String link) {
    if (isClosed) return;
    emit(
      SharedLinkState(
        pending: link,
        serial: state.serial + 1,
        missingSerial: state.missingSerial,
      ),
    );
  }

  void _missing() {
    if (isClosed) return;
    emit(
      SharedLinkState(
        pending: state.pending,
        serial: state.serial,
        missingSerial: state.missingSerial + 1,
      ),
    );
  }

  /// Marca el enlace como usado, para que no se vuelva a aplicar.
  String? consume() {
    final link = state.pending;
    if (link != null) {
      emit(
        SharedLinkState(
          serial: state.serial,
          missingSerial: state.missingSerial,
        ),
      );
    }
    return link;
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    await _missingSubscription?.cancel();
    return super.close();
  }
}
