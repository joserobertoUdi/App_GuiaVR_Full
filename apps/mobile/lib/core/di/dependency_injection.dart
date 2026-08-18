import 'package:get_it/get_it.dart';

import '../../features/navigation/domain/repositories/node_repository.dart';
import '../../features/navigation/domain/repositories/route_repository.dart';
import '../../features/panorama_viewer/domain/repositories/panorama_repository.dart';
import '../../features/location/domain/repositories/location_repository.dart';
import '../../features/route_engine/domain/repositories/graph_repository.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  _registerRepositories();
  _registerUseCases();
  _registerServices();
}

void _registerRepositories() {
  getIt.registerLazySingleton<NodeRepository>(
    () => throw UnimplementedError('NodeRepository not implemented yet'),
  );

  getIt.registerLazySingleton<RouteRepository>(
    () => throw UnimplementedError('RouteRepository not implemented yet'),
  );

  getIt.registerLazySingleton<PanoramaRepository>(
    () => throw UnimplementedError('PanoramaRepository not implemented yet'),
  );

  getIt.registerLazySingleton<LocationRepository>(
    () => throw UnimplementedError('LocationRepository not implemented yet'),
  );

  getIt.registerLazySingleton<GraphRepository>(
    () => throw UnimplementedError('GraphRepository not implemented yet'),
  );
}

void _registerUseCases() {
  // Register use cases here
  // Example:
  // getIt.registerLazySingleton(() => CalculateRouteUseCase(getIt()));
  // getIt.registerLazySingleton(() => GetNodeByIdUseCase(getIt()));
}

void _registerServices() {
  // Register external services here
  // Example:
  // getIt.registerLazySingleton(() => FirebaseService());
  // getIt.registerLazySingleton(() => LocationService());
}
