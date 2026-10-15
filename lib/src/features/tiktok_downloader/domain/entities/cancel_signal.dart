/// Señal para cancelar una descarga en curso. Mantiene la capa de dominio
/// libre de `dio`: la fuente de datos la traduce a su propio mecanismo.
class CancelSignal {
  bool _cancelled = false;
  final List<void Function()> _listeners = [];

  bool get isCancelled => _cancelled;

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    for (final listener in _listeners) {
      listener();
    }
    _listeners.clear();
  }

  /// Llama a [listener] al cancelar, o de inmediato si ya se canceló.
  void onCancel(void Function() listener) {
    if (_cancelled) {
      listener();
    } else {
      _listeners.add(listener);
    }
  }
}
