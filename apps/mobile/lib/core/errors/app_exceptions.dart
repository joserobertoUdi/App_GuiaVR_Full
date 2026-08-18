abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException({
    required this.message,
    this.code,
    this.originalError,
  });

  @override
  String toString() => 'AppException: $message (code: $code)';
}

class ServerException extends AppException {
  const ServerException({
    required String message,
    String? code,
    dynamic originalError,
  }) : super(
          message: message,
          code: code,
          originalError: originalError,
        );
}

class CacheException extends AppException {
  const CacheException({
    required String message,
    String? code,
    dynamic originalError,
  }) : super(
          message: message,
          code: code,
          originalError: originalError,
        );
}

class NetworkException extends AppException {
  const NetworkException({
    required String message,
    String? code,
    dynamic originalError,
  }) : super(
          message: message,
          code: code,
          originalError: originalError,
        );
}

class LocationException extends AppException {
  const LocationException({
    required String message,
    String? code,
    dynamic originalError,
  }) : super(
          message: message,
          code: code,
          originalError: originalError,
        );
}

class PermissionException extends AppException {
  const PermissionException({
    required String message,
    String? code,
    dynamic originalError,
  }) : super(
          message: message,
          code: code,
          originalError: originalError,
        );
}

class ParseException extends AppException {
  const ParseException({
    required String message,
    String? code,
    dynamic originalError,
  }) : super(
          message: message,
          code: code,
          originalError: originalError,
        );
}

class RouteException extends AppException {
  const RouteException({
    required String message,
    String? code,
    dynamic originalError,
  }) : super(
          message: message,
          code: code,
          originalError: originalError,
        );
}

class NodeNotFoundException extends RouteException {
  const NodeNotFoundException({
    required String nodeId,
    String? message,
  }) : super(
          message: message ?? 'Node not found: $nodeId',
          code: 'NODE_NOT_FOUND',
        );
}

class NoRouteFoundException extends RouteException {
  const NoRouteFoundException({
    required String startNodeId,
    required String endNodeId,
    String? message,
  }) : super(
          message: message ??
              'No route found from $startNodeId to $endNodeId',
          code: 'NO_ROUTE_FOUND',
        );
}

class PanoramaException extends AppException {
  const PanoramaException({
    required String message,
    String? code,
    dynamic originalError,
  }) : super(
          message: message,
          code: code,
          originalError: originalError,
        );
}
