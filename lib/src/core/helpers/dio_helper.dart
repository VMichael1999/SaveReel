import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../container_injector.dart';
import '../api/interceptors.dart';
import '../utils/app_constants.dart';

const String _contentType = "Content-Type";
const String _applicationJson = "application/json";
const String _apiKey = String.fromEnvironment('RAPIDAPI_KEY');
const String _apiHost = "tiktok-download-without-watermark.p.rapidapi.com";

class DioHelper {
  final Dio dio;

  /// Cliente sin las cabeceras de RapidAPI, para bajar los archivos de los
  /// servidores de video: esos no deben recibir la clave.
  final Dio _fileDio = Dio();

  DioHelper({required this.dio}) {
    if (kDebugMode && _apiKey.isEmpty) {
      debugPrint(
        'AVISO: falta RAPIDAPI_KEY. Sin ella el servicio responde 401. '
        'Ejecuta con --dart-define-from-file=env.json (ver env.example.json).',
      );
    }
    Map<String, dynamic> headers = {
      _contentType: _applicationJson,
      "X-RapidAPI-Key": _apiKey,
      "X-RapidAPI-Host": _apiHost,
    };
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

  Future<Response> download({
    required String downloadLink,
    required String savePath,
    Map<String, dynamic>? queryParams,
    ProgressCallback? onReceiveProgress,
    CancelToken? cancelToken,
  }) async {
    return await _fileDio.download(
      downloadLink,
      savePath,
      onReceiveProgress: onReceiveProgress,
      cancelToken: cancelToken,
    );
  }
}
