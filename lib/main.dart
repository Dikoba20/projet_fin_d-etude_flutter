import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'features/auth/login_page.dart';
import 'features/admin/admin_dashboard_page.dart';
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
        '/admin':     (_) => const _AdminWebGuard(),
      },
      home: const SplashRouter(),
    );
  }
}

// ══════════════════════════════════════════════════════
// GARDE : Admin accessible uniquement sur Web
// ══════════════════════════════════════════════════════
class _AdminWebGuard extends StatelessWidget {
  const _AdminWebGuard();
  @override
  Widget build(BuildContext context) {
    // Si on est sur mobile (pas web), bloquer l'accès
    if (!kIsWeb) {
      return Scaffold(
        backgroundColor: const Color(0xFFF0FDF4),
        body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: const Color(0xFF059669).withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.desktop_windows_rounded, size: 64, color: Color(0xFF059669))),
          const SizedBox(height: 24),
          const Text('Accès réservé au Web', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF064E3B))),
          const SizedBox(height: 8),
          const Text('L\'interface administrateur est\nuniquement accessible depuis un\nnavigateur web.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushReplacementNamed(context, '/dashboard'),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Retour à l\'application'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
          ),
        ])),
      );
    }
    return const AdminDashboardPage();
  }
}

// ══════════════════════════════════════════════════════
// SPLASH ROUTER
// ══════════════════════════════════════════════════════
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

  Future<void> _check() async {
    final auth     = AuthService();
    final connecte = await auth.estConnecte();
    if (!mounted) return;

    if (!connecte) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    // Redirection selon le rôle
    final role = await auth.getRole();
    if (role == 'ADMIN' && kIsWeb) {
      // Admin sur web → interface admin
      Navigator.pushReplacementNamed(context, '/admin');
    } else if (role == 'ADMIN' && !kIsWeb) {
      // Admin sur mobile → dashboard normal avec bouton admin
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDEEBFA),
      body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFF1A56DB).withOpacity(0.1), shape: BoxShape.circle),
          child: const Icon(Icons.shield_rounded, size: 48, color: Color(0xFF1A56DB))),
        const SizedBox(height: 20),
        const Text('AssurAncy', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1535A8))),
        const SizedBox(height: 24),
        const CircularProgressIndicator(color: Color(0xFF1A56DB)),
      ])),
    );
  }
}