import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'models/browser_config.dart';
import 'models/browser_settings.dart';
import 'screens/browser_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set dark system overlays
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: BrowserConfig.primaryColor,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: BrowserConfig.backgroundColor,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const SecureBrowserApp());
}

class SecureBrowserApp extends StatelessWidget {
  const SecureBrowserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BrowserSettings(),
      child: MaterialApp(
        title: BrowserConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          primaryColor: BrowserConfig.primaryColor,
          scaffoldBackgroundColor: BrowserConfig.backgroundColor,
          colorScheme: const ColorScheme.dark(
            primary: BrowserConfig.primaryColor,
            secondary: BrowserConfig.accentColor,
            surface: BrowserConfig.cardColor,
            error: BrowserConfig.errorColor,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: BrowserConfig.primaryColor,
            elevation: 0,
          ),
        ),
        home: const BrowserScreen(),
      ),
    );
  }
}
