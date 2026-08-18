import '../models/location_model.dart';

abstract class LocationRepository {
  Future<LocationModel?> getCurrentLocation();
  Stream<LocationModel> watchCurrentLocation();
  Future<String?> findNearestNode({
    required double latitude,
    required double longitude,
    double maxDistance = 50,
  });
  Future<void> saveLocation(LocationModel location);
  Future<List<LocationModel>> getLocationHistory();
  Future<bool> checkPermissions();
  Future<void> requestPermissions();
}
