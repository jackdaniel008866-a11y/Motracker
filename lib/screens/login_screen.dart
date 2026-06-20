// Motracker — Login Screen

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../providers/auth_provider.dart';
import '../providers/sync_provider.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              
              // Logo
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.cardDark,
                    border: Border.all(
                      color: AppTheme.accent.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    size: 80,
                    color: AppTheme.accent,
                  ),
                ),
              ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
              
              const SizedBox(height: 32),
              
              // Welcome Text
              Text(
                'Welcome to',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
              
              Text(
                AppConstants.appName,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: AppTheme.accent,
                  fontSize: 40,
                ),
              ).animate().slideY(begin: 0.2, end: 0, delay: 300.ms, duration: 600.ms).fadeIn(),
              
              const SizedBox(height: 16),
              
              Text(
                'Your personal finance manager\nwith free cloud backup',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textMuted,
                  height: 1.5,
                ),
              ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
              
              const Spacer(),
              
              // Login Button
              ElevatedButton(
                onPressed: () => _handleLogin(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppTheme.cardDarkAlt,
                  foregroundColor: AppTheme.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: AppTheme.accent.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Simple Google "G" icon replacement using an Icon since we don't have assets yet
                    const Icon(Icons.g_mobiledata_rounded, size: 32, color: Colors.white),
                    const SizedBox(width: 12),
                    Text(
                      'Continue with Google',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ).animate().slideY(begin: 0.5, end: 0, delay: 600.ms, duration: 600.ms).fadeIn(),
              
              const SizedBox(height: 16),
              
              // Terms text
              Text(
                'By continuing, you agree to store your data\nin your own Google Sheet.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textMuted,
                ),
              ).animate().fadeIn(delay: 800.ms, duration: 600.ms),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final sync = context.read<SyncProvider>();
    final navigator = Navigator.of(context, rootNavigator: true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    // Show loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppTheme.accent),
      ),
    );
    
    final success = await auth.signIn();
    
    // Hide loading
    navigator.pop();
    
    if (success && auth.userEmail != null) {
      // Show sync dialog for fresh install
      showDialog(
        context: navigator.context,
        barrierDismissible: false,
        builder: (context) => _SyncingDialog(email: auth.userEmail!),
      );
      
      // Initial restore
      await sync.initialRestoreSync(auth.userEmail!);
      
      // Hide sync dialog
      navigator.pop();
    } else if (!success) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Failed to sign in. Please try again.'),
          backgroundColor: AppTheme.expense,
        ),
      );
    }
  }
}

class _SyncingDialog extends StatelessWidget {
  final String email;
  
  const _SyncingDialog({required this.email});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppTheme.accent),
            const SizedBox(height: 24),
            Text(
              'Restoring Data',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Checking your Google Sheet...',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
