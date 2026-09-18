import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'screens/route_options_screen.dart';
import 'screens/route_details_screen.dart';
import 'screens/sos_screen.dart';
import 'screens/safe_haven_screen.dart';
import 'screens/navigation_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'services/location_service.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => LocationService()),
        ProxyProvider<AuthService, ApiService>(
          update: (context, auth, previous) => ApiService(
            getToken: auth.getToken,
          ),
        ),
      ],
      child: const SheSafeApp(),
    ),
  );
}

class SheSafeApp extends StatefulWidget {
  const SheSafeApp({super.key});

  @override
  State<SheSafeApp> createState() => _SheSafeAppState();
}

class _SheSafeAppState extends State<SheSafeApp> {
  bool isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();

    Widget homeWidget;
    if (authService.isLoading) {
      homeWidget = Scaffold(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFFFF8F8),
        body: const Center(child: CircularProgressIndicator(color: Colors.pink)),
      );
    } else if (authService.isAuthenticated) {
      homeWidget = NavigationScreen(
        isDarkMode: isDarkMode,
        onThemeChanged: (value) {
          setState(() {
            isDarkMode = value;
          });
        },
      );
    } else {
      homeWidget = LoginScreen(isDarkMode: isDarkMode);
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,

      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: const Color(0xFFFFF8F8),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFFD6E8),
          foregroundColor: Colors.black,
          elevation: 0,
        ),
      ),

      darkTheme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),

      themeMode:
          isDarkMode ? ThemeMode.dark : ThemeMode.light,

      home: homeWidget,
    );
  }
}