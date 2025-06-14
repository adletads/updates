import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/auth_service.dart';
import 'package:provider/provider.dart';
import 'providers/user_provider.dart';
import 'screens/employee_panel.dart';
import 'screens/manager_panel.dart';
import 'screens/admin_panel.dart';
import 'screens/hr_panel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    ChangeNotifierProvider(
      create: (_) => UserProvider(),
      child: const EmployeeUpdatesApp(),
    ),
  );
}

class EmployeeUpdatesApp extends StatelessWidget {
  const EmployeeUpdatesApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData.light();
    final modernTheme = baseTheme.copyWith(
      colorScheme: baseTheme.colorScheme.copyWith(
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
      textTheme: baseTheme.textTheme.apply(
        fontFamily: 'Roboto',
        bodyColor: Colors.black87,
        displayColor: Colors.black87,
      ).copyWith(
        titleLarge: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        titleMedium: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
        labelLarge: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    );

    return MaterialApp(
      title: 'Employee Updates',
      theme: modernTheme,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _loadingUser = true;

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (user != null) {
        await userProvider.loadUser(user.uid);
      } else {
        userProvider.clear();
      }
      setState(() {
        _loadingUser = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingUser) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const LoginScreen();
    } else {
      return const HomeScreen();
    }
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+*$');
    return emailRegex.hasMatch(email);
  }

  Future<void> _signInWithEmail() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    if (!_isValidEmail(_emailController.text.trim())) {
      if (!mounted) return;
      setState(() {
        _error = 'Please enter a valid email address.';
        _loading = false;
      });
      return;
    }
    try {
      await _authService.signInWithEmail(_emailController.text.trim(), _passwordController.text.trim());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _authService.signInWithGoogle();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _registerWithEmail() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    if (!_isValidEmail(_emailController.text.trim())) {
      if (!mounted) return;
      setState(() {
        _error = 'Please enter a valid email address.';
        _loading = false;
      });
      return;
    }
    try {
      await _authService.registerWithEmail(_emailController.text.trim(), _passwordController.text.trim());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
            ],
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            if (_loading)
              const CircularProgressIndicator()
            else ...[
              ElevatedButton(
                onPressed: _signInWithEmail,
                child: const Text('Sign in with Email'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _registerWithEmail,
                child: const Text('Sign up with Email'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _signInWithGoogle,
                child: const Text('Sign in with Google'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Updates Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: Center(
        child: userProvider.role == 'employee' || userProvider.role == null || userProvider.role == ''
            ? ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const EmployeePanel()),
                  );
                },
                child: const Text('Go to Employee Panel'),
              )
            : userProvider.role == 'manager'
                ? ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ManagerPanel()),
                      );
                    },
                    child: const Text('Go to Manager Panel'),
                  )
                : userProvider.role == 'admin'
                    ? ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AdminPanel()),
                          );
                        },
                        child: const Text('Go to Admin Panel'),
                      )
                    : userProvider.role == 'hr'
                        ? ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const HRPanel()),
                              );
                            },
                            child: const Text('Go to HR Panel'),
                          )
                        : const Text('Welcome! You are logged in.'),
      ),
    );
  }
}
