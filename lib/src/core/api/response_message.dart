class Authorized {
  static const String badRequest =
      "No pudimos procesar ese enlace. Revisa que sea de un video de TikTok o Instagram.";
  static const String unauthorized =
      "No tienes autorización para esta acción. Inténtalo más tarde.";
  static const String forbidden =
      "El servicio rechazó la solicitud. Inténtalo más tarde.";
  static const String notFound =
      "No encontramos ese video. Puede ser privado o haber sido borrado.";
  static const String internalServerError =
      "El servicio tuvo un problema. Inténtalo de nuevo en un rato.";

  // local status code
  static const String connectTimeOut =
      "La conexión tardó demasiado. Revisa tu internet e inténtalo de nuevo.";
  static const String cancel = "Se canceló la solicitud.";
  static const String noInternetConnection =
      "Sin conexión. Revisa tu internet e inténtalo de nuevo.";
  static const String unexpected = "Algo salió mal. Inténtalo de nuevo.";

  static const String tooManyRequests =
      "Se alcanzó el límite de descargas de hoy. Inténtalo mañana.";
  static const String notSubscribed =
      "El servicio no está disponible por ahora. Inténtalo más tarde.";
}
