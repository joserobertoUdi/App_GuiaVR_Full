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
    required super.message,
    super.code,
    super.originalError,
  });
}

class CacheException extends AppException {
  const CacheException({
    required super.message,
    super.code,
    super.originalError,
  });
}

class NetworkException extends AppException {
  const NetworkException({
    required super.message,
    super.code,
    super.originalError,
  });
}

class LocationException extends AppException {
  const LocationException({
    required super.message,
    super.code,
    super.originalError,
  });
}

class PermissionException extends AppException {
  const PermissionException({
    required super.message,
    super.code,
    super.originalError,
  });
}

class ParseException extends AppException {
  const ParseException({
    required super.message,
    super.code,
    super.originalError,
  });
}

class RouteException extends AppException {
  const RouteException({
    required super.message,
    super.code,
    super.originalError,
  });
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
    required super.message,
    super.code,
    super.originalError,
  });
}