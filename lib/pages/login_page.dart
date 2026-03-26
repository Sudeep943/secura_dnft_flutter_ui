import 'package:flutter/material.dart';

import '../navigation/app_section.dart';
import '../services/api_service.dart';
import '../widgets/brand_artwork.dart';
import 'app_shell.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final username = TextEditingController();
  final password = TextEditingController();

  bool loading = false;

  login() async {
    setState(() => loading = true);

    String? token = await ApiService.login(username.text, password.text);

    setState(() => loading = false);

    if (token != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AppShell(initialSection: AppSection.dashboard),
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Login Failed")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFFF7FBFA),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 64,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const BrandLogo(width: 520),
                const SizedBox(height: 28),
                Center(
                  child: Container(
                    width: 400,
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 15),
                      ],
                    ),

                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Login",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F8F82),
                          ),
                        ),

                        const SizedBox(height: 30),

                        TextField(
                          controller: username,
                          decoration: const InputDecoration(
                            labelText: "Username / Phone",
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 20),

                        TextField(
                          controller: password,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: "Password",
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 30),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F8F82),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: loading ? null : login,
                            child: loading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text("Login"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
