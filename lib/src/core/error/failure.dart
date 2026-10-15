import 'package:equatable/equatable.dart';

import '../api/response_message.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure({required this.message});

  /// Si vale la pena volver a intentarlo tal cual: la causa es pasajera
  /// (sin señal, servicio caído) y no del enlace ni del video.
  bool get retryable => false;

  @override
  List<Object?> get props => [message];
}

class BadRequestFailure extends Failure {
  const BadRequestFailure() : super(message: Authorized.badRequest);
}

class ServerFailure extends Failure {
  const ServerFailure() : super(message: Authorized.internalServerError);

  @override
  bool get retryable => true;
}

class NotFoundFailure extends Failure {
  const NotFoundFailure() : super(message: Authorized.notFound);
}

class NoInternetConnectionFailure extends Failure {
  const NoInternetConnectionFailure()
    : super(message: Authorized.noInternetConnection);

  @override
  bool get retryable => true;
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure() : super(message: Authorized.unexpected);

  @override
  bool get retryable => true;
}

class ConnectTimeOutFailure extends Failure {
  const ConnectTimeOutFailure() : super(message: Authorized.connectTimeOut);

  @override
  bool get retryable => true;
}

class CancelRequestFailure extends Failure {
  const CancelRequestFailure() : super(message: Authorized.cancel);
}

class TooManyRequestsFailure extends Failure {
  const TooManyRequestsFailure() : super(message: Authorized.tooManyRequests);
}

class NotSubscribedFailure extends Failure {
  const NotSubscribedFailure() : super(message: Authorized.notSubscribed);

  @override
  bool get retryable => true;
}
