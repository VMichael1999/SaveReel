/// Tipo de aviso: define el ícono, el color y cuánto dura en pantalla.
enum MessageType {
  /// Algo salió bien: descarga lista, guardado en la galería.
  success,

  /// Algo falló y el usuario debe saberlo.
  error,

  /// Un dato neutro: descarga cancelada, video eliminado.
  info,
}

enum DownloadStatus { downloading, success, error }
