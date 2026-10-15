import 'dart:io';

import 'package:dio/dio.dart';

/// Baja un archivo a `<destino>.part` y lo renombra al terminar. Si un
/// intento anterior se cortó y dejó su `.part`, pide al servidor solo lo que
/// falta (cabecera `Range`) en lugar de empezar de cero.
class ResumableDownload {
  ResumableDownload(this._dio);

  final Dio _dio;

  /// Archivo temporal de un destino: existe mientras la descarga está a medias.
  static String partPathOf(String savePath) => '$savePath.part';

  /// Bytes ya guardados de un intento anterior de [savePath], o 0.
  static Future<int> savedBytes(String savePath) async {
    final part = File(partPathOf(savePath));
    return await part.exists() ? part.length() : 0;
  }

  /// Borra lo que quedó a medias de [savePath].
  static Future<void> discard(String savePath) async {
    final part = File(partPathOf(savePath));
    if (await part.exists()) await part.delete();
  }

  Future<void> run({
    required String url,
    required String savePath,
    ProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) async {
    final part = File(partPathOf(savePath));
    var start = await savedBytes(savePath);

    Response<ResponseBody> response;
    try {
      response = await _request(url, start, cancelToken);
    } on DioException catch (error) {
      // 416: el rango no vale (el archivo cambió o ya estaba completo).
      if (start > 0 && error.response?.statusCode == 416) {
        await part.delete();
        start = 0;
        response = await _request(url, 0, cancelToken);
      } else {
        rethrow;
      }
    }

    // Si el servidor ignoró el rango y mandó todo (200), se empieza de cero.
    final resumed = start > 0 && response.statusCode == 206;
    if (!resumed) start = 0;
    final total = _totalOf(response, start);

    final sink = part.openWrite(
      mode: resumed ? FileMode.append : FileMode.write,
    );
    var received = start;
    try {
      await for (final chunk in response.data!.stream) {
        sink.add(chunk);
        received += chunk.length;
        onProgress?.call(received, total);
      }
    } on DioException {
      await sink.close();
      rethrow;
    } catch (error) {
      await sink.close();
      throw DioException(
        requestOptions: response.requestOptions,
        error: error,
        type: DioExceptionType.connectionError,
      );
    }
    await sink.flush();
    await sink.close();

    if (total > 0 && received < total) {
      throw DioException(
        requestOptions: response.requestOptions,
        type: DioExceptionType.connectionError,
        error: 'La descarga llegó incompleta',
      );
    }
    await part.rename(savePath);
  }

  Future<Response<ResponseBody>> _request(
    String url,
    int start,
    CancelToken? cancelToken,
  ) {
    return _dio.get<ResponseBody>(
      url,
      cancelToken: cancelToken,
      options: Options(
        responseType: ResponseType.stream,
        headers: {
          // Sin compresión, para que los tamaños coincidan con los bytes.
          HttpHeaders.acceptEncodingHeader: 'identity',
          if (start > 0) HttpHeaders.rangeHeader: 'bytes=$start-',
        },
      ),
    );
  }

  /// Tamaño total del archivo, o 0 si el servidor no lo dice.
  int _totalOf(Response<ResponseBody> response, int start) {
    final range = response.headers.value(HttpHeaders.contentRangeHeader);
    if (range != null) {
      final total = int.tryParse(range.split('/').last);
      if (total != null) return total;
    }
    final length = int.tryParse(
      response.headers.value(Headers.contentLengthHeader) ?? '',
    );
    if (length == null || length <= 0) return 0;
    return start + length;
  }
}
