import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tut4u/components/BookingCard.dart';
import 'package:tut4u/screen/login.dart';

class TutorDashboard extends StatefulWidget {
  const TutorDashboard({super.key});

  @override
  _TutorDashboardState createState() => _TutorDashboardState();
}

class _TutorDashboardState extends State<TutorDashboard> {
  Future<Map<String, dynamic>?> fetchTutorProfile() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return null;

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return doc.data();
  }

  Future<void> updateTutorProfile(Map<String, dynamic> updatedData) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update(updatedData);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully!')),
    );
    setState(() {});
  }

  Stream<QuerySnapshot> fetchTutorBookings() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    return FirebaseFirestore.instance
        .collection('bookings')
        .where('tutorId', isEqualTo: userId)
        .snapshots();
  }

  void showEditProfileDialog(Map<String, dynamic> profileData) {
    final nameController = TextEditingController(text: profileData['name']);
    final expertiseController =
        TextEditingController(text: profileData['expertise']);
    final bioController = TextEditingController(text: profileData['bio']);
    final hourlyRateController =
        TextEditingController(text: profileData['hourlyRate']?.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: expertiseController,
                  decoration: const InputDecoration(labelText: 'Expertise'),
                ),
                TextField(
                  controller: bioController,
                  decoration: const InputDecoration(labelText: 'Bio'),
                ),
                TextField(
                  controller: hourlyRateController,
                  decoration: const InputDecoration(labelText: 'Hourly Rate (\$)'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final updatedData = {
                  'expertise': expertiseController.text.trim(),
                  'bio': bioController.text.trim(),
                  'hourlyRate':
                      double.tryParse(hourlyRateController.text.trim()) ?? 0.0,
                };
                await updateTutorProfile(updatedData);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void showEditFieldDialog(String fieldKey, String currentValue) {
    final controller = TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit $fieldKey'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: 'Enter your $fieldKey',
            ),
            maxLines: fieldKey == 'bio' ? 5 : 1,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final updatedValue = controller.text.trim();
                if (updatedValue.isNotEmpty) {
                  await updateTutorProfile({fieldKey: updatedValue});
                }
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tutor Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blue.shade900,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => LoginPage(),
                ),
                (context) => false,
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: fetchTutorProfile(),
        builder: (context, profileSnapshot) {
          if (profileSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!profileSnapshot.hasData || profileSnapshot.data == null) {
            return const Center(child: Text('Failed to load profile.'));
          }

          final tutorProfile = profileSnapshot.data!;
          final profileFields = [
            {'label': 'Name', 'key': 'name'},
            {'label': 'Expertise', 'key': 'expertise'},
            {'label': 'Bio', 'key': 'bio'},
            {'label': 'Hourly Rate', 'key': 'hourlyRate'},
          ];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tutor Profile Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: NetworkImage(
                            tutorProfile['profileImage'] ??
                                'https://via.placeholder.com/150',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tutorProfile['name'] ?? 'Tutor Name',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Chip(
                                label: Text(
                                  'Expertise: ${tutorProfile['expertise']}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                backgroundColor: Colors.blue.shade100,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Bio: ${tutorProfile['bio']}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.attach_money, color: Colors.green),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Hourly Rate: \$${tutorProfile['hourlyRate']}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.star,
                                      color: Colors.amber, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Rating: ${tutorProfile['rating']}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Profile Details Section
                Text(
                  'Profile Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
                const SizedBox(height: 16),


                
                ...profileFields.map((field) {
                  final fieldKey = field['key'];
                  final fieldLabel = field['label'];
                  final fieldValue = tutorProfile[fieldKey] ?? 'Not defined';

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      title: Text(
                        '$fieldLabel: $fieldValue',
                        style: const TextStyle(fontSize: 16),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue.shade900),
                        onPressed: () => showEditFieldDialog(
                            fieldKey!, fieldValue.toString()),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 24),

                // Bookings Section
                Text(
                  'Bookings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
                const SizedBox(height: 16),
                StreamBuilder<QuerySnapshot>(
                  stream: fetchTutorBookings(),
                  builder: (context, bookingsSnapshot) {
                    if (bookingsSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!bookingsSnapshot.hasData ||
                        bookingsSnapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No bookings available.'));
                    }

                    final bookings = bookingsSnapshot.data!.docs;

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: bookings.length,
                      itemBuilder: (context, index) {
                        final booking = bookings[index];
                        final bookingData =
                            booking.data() as Map<String, dynamic>;

                        return BookingCard(
                          bookingData: bookingData,
                          bookingId: booking.id,
                          isTutor: true,
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
