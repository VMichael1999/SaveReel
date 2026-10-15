/// Claves de `localization/*.json` con el mensaje de cada falla. Se traducen
/// al mostrarlas (`context.strings.translate`), así el idioma que se ve es el
/// de ese momento y no el que había cuando ocurrió el error.
class Authorized {
  static const String badRequest = 'errBadRequest';
  static const String unauthorized = 'errUnauthorized';
  static const String forbidden = 'errForbidden';
  static const String notFound = 'errNotFound';
  static const String internalServerError = 'errServer';

  // local status code
  static const String connectTimeOut = 'errTimeout';
  static const String cancel = 'errCancel';
  static const String noInternetConnection = 'errNoInternet';
  static const String unexpected = 'errUnexpected';

  static const String tooManyRequests = 'errTooManyRequests';
  static const String notSubscribed = 'errNotSubscribed';
}
