import 'package:flutter/material.dart';

import 'app.dart';
import 'core/di/dependency_injection.dart';
import 'core/utils/campus_sync_service.dart';
import 'core/utils/platform_storage.dart';
import 'features/navigation/data/datasources/mock_campus_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await PlatformStorage.instance.init();
  setupDependencies();
  await MockCampusData.loadFromFile();

  // Sincronización automática con el backend de push (no bloqueante).
  CampusSyncService.sync();

  runApp(const AppGuiaAR());
}
