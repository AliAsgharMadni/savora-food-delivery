class Failure implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  const Failure(this.message, {this.code, this.details});

  @override
  String toString() => 'Failure(message: $message, code: $code)';
}

class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code, super.details});
}

