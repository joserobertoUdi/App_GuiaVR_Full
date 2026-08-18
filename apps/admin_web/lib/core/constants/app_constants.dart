class AppConstants {
  AppConstants._();

  static const String appName = 'Guía AR Campus';
  static const String appVersion = '1.0.0';

  static const double defaultMapZoom = 16.0;
  static const double defaultMaxSearchDistance = 100.0;
  static const double defaultNodeSnapDistance = 30.0;

  static const int defaultPanoramaWidth = 4096;
  static const int defaultPanoramaHeight = 2048;

  static const double hotspotsDefaultRadius = 30.0;
  static const double hotspotsMinPitch = -30.0;
  static const double hotspotsMaxPitch = 30.0;

  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration defaultTransitionDuration = Duration(milliseconds: 500);
  static const Duration defaultTimeout = Duration(seconds: 30);

  static const String firebaseCollectionNodes = 'nodes';
  static const String firebaseCollectionRoutes = 'routes';
  static const String firebaseCollectionPanoramas = 'panoramas';
  static const String firebaseCollectionGraphs = 'graphs';
  static const String firebaseStoragePanoramas = 'panoramas';

  static const double gpsAccuracyThreshold = 20.0;
  static const int maxLocationHistorySize = 100;
}