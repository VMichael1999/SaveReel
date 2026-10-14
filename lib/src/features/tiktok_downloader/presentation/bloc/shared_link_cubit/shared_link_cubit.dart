import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/helpers/shared_link_receiver.dart';

/// El enlace que llegó desde «Compartir» y aún no se usó. `serial` distingue
/// dos veces el mismo enlace.
class SharedLinkState extends Equatable {
  const SharedLinkState({this.pending, this.serial = 0});

  final String? pending;
  final int serial;

  @override
  List<Object?> get props => [pending, serial];
}

class SharedLinkCubit extends Cubit<SharedLinkState> {
  SharedLinkCubit({required this.receiver}) : super(const SharedLinkState());

  final SharedLinkReceiver receiver;
  StreamSubscription<String>? _subscription;

  /// Escucha lo compartido: lo que abrió la app y lo que llega después.
  Future<void> start() async {
    _subscription = receiver.links.listen(_receive);
    final initial = await receiver.initialLink();
    if (initial != null) _receive(initial);
  }

  void _receive(String link) {
    if (isClosed) return;
    emit(SharedLinkState(pending: link, serial: state.serial + 1));
  }

  /// Marca el enlace como usado, para que no se vuelva a aplicar.
  String? consume() {
    final link = state.pending;
    if (link != null) emit(SharedLinkState(serial: state.serial));
    return link;
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
