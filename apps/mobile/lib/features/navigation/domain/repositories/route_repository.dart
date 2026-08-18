import '../models/route_model.dart';

abstract class RouteRepository {
  Future<RouteModel> calculateRoute({
    required String startNodeId,
    required String endNodeId,
  });
  Future<List<RouteModel>> getSavedRoutes();
  Future<RouteModel?> getRouteById(String id);
  Future<void> saveRoute(RouteModel route);
  Future<void> deleteRoute(String id);
  Stream<List<RouteModel>> watchSavedRoutes();
}
