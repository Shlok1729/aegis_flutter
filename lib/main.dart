import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/dashboard_screen.dart';

void main() {
  runApp(const AegisApp());
}

class AegisApp extends StatelessWidget {
  const AegisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Project AEGIS',
      debugShowCheckedModeBanner: false,
      theme: AegisTheme.darkTheme,
      home: DashboardScreen(),
    );
  }
}
