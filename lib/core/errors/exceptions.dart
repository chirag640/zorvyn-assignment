/// Custom exception classes for better error handling
class AppException implements Exception {
  AppException(this.message, [this.prefix = 'Error']);
  
  final String message;
  final String prefix;

  @override
  String toString() => '$prefix: $message';
}

class FetchDataException extends AppException {
  FetchDataException(String message) : super(message, 'Error During Communication');
}

class BadRequestException extends AppException {
  BadRequestException(String message) : super(message, 'Invalid Request');
}

class UnauthorizedException extends AppException {
  UnauthorizedException(String message) : super(message, 'Unauthorized');
}

class NotFoundException extends AppException {
  NotFoundException(String message) : super(message, 'Not Found');
}

class InvalidInputException extends AppException {
  InvalidInputException(String message) : super(message, 'Invalid Input');
}

class ServerException extends AppException {
  ServerException(String message) : super(message, 'Internal Server Error');
}

class NetworkException extends AppException {
  NetworkException(String message) : super(message, 'No Internet Connection');
}

class TimeoutException extends AppException {
  TimeoutException(String message) : super(message, 'Request Timeout');
}

class CacheException extends AppException {
  CacheException(String message) : super(message, 'Cache Error');
}

