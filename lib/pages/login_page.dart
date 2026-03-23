import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
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
        MaterialPageRoute(builder: (_) => HomePage()),
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
      body: Center(
        child: Container(
          width: 400,
          padding: EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15)],
          ),

          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Login",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F8F82),
                ),
              ),

              SizedBox(height: 30),

              TextField(
                controller: username,
                decoration: InputDecoration(
                  labelText: "Username / Phone",
                  border: OutlineInputBorder(),
                ),
              ),

              SizedBox(height: 20),

              TextField(
                controller: password,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                ),
              ),

              SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF0F8F82),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: loading ? null : login,
                  child: loading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text("Login"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
