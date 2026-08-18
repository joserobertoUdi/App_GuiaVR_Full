import 'package:flutter/material.dart';
import 'package:admin_web/core/theme/app_theme.dart';
import 'package:admin_web/core/utils/platform_storage.dart';
import 'package:admin_web/features/navigation/presentation/screens/admin_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PlatformStorage.instance.init();
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Guía AR Campus · Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AdminScreen(),
    );
  }
}