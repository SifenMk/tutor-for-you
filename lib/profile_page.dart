import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late String _userId;
  late String _name;
  late String _email;
  late String _phone;
  late String _address;
  late String _profileImageUrl;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      _userId = user.uid;
      final doc = await _firestore.collection('users').doc(_userId).get();
      if (doc.exists) {
        setState(() {
          _name = doc['name'];
          _email = doc['email'];

          _profileImageUrl = doc['profileImage'] ?? '';
          _nameController.text = _name;

          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateProfile() async {
    setState(() {
      _isLoading = true;
    });

    await _firestore.collection('users').doc(_userId).update({
      'name': _nameController.text,
      'phone': _phoneController.text,
      'address': _addressController.text,
    });

    setState(() {
      _isEditing = false;
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully!')),
    );
  }

  Future<void> _logout() async {
    await _auth.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: () {
              if (_isEditing) {
                _updateProfile();
              } else {
                setState(() {
                  _isEditing = true;
                });
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Profile Picture
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: _profileImageUrl.isNotEmpty
                        ? NetworkImage(_profileImageUrl)
                        : const AssetImage('assets/images/default_profile.jpg')
                            as ImageProvider,
                    child: _isEditing
                        ? const Icon(Icons.camera_alt,
                            size: 30, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(height: 20),

                  // Name Field
                  _buildEditableField(
                    label: 'Name',
                    controller: _nameController,
                    isEditing: _isEditing,
                  ),
                  const SizedBox(height: 16),

                  // Email Field (Non-editable)
                  _buildReadOnlyField(
                    label: 'Email',
                    value: _email,
                  ),
                  const SizedBox(height: 16),

                  // Phone Field
                  _buildEditableField(
                    label: 'Phone',
                    controller: _phoneController,
                    isEditing: _isEditing,
                  ),
                  SizedBox(height: 16),

                  // Address Field
                  _buildEditableField(
                    label: 'Address',
                    controller: _addressController,
                    isEditing: _isEditing,
                  ),
                  const SizedBox(height: 20),

                  // Logout Button
                  ElevatedButton(
                    onPressed: _logout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 12),
                    ),
                    child: const Text('Logout'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required bool isEditing,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          enabled: isEditing,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}
