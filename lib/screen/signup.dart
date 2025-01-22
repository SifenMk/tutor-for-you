import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tut4u/screen/CustomerDashboard.dart';
import 'package:tut4u/screen/TutorDashboard.dart';
import 'package:tut4u/components/elements.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _profileImageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedRole = 'Customer'; // Default role
  bool _isLoading = false;

  Future<void> _signUp() async {
    if (_passwordController.text.trim() !=
        _confirmPasswordController.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Store user details in Firestore
      await _firestore.collection('users').doc(userCredential.user?.uid).set({
        'id': userCredential.user?.uid,
        'email': _emailController.text.trim(),
        'name': _nameController.text.trim(),
        'profileImage': _profileImageController.text.trim(),
        'role': _selectedRole,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account Created Successfully')),
      );
      navigateBasedOnRole();
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Sign Up Failed')),
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
      appBar: AppBar(title: const Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 48),
              const Text(
                'Create an Account',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Role: ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedRole,
                        items: ['Customer', 'Tutor'].map((role) {
                          return DropdownMenuItem(
                            value: role,
                            child: Text(role),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = value!;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SimpleComponents.buildTextField(
                  _nameController, "Name", "Enter your name"),
              const SizedBox(height: 16),
              SimpleComponents.buildTextField(
                  _emailController, "Email", "Enter your email"),
              const SizedBox(height: 16),
              SimpleComponents.buildTextField(
                  _passwordController, "Password", "Enter your password",
                  isPassword: true),
              const SizedBox(height: 16),
              SimpleComponents.buildTextField(_confirmPasswordController,
                  "Confirm Password", "Re-enter your password",
                  isPassword: true),
              const SizedBox(height: 24),
              SimpleComponents.buildButton(
                  isLoading: _isLoading, onTap: _signUp, buttonText: 'Sign Up'),
              const SizedBox(height: 16),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: RichText(
                    text: const TextSpan(
                        text: 'Already have an account? ',
                        style: TextStyle(color: Colors.black),
                        children: [
                      TextSpan(
                        text: 'Login',
                        style: TextStyle(color: Colors.blue),
                      )
                    ])),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> navigateBasedOnRole() async {
    final user = FirebaseAuth.instance.currentUser;
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
