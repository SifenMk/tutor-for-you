import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tut4u/screen/CustomerDashboard.dart';
import 'package:tut4u/screen/TutorDashboard.dart';
import 'package:tut4u/components/elements.dart';
import 'package:tut4u/screen/signup.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login Successful')),
      );
      navigateBasedOnRole();
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Login Failed')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 48),
              Image.asset(
                'assets/images/logo.jpg',
                height: 100,
                width: 300,
                fit: BoxFit.cover,
              ),
              const SizedBox(height: 24),

              const Text(
                'Welcome to TutForYou',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              const SizedBox(height: 16),
              SimpleComponents.buildTextField(
                  _emailController, "Email", "Enter your email"),
              const SizedBox(height: 16),
              SimpleComponents.buildTextField(
                  _passwordController, "Password", "Enter your password",
                  isPassword: true),
              const SizedBox(height: 24),
              SimpleComponents.buildButton(
                  isLoading: _isLoading, onTap: _login, buttonText: 'Login'),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SignUpPage()),
                  );
                },
                child: RichText(
                    text: const TextSpan(
                        text: 'Don\'t have an account? ',
                        style: TextStyle(color: Colors.black),
                        children: [
                      TextSpan(
                        text: 'Create Account',
                        style: TextStyle(color: Colors.blue),
                      )
                    ])),
              ),

              // TextField(
              //   controller: _emailController,
              //   decoration: InputDecoration(labelText: 'Email'),
              // ),
              // SizedBox(height: 16),
              // TextField(
              //   controller: _passwordController,
              //   decoration: InputDecoration(labelText: 'Password'),
              //   obscureText: true,
              // ),
              // SizedBox(height: 24),
              // _isLoading
              //     ? CircularProgressIndicator()
              //     : ElevatedButton(
              //         onPressed: _login,
              //         child: Text('Login'),
              //       ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> navigateBasedOnRole() async {
    final user = FirebaseAuth.instance.currentUser;
    print(user);
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final role = doc.data()?['role'];

      if (role == 'Customer') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  CustomerDashboard(name: doc.data()?['name'] ?? '')),
        );
      } else {
        // Handle Tutor navigation
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => TutorDashboard()),
        );
      }
    }
  }
}
