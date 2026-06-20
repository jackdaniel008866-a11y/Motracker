// Motracker — Splash Screen

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';
import '../config/constants.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accent.withValues(alpha: 0.1),
                border: Border.all(
                  color: AppTheme.accent.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                size: 64,
                color: AppTheme.accent,
              ),
            )
            .animate()
            .scale(duration: 600.ms, curve: Curves.easeOutBack)
            .fadeIn(duration: 600.ms),
            
            const SizedBox(height: 24),
            
            // App Name
            Text(
              AppConstants.appName,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: AppTheme.accent,
                letterSpacing: 1.2,
              ),
            )
            .animate()
            .slideY(begin: 0.5, end: 0, duration: 600.ms, curve: Curves.easeOutCubic)
            .fadeIn(duration: 600.ms, delay: 200.ms),
            
            const SizedBox(height: 8),
            
            // Tagline
            Text(
              'Your personal finance manager',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textSecondary,
              ),
            )
            .animate()
            .fadeIn(duration: 600.ms, delay: 400.ms),
            
            const SizedBox(height: 48),
            
            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accent),
              strokeWidth: 3,
            )
            .animate()
            .fadeIn(duration: 600.ms, delay: 600.ms),
          ],
        ),
      ),
    );
  }
}
