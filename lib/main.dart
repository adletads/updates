import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'auth_wrapper.dart';
import 'providers/user_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const EmployeeUpdatesApp());
}

class EmployeeUpdatesApp extends StatefulWidget {
  const EmployeeUpdatesApp({Key? key}) : super(key: key);

  @override
  State<EmployeeUpdatesApp> createState() => _EmployeeUpdatesAppState();
}

class _EmployeeUpdatesAppState extends State<EmployeeUpdatesApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _toggleThemeMode() {
    setState(() {
      if (_themeMode == ThemeMode.light) {
        _themeMode = ThemeMode.dark;
      } else {
        _themeMode = ThemeMode.light;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: Builder(
        builder: (context) {
          final baseLightTheme = ThemeData.light(useMaterial3: true);
          final baseDarkTheme = ThemeData.dark(useMaterial3: true);

    final lightTheme = baseLightTheme.copyWith(
      colorScheme: baseLightTheme.colorScheme.copyWith(
        primary: const Color(0xFF0A73B7),
        secondary: const Color(0xFF1E88E5),
        background: const Color(0xFFF5F7FA),
        surface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onBackground: Colors.black87,
        onSurface: Colors.black87,
      ),
      primaryColor: const Color(0xFF0A73B7),
      scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0A73B7),
        foregroundColor: Colors.white,
        elevation: 4,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E88E5),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          elevation: 4,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 2),
        ),
        labelStyle: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
      textTheme: baseLightTheme.textTheme.apply(
        fontFamily: 'Roboto',
        bodyColor: Colors.black87,
        displayColor: Colors.black87,
      ).copyWith(
        titleLarge: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        titleMedium: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
        labelLarge: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    );

    final darkTheme = baseDarkTheme.copyWith(
      colorScheme: baseDarkTheme.colorScheme.copyWith(
        primary: const Color(0xFF0A73B7),
        secondary: const Color(0xFF1E88E5),
        background: const Color(0xFF121212),
        surface: const Color(0xFF1E1E1E),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onBackground: Colors.white70,
        onSurface: Colors.white70,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0A73B7),
        foregroundColor: Colors.white,
        elevation: 4,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E88E5),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          elevation: 4,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 2),
        ),
        labelStyle: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
      ),
      cardTheme: CardTheme(
        color: const Color(0xFF1E1E1E),
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
      textTheme: baseDarkTheme.textTheme.apply(
        fontFamily: 'Roboto',
        bodyColor: Colors.white70,
        displayColor: Colors.white70,
      ).copyWith(
        titleLarge: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        titleMedium: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
        labelLarge: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    );

    return MaterialApp(
      title: 'Employee Updates',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: _themeMode,
      home: AuthWrapper(
        onToggleTheme: _toggleThemeMode,
      ),
    );
        },
      ),
    );
  }
}