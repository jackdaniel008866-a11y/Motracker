// Motracker — Entry Point

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';
import 'providers/auth_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/budget_provider.dart';
import 'providers/recurring_transaction_provider.dart';
import 'providers/sync_provider.dart';
import 'providers/settings_provider.dart';
import 'services/database_service.dart';
import 'services/sheets_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize date formatting for India locale
  await initializeDateFormatting('en_IN', null);
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialize core services
  final databaseService = DatabaseService();
  final sheetsService = SheetsService();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => BudgetProvider()),
        ChangeNotifierProvider(create: (_) => RecurringTransactionProvider()),
        ChangeNotifierProvider(create: (_) => SyncProvider(databaseService, sheetsService)),
      ],
      child: const MotrackerApp(),
    ),
  );
}
