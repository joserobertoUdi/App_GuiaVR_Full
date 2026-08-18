import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/navigation/presentation/screens/home_screen.dart';

class AppGuiaAR extends StatelessWidget {
  const AppGuiaAR({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Guía AR Campus',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
    );
  }
}
