import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../onboarding/onboarding_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _signup() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Username and password cannot be empty')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
    await prefs.setString('password', password);

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => OnboardingScreen()),
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign Up'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E1E1E), Color(0xFF121212)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 40),
                Center(
                  child: Icon(Icons.person_add, size: 80, color: Colors.deepOrange),
                ),
                SizedBox(height: 20),
                Center(
                  child: Text(
                    'CREATE ACCOUNT',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 2, color: Colors.white),
                  ),
                ),
                SizedBox(height: 40),
                TextField(
                  controller: _usernameController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Choose Username',
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.deepOrange),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _passwordController,
                  style: TextStyle(color: Colors.white),
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Choose Password',
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.deepOrange),
                    ),
                  ),
                ),
                SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _signup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Sign Up', style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
