import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savetic/src/core/helpers/resumable_download.dart';

/// Servidor falso de un archivo de 10 bytes ("0123456789") que entiende
/// `Range`, o no, según la prueba.
class _Server implements HttpClientAdapter {
  _Server({this.supportsRange = true, this.cutAfter, this.rangeStatus});

  final bool supportsRange;

  /// Si se da, la respuesta se corta con error tras esos bytes.
  int? cutAfter;

  /// Si se da, responde ese estado a toda petición con rango.
  final int? rangeStatus;

  static final Uint8List content = Uint8List.fromList('0123456789'.codeUnits);
  final List<String?> ranges = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final range = options.headers['range'] as String?;
    ranges.add(range);
    if (range != null && rangeStatus != null) {
      return ResponseBody.fromString('', rangeStatus!);
    }
    var from = 0;
    var status = 200;
    if (range != null && supportsRange) {
      from = int.parse(range.replaceAll(RegExp(r'[^0-9]'), ''));
      status = 206;
    }
    final body = content.sublist(from);
    final headers = <String, List<String>>{
      Headers.contentLengthHeader: ['${body.length}'],
      if (status == 206) 'content-range': ['bytes $from-9/10'],
    };
    final cut = cutAfter;
    if (cut != null) {
      cutAfter = null;
      return ResponseBody(
        () async* {
          yield body.sublist(0, cut);
          throw const SocketException('se cortó la conexión');
        }(),
        status,
        headers: headers,
      );
    }
    return ResponseBody.fromBytes(body, status, headers: headers);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Directory dir;
  late String target;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('reanudar');
    target = '${dir.path}/video.mp4';
  });

  tearDown(() => dir.delete(recursive: true));

  ResumableDownload downloader(_Server server) =>
      ResumableDownload(Dio()..httpClientAdapter = server);

  String read(String path) => File(path).readAsStringSync();

  test('una descarga normal queda en el destino y no deja .part', () async {
    final progress = <List<int>>[];
    await downloader(_Server()).run(
      url: 'https://cdn/v.mp4',
      savePath: target,
      onProgress: (r, t) => progress.add([r, t]),
    );

    expect(read(target), '0123456789');
    expect(File(ResumableDownload.partPathOf(target)).existsSync(), isFalse);
    expect(progress.last, [10, 10]);
  });

  test('un corte deja lo bajado en .part y no crea el archivo final', () async {
    final server = _Server(cutAfter: 4);

    await expectLater(
      downloader(server).run(url: 'https://cdn/v.mp4', savePath: target),
      throwsA(isA<DioException>()),
    );

    expect(File(target).existsSync(), isFalse);
    expect(await ResumableDownload.savedBytes(target), 4);
  });

  test('reintentar pide solo lo que falta y completa el archivo', () async {
    final server = _Server(cutAfter: 4);
    final first = downloader(server);
    await first
        .run(url: 'https://cdn/v.mp4', savePath: target)
        .catchError((_) {});

    final progress = <List<int>>[];
    await first.run(
      url: 'https://cdn/v.mp4',
      savePath: target,
      onProgress: (r, t) => progress.add([r, t]),
    );

    expect(server.ranges, [null, 'bytes=4-']);
    expect(read(target), '0123456789');
    expect(File(ResumableDownload.partPathOf(target)).existsSync(), isFalse);
    // El avance cuenta lo que ya estaba: arranca en 10 de 10 al sumar 6 a 4.
    expect(progress.first[0], greaterThan(4));
    expect(progress.last, [10, 10]);
  });

  test('si el servidor ignora el rango, se baja entero sin duplicar', () async {
    final server = _Server(supportsRange: false);
    await File(ResumableDownload.partPathOf(target)).writeAsString('0123');

    await downloader(server).run(url: 'https://cdn/v.mp4', savePath: target);

    expect(server.ranges, ['bytes=4-']);
    expect(read(target), '0123456789'); // no '01230123456789'
  });

  test('un 416 descarta lo parcial y empieza de cero', () async {
    final server = _Server(rangeStatus: 416);
    await File(ResumableDownload.partPathOf(target)).writeAsString('0123');

    await downloader(server).run(url: 'https://cdn/v.mp4', savePath: target);

    expect(server.ranges, ['bytes=4-', null]);
    expect(read(target), '0123456789');
  });

  test('un error del servidor con lo parcial guardado lo conserva', () async {
    final server = _Server(rangeStatus: 403);
    await File(ResumableDownload.partPathOf(target)).writeAsString('0123');

    await expectLater(
      downloader(server).run(url: 'https://cdn/v.mp4', savePath: target),
      throwsA(isA<DioException>()),
    );

    expect(await ResumableDownload.savedBytes(target), 4);
  });

  test('discard borra lo parcial', () async {
    await File(ResumableDownload.partPathOf(target)).writeAsString('0123');

    await ResumableDownload.discard(target);

    expect(await ResumableDownload.savedBytes(target), 0);
  });

  test('un destino ya existente se reemplaza al terminar', () async {
    await File(target).writeAsString('viejo');

    await downloader(_Server()).run(url: 'https://cdn/v.mp4', savePath: target);

    expect(read(target), '0123456789');
  });
}
