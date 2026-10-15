import 'package:dio/dio.dart';

import '../../container_injector.dart';
import '../api/interceptors.dart';
import '../utils/app_constants.dart';
import 'resumable_download.dart';

const String _apiKey = String.fromEnvironment('RAPIDAPI_KEY');
const String _apiHost = String.fromEnvironment(
  'RAPIDAPI_HOST',
  defaultValue: "tiktok-download-without-watermark.p.rapidapi.com",
);

class DioHelper {
  final Dio dio;

  /// Cliente sin las cabeceras del servicio, para bajar los archivos de los
  /// servidores de video: esos no deben recibir ninguna clave.
  final Dio _fileDio = Dio();

  /// Cabeceras para el servicio de análisis. Solo se envían las de RapidAPI
  /// cuando se compila con una clave; el servicio público no las necesita.
  static Map<String, dynamic> serviceHeaders({String apiKey = _apiKey}) => {
    "Content-Type": "application/json",
    if (apiKey.isNotEmpty) ...{
      "X-RapidAPI-Key": apiKey,
      "X-RapidAPI-Host": _apiHost,
    },
  };

  DioHelper({required this.dio}) {
    final headers = serviceHeaders();
    dio.options = BaseOptions(
      baseUrl: AppConstants.baseUrl,
      receiveDataWhenStatusError: true,
      headers: headers,
    );
    dio.interceptors.add(sl<LogInterceptor>());
    dio.interceptors.add(sl<AppInterceptors>());
  }

  Future<Response> get({
    required String path,
    Map<String, dynamic>? queryParams,
  }) async {
    return await dio.get(path, queryParameters: queryParams);
  }

  /// Tamaño en bytes que informa el servidor, o nulo si no lo dice.
  Future<int?> contentLength(String url) async {
    final response = await _fileDio.head(url);
    return int.tryParse(
      response.headers.value(Headers.contentLengthHeader) ?? '',
    );
  }

  late final ResumableDownload _resumable = ResumableDownload(_fileDio);

  /// Baja [downloadLink] a [savePath]. Si un intento anterior se cortó,
  /// continúa desde donde quedó (ver [ResumableDownload]).
  Future<void> download({
    required String downloadLink,
    required String savePath,
    ProgressCallback? onReceiveProgress,
    CancelToken? cancelToken,
  }) {
    return _resumable.run(
      url: downloadLink,
      savePath: savePath,
      onProgress: onReceiveProgress,
      cancelToken: cancelToken,
    );
  }
}
