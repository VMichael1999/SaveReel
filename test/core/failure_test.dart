import 'package:flutter_test/flutter_test.dart';
import 'package:savetic/src/core/error/failure.dart';

void main() {
  test('solo se ofrece reintentar cuando la causa es pasajera', () {
    for (final failure in <Failure>[
      const ServerFailure(),
      const NoInternetConnectionFailure(),
      const ConnectTimeOutFailure(),
      const UnexpectedFailure(),
      const NotSubscribedFailure(),
    ]) {
      expect(failure.retryable, isTrue, reason: '$failure');
    }
    for (final failure in <Failure>[
      const NotFoundFailure(),
      const BadRequestFailure(),
      const TooManyRequestsFailure(),
      const CancelRequestFailure(),
    ]) {
      expect(failure.retryable, isFalse, reason: '$failure');
    }
  });
}
