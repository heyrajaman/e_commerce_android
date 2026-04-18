/// Thrown when the server returns a 400, 404, 500, etc.
class ServerException implements Exception {
  final String message;
  final int? statusCode;

  ServerException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

/// Thrown specifically for 401/403 responses to trigger logout workflows.
class UnauthorizedException implements Exception {
  final String message;

  UnauthorizedException(this.message);

  @override
  String toString() => message;
}

/// Thrown when there is no internet connection or a timeout occurs.
class NetworkException implements Exception {
  final String message;

  NetworkException(this.message);

  @override
  String toString() => message;
}

/// Thrown when local storage operations fail.
class CacheException implements Exception {
  final String message;

  CacheException(this.message);

  @override
  String toString() => message;
}

/// Helper class to map HTTP responses to our custom exceptions.
class ApiExceptionMapper {
  static Exception map(int? statusCode, String message) {
    if (statusCode == null) {
      return NetworkException('Network connection failed. Please check your internet.');
    }

    switch (statusCode) {
      case 401:
      case 403:
        return UnauthorizedException(message);
      case 400:
      case 404:
      case 500:
      default:
        return ServerException(message, statusCode);
    }
  }
}