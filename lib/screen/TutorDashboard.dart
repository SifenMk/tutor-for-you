import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tut4u/components/BookingCard.dart';
import 'package:tut4u/screen/login.dart';

class TutorDashboard extends StatefulWidget {
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
      SnackBar(content: Text('Profile updated successfully!')),
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
          title: Text('Edit Profile'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: expertiseController,
                  decoration: InputDecoration(labelText: 'Expertise'),
                ),
                TextField(
                  controller: bioController,
                  decoration: InputDecoration(labelText: 'Bio'),
                ),
                TextField(
                  controller: hourlyRateController,
                  decoration: InputDecoration(labelText: 'Hourly Rate (\$)'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
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
              child: Text('Save'),
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
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final updatedValue = controller.text.trim();
                if (updatedValue.isNotEmpty) {
                  await updateTutorProfile({fieldKey: updatedValue});
                }
                Navigator.pop(context);
              },
              child: Text('Save'),
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
        title: Text('Tutor Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
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
            return Center(child: CircularProgressIndicator());
          }

          if (!profileSnapshot.hasData || profileSnapshot.data == null) {
            return Center(child: Text('Failed to load profile.'));
          }

          final tutorProfile = profileSnapshot.data!;
          final profileFields = [
            {'label': 'Name', 'key': 'name'},
            {'label': 'Expertise', 'key': 'expertise'},
            {'label': 'Bio', 'key': 'bio'},
            {'label': 'Hourly Rate', 'key': 'hourlyRate'},
          ];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tutor Profile Section
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade50, width: 1.5),
                ),
                padding: EdgeInsets.all(16.0),
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: NetworkImage(
                          tutorProfile['profileImage'] ??
                              'https://via.placeholder.com/150'),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (tutorProfile['name'] != null)
                            Text(
                              tutorProfile['name'],
                              style: TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                          SizedBox(height: 8),
                          if (tutorProfile['expertise'] != null)
                            Chip(
                              label: Text(
                                'Expertise: ${tutorProfile['expertise']}',
                                style: TextStyle(fontSize: 16),
                              ),
                              backgroundColor: Colors.blue.shade100,
                            ),
                          SizedBox(height: 4),
                          if (tutorProfile['bio'] != null)
                            Text(
                              'Bio: ${tutorProfile['bio']}',
                              style: TextStyle(fontSize: 16),
                            ),
                          SizedBox(height: 4),
                          if (tutorProfile['hourlyRate'] != null)
                            Row(
                              children: [
                                Icon(Icons.attach_money, color: Colors.green),
                                SizedBox(width: 4),
                                Text(
                                  'Hourly Rate: \$${tutorProfile['hourlyRate']}',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          SizedBox(height: 4),
                          if (tutorProfile['rating'] != null)
                            Row(
                              children: [
                                Text(
                                  'Rating: ${tutorProfile['rating']}',
                                  style: TextStyle(fontSize: 16),
                                ),
                                Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 16,
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),

              // Profile Details Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: profileFields.map((field) {
                    final fieldKey = field['key'];
                    final fieldLabel = field['label'];
                    final fieldValue = tutorProfile[fieldKey] ?? 'Not defined';

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$fieldLabel: $fieldValue',
                            style: TextStyle(fontSize: 16),
                          ),
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () => showEditFieldDialog(
                                fieldKey!, fieldValue.toString()),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Bookings Section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Bookings',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: fetchTutorBookings(),
                  builder: (context, bookingsSnapshot) {
                    if (bookingsSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    if (!bookingsSnapshot.hasData ||
                        bookingsSnapshot.data!.docs.isEmpty) {
                      return Center(child: Text('No bookings available.'));
                    }

                    final bookings = bookingsSnapshot.data!.docs;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: ListView.builder(
                        itemCount: bookings.length,
                        itemBuilder: (context, index) {
                          final booking = bookings[index];
                          final bookingData =
                              booking.data() as Map<String, dynamic>;

                          return BookingCard(
                              bookingData: bookingData,
                              bookingId: booking.id,
                              isTutor: true);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
