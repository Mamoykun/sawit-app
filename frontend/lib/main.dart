import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Status bar transparan
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  // Portrait only
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
    home: const SplashScreen(),
  );
}
