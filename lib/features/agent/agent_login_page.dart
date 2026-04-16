import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import 'agent_dashboard_page.dart';

class AgentLoginPage extends StatefulWidget {
  const AgentLoginPage({super.key});

  @override
  State<AgentLoginPage> createState() => _AgentLoginPageState();
}

class _AgentLoginPageState extends State<AgentLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _auth = AuthService();
  
  bool _isLoading = false;
  bool _obscure = true;

  // Couleurs de la charte
  final Color primary = const Color(0xFF1535A8);
  final Color bg = const Color(0xFFEEF2FF);

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    try {
      // Appel à votre service Django
      final res = await _auth.connecter(_emailCtrl.text, _passCtrl.text);
      
      if (res['success'] == true && mounted) {
        // Redirection vers le dashboard que nous avons créé
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AgentDashboardPage()),
        );
      } else {
        _showError(res['message'] ?? "Identifiants invalides");
      }
    } catch (e) {
      _showError("Erreur de connexion au serveur");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 400, // Largeur fixe pour un look "Portail Web/Tablette"
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo & Titre
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.shield_rounded, color: primary, size: 40),
                  ),
                  const SizedBox(height: 16),
                  Text("AssurAncy", 
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: primary)),
                  const Text("Portail Agent - Connexion", 
                    style: TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 40),

                  // Champ Email
                  TextFormField(
                    controller: _emailCtrl,
                    decoration: InputDecoration(
                      labelText: "Email professionnel",
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => v!.isEmpty ? "Champ requis" : null,
                  ),
                  const SizedBox(height: 20),

                  // Champ Password
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: "Mot de passe",
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => v!.isEmpty ? "Champ requis" : null,
                  ),
                  const SizedBox(height: 32),

                  // Bouton Connexion
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Se connecter", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}