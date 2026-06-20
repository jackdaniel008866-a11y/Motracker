// Motracker — App Constants

class AppConstants {
  // Google Sheets API URL
  static const String sheetsApiUrl = 'https://script.google.com/macros/s/AKfycbztoAl9W70EzdNUIIz2N7GPU7o9iEZhXY656JP1DsCBdIOr8hx54gf7Ip9vJHwPNfaq/exec';

  // App Info
  static const String appName = 'Motracker';
  static const String appVersion = '1.0.0';
  static String currencySymbol = '₹';
  static String currencyCode = 'INR';

  // Database
  static const String dbName = 'motracker.db';
  static const int dbVersion = 2;

  // Shared Preferences Keys
  static const String prefUserEmail = 'user_email';
  static const String prefUserName = 'user_name';
  static const String prefUserPhoto = 'user_photo';
  static const String prefIsLoggedIn = 'is_logged_in';
  static const String prefLastSyncTime = 'last_sync_time';
  static const String prefDarkMode = 'dark_mode';

  // Transaction Types
  static const String typeIncome = 'income';
  static const String typeExpense = 'expense';

  // Frequencies
  static const List<String> frequencies = ['daily', 'weekly', 'monthly', 'yearly'];

  // Date Formats
  static const String dateFormatDisplay = 'dd MMM yyyy';
  static const String dateFormatMonth = 'MMMM yyyy';
  static const String dateFormatShort = 'dd MMM';
  static const String monthKeyFormat = 'yyyy-MM';
}
