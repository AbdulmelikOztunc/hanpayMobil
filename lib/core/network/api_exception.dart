class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.details});

  final String message;
  final int? statusCode;
  final dynamic details;

  @override
  String toString() => message;
}

String messageFromDioError(Object error) {
  if (error is ApiException) return error.message;
  return error.toString();
}
