// Motracker — App Configuration

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'config/constants.dart';
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
// Note: We'll import other screens as they are created

class MotrackerApp extends StatelessWidget {
  const MotrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark, // Enforce dark theme
      darkTheme: AppTheme.darkTheme,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Initialize auth on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        if (auth.isLoading) {
          return const SplashScreen();
        }
        
        if (auth.isLoggedIn) {
          return const HomeScreen();
        }
        
        return const LoginScreen();
      },
    );
  }
}
