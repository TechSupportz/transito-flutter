class ApiException implements Exception {
  ApiException({
    required this.statusCode,
    required this.message,
    this.uri,
    this.responseBody,
  });

  final int statusCode;
  final String message;
  final Uri? uri;
  final String? responseBody;

  @override
  String toString() {
    final String uriText = uri == null ? '' : ' uri=$uri';
    return 'ApiException(statusCode: $statusCode,$uriText message: $message)';
  }
}

class NetworkException implements Exception {
  NetworkException(this.message, {this.uri, this.cause});

  final String message;
  final Uri? uri;
  final Object? cause;

  @override
  String toString() {
    final String uriText = uri == null ? '' : ' uri=$uri';
    return 'NetworkException($message,$uriText cause: $cause)';
  }
}

class ApiParsingException implements Exception {
  ApiParsingException(this.message, {this.uri, this.cause});

  final String message;
  final Uri? uri;
  final Object? cause;

  @override
  String toString() {
    final String uriText = uri == null ? '' : ' uri=$uri';
    return 'ApiParsingException($message,$uriText cause: $cause)';
  }
}
