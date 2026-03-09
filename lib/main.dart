import 'package:flutter/material.dart';
import 'features/auth/login_page.dart';
import 'core/services/auth_service.dart';
import 'core/dashboard/dashboard_page.dart';

void main() => runApp(const AssurAncyApp());

class AssurAncyApp extends StatelessWidget {
  const AssurAncyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AssurAncy',
      debugShowCheckedModeBanner: false,
      routes: {
        '/login':     (_) => const LoginPage(),
        '/dashboard': (_) => const DashboardPage(),
      },
      home: const SplashRouter(), 
    );
  }
}

class SplashRouter extends StatefulWidget {
  const SplashRouter({super.key});
  @override
  State<SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends State<SplashRouter> {
  @override
  void initState() {
    super.initState();
    _check();
  }

  void _check() async {
    final auth = AuthService();
    final connecte = await auth.estConnecte();
    if (!mounted) return;
    Navigator.pushReplacementNamed(
      context,
      connecte ? '/dashboard' : '/login',
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFDEEBFA),
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFF1A56DB)),
      ),
    );
  }
}