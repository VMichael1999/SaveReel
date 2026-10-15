import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savetic/src/core/error/error_handler.dart';
import 'package:savetic/src/core/error/failure.dart';

DioException _response(int status) => DioException(
  requestOptions: RequestOptions(path: '/analysis'),
  type: DioExceptionType.badResponse,
  response: Response(
    requestOptions: RequestOptions(path: '/analysis'),
    statusCode: status,
    data: {'message': 'Invalid API key.'},
  ),
);

DioException _of(DioExceptionType type) =>
    DioException(requestOptions: RequestOptions(path: '/analysis'), type: type);

void main() {
  Failure handle(DioException e) => ErrorHandler.handle(e).failure;

  test(
    'una clave inválida (401) se explica sin mostrar el mensaje en inglés',
    () {
      final failure = handle(_response(401));

      expect(failure, isA<NotSubscribedFailure>());
      expect(failure.message, isNot(contains('Invalid')));
    },
  );

  test('cada código del servicio tiene su mensaje en español', () {
    expect(handle(_response(400)), isA<BadRequestFailure>());
    expect(handle(_response(403)), isA<NotSubscribedFailure>());
    expect(handle(_response(404)), isA<NotFoundFailure>());
    expect(handle(_response(429)), isA<TooManyRequestsFailure>());
    expect(handle(_response(500)), isA<ServerFailure>());
    expect(handle(_response(418)), isA<UnexpectedFailure>());
  });

  test('los cortes de red y los tiempos de espera se distinguen', () {
    expect(
      handle(_of(DioExceptionType.connectionTimeout)),
      isA<ConnectTimeOutFailure>(),
    );
    expect(
      handle(_of(DioExceptionType.receiveTimeout)),
      isA<ConnectTimeOutFailure>(),
    );
    expect(
      handle(_of(DioExceptionType.connectionError)),
      isA<NoInternetConnectionFailure>(),
    );
    expect(handle(_of(DioExceptionType.cancel)), isA<CancelRequestFailure>());
  });
}
