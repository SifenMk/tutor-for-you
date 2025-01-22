import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:tut4u/screen/CustomerDashboard.dart';
import 'package:tut4u/screen/TutorDashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tut4U',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FutureBuilder<Map<String, dynamic>?>(
        future: navigateBasedOnRole(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (snapshot.hasData) {
            final name = snapshot.data!['name'];
            final role = snapshot.data!['role'];
            if (role == 'Customer') {
              return CustomerDashboard(
                name: name,
              );
            } else if (role == 'Tutor') {
              return TutorDashboard();
            }
          }

          return CustomerDashboard(name: 'user');
        },
      ),
    );
  }

  Future<Map<String, dynamic>?> navigateBasedOnRole() async {
    final user = FirebaseAuth.instance.currentUser;
    print(user);
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final res = doc.data();

      return res;
    }

    return null;
  }
}
