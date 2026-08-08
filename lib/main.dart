import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/auth_provider.dart';
import 'providers/session_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/welcome_screen.dart';
import 'theme/app_colors.dart';

Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();


  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(

      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const BisnisKuApp(),
    ),
  );
}

class BisnisKuApp extends StatelessWidget {
  const BisnisKuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bisnis-Ku',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primary,
        useMaterial3: true,
      ),
      home: const _AuthGate(),
    );
  }
}






class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authControllerProvider);

    return authAsync.when(
      loading: () => const _SplashScreen(),
      error: (err, st) => const WelcomeScreen(),
      data: (akun) {
        if (akun != null) {
          return const DashboardScreen();
        }
        return const WelcomeScreen();
      },
    );
  }
}


class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF5B4FDD),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Bisnis-Ku',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(color: Colors.white70),
          ],
        ),
      ),
    );
  }
}
