import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'database/app_database.dart';
import 'services/sync_service.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

final navigatorKey = GlobalKey<NavigatorState>();
late final AppDatabase appDb;
late final SyncService syncService;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Indonesian locale data for DateFormat & NumberFormat
  // (used by laporan PDF, currency display, dll).
  await initializeDateFormatting('id_ID', null);
  appDb = AppDatabase();
  syncService = SyncService(db: appDb, api: ApiService());
  syncService.init();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const SawitKuApp());
}

class SawitKuApp extends StatelessWidget {
  const SawitKuApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'SawitKu',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.theme,
    navigatorKey: navigatorKey,
    home: const SplashScreen(),
  );
}
