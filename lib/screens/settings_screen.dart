// Motracker — Settings Screen

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../providers/auth_provider.dart';
import '../providers/sync_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/settings_provider.dart';
import '../services/export_service.dart';
import '../utils/formatters.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer4<AuthProvider, SyncProvider, TransactionProvider, SettingsProvider>(
      builder: (context, auth, sync, transactions, settings, child) {
        return SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    'Settings',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                ),
              ),
              
              // Profile Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: AppTheme.glassCard,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: AppTheme.surfaceDark,
                          backgroundImage: auth.userPhoto != null 
                              ? NetworkImage(auth.userPhoto!) 
                              : null,
                          child: auth.userPhoto == null 
                              ? const Icon(Icons.person_rounded, size: 30, color: AppTheme.textSecondary)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                auth.userName ?? 'User',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                auth.userEmail ?? 'No email',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms),
                ),
              ),
              
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
              
              // Preferences
              SliverToBoxAdapter(
                child: _SectionHeader(title: 'Preferences'),
              ),
              
              SliverToBoxAdapter(
                child: _SettingsTile(
                  icon: Icons.attach_money_rounded,
                  iconColor: AppTheme.accent,
                  title: 'Currency',
                  subtitle: 'Base currency for display',
                  trailing: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: settings.currencySymbol,
                      dropdownColor: AppTheme.cardDarkAlt,
                      items: const [
                        DropdownMenuItem(value: '₹', child: Text('INR (₹)')),
                        DropdownMenuItem(value: '\$', child: Text('USD (\$)', style: TextStyle(fontFamily: 'Roboto'))),
                        DropdownMenuItem(value: '€', child: Text('EUR (€)', style: TextStyle(fontFamily: 'Roboto'))),
                        DropdownMenuItem(value: '£', child: Text('GBP (£)', style: TextStyle(fontFamily: 'Roboto'))),
                        DropdownMenuItem(value: '¥', child: Text('JPY (¥)', style: TextStyle(fontFamily: 'Roboto'))),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          settings.setCurrencySymbol(val);
                        }
                      },
                    ),
                  ),
                  onTap: () {},
                ),
              ),
              
              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // Sync & Backup
              SliverToBoxAdapter(
                child: _SectionHeader(title: 'Cloud Backup (Google Sheets)'),
              ),
              
              SliverToBoxAdapter(
                child: _SettingsTile(
                  icon: Icons.cloud_sync_rounded,
                  iconColor: AppTheme.accent,
                  title: 'Sync Now',
                  subtitle: sync.isSyncing 
                      ? sync.lastSyncMessage ?? 'Syncing...'
                      : sync.lastSyncTime != null 
                          ? 'Last synced: ${Formatters.relativeDate(sync.lastSyncTime!)} at ${Formatters.time(sync.lastSyncTime!)}'
                          : 'Never synced',
                  trailing: sync.isSyncing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accent),
                        )
                      : IconButton(
                          icon: const Icon(Icons.sync_rounded),
                          onPressed: () {
                            sync.syncNow(auth.userEmail);
                          },
                        ),
                  onTap: () {
                    if (!sync.isSyncing) {
                      sync.syncNow(auth.userEmail);
                    }
                  },
                ).animate().slideX(begin: 0.1, end: 0, delay: 100.ms).fadeIn(),
              ),
              
              // Data Management
              SliverToBoxAdapter(
                child: _SectionHeader(title: 'Data Management'),
              ),
              
              SliverToBoxAdapter(
                child: _SettingsTile(
                  icon: Icons.download_rounded,
                  iconColor: AppTheme.info,
                  title: 'Export to CSV',
                  subtitle: 'Save transactions as a spreadsheet file',
                  onTap: () async {
                    try {
                      await ExportService.exportAndShare(transactions.transactions);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Export failed: $e')),
                        );
                      }
                    }
                  },
                ).animate().slideX(begin: 0.1, end: 0, delay: 200.ms).fadeIn(),
              ),
              
              // Account Actions
              SliverToBoxAdapter(
                child: _SectionHeader(title: 'Account'),
              ),
              
              SliverToBoxAdapter(
                child: _SettingsTile(
                  icon: Icons.logout_rounded,
                  iconColor: AppTheme.expense,
                  title: 'Sign Out',
                  subtitle: 'Log out from your Google account',
                  onTap: () async {
                    // Show confirmation
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Sign Out'),
                        content: const Text('Are you sure you want to sign out? Your local data will remain until you clear it.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Sign Out', style: TextStyle(color: AppTheme.expense)),
                          ),
                        ],
                      ),
                    );
                    
                    if (confirm == true && context.mounted) {
                      await auth.signOut();
                    }
                  },
                ).animate().slideX(begin: 0.1, end: 0, delay: 300.ms).fadeIn(),
              ),
              
              // App Info
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      children: [
                        Text(
                          AppConstants.appName,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Version ${AppConstants.appVersion}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 500.ms),
                ),
              ),
              
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppTheme.textMuted,
          letterSpacing: 1.2,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
