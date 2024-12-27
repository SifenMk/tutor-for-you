import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class TutorProfilePage extends StatefulWidget {
  final String tutorId;

  TutorProfilePage({required this.tutorId});

  @override
  _TutorProfilePageState createState() => _TutorProfilePageState();
}

class _TutorProfilePageState extends State<TutorProfilePage> {
  late Future<Map<String, dynamic>?> tutorDetailsFuture;
  double? userRating;

  @override
  void initState() {
    super.initState();
    tutorDetailsFuture = fetchTutorDetails();
  }

  Future<Map<String, dynamic>?> fetchTutorDetails() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.tutorId)
        .get();
    return doc.data();
  }

  Future<void> submitRating(double rating) async {
    final ratingsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.tutorId)
        .collection('ratings');

    // Save the user's rating
    await ratingsRef
        .add({'rating': rating, 'timestamp': FieldValue.serverTimestamp()});

    // Recalculate and update the average rating
    final ratingsSnapshot = await ratingsRef.get();
    final ratings =
        ratingsSnapshot.docs.map((doc) => doc['rating'] as double).toList();
    final averageRating = ratings.reduce((a, b) => a + b) / ratings.length;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.tutorId)
        .update({'rating': averageRating});

    setState(() {
      tutorDetailsFuture = fetchTutorDetails();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tutor Profile'),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: tutorDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: Text('Tutor details not found.'));
          }

          final tutorDetails = snapshot.data!;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header Section
                Stack(
                  children: [
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue, Colors.blueAccent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 50,
                      left: MediaQuery.of(context).size.width / 2 - 50,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: NetworkImage(
                            tutorDetails['profileImage'] ??
                                'https://via.placeholder.com/150'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // Tutor Name and Rating
                Center(
                  child: Column(
                    children: [
                      Text(
                        tutorDetails['name'] ?? 'Name not available',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, color: Colors.amber),
                          SizedBox(width: 4),
                          Text(
                            '${tutorDetails['rating'] ?? 'N/A'}',
                            style: TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),

                // Bio Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About Me',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        tutorDetails['bio'] ?? 'Bio not available',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),

                // Expertise Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Expertise',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        tutorDetails['expertise'] ?? 'Expertise not available',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),

                // Hourly Rate Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hourly Rate',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        tutorDetails['hourlyRate'] != null
                            ? '\$${tutorDetails['hourlyRate']}/hour'
                            : 'Rate not available',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),

                // Contact Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Contact',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        tutorDetails['email'] ?? 'Email not available',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
                // Rating Section
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rate this Tutor',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Center(
                        child: RatingBar.builder(
                          initialRating: userRating ?? 0,
                          minRating: 1,
                          direction: Axis.horizontal,
                          allowHalfRating: true,
                          itemCount: 5,
                          itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
                          itemBuilder: (context, _) => Icon(
                            Icons.star,
                            color: Colors.amber,
                          ),
                          onRatingUpdate: (rating) {
                            setState(() {
                              userRating = rating;
                            });
                          },
                        ),
                      ),
                      SizedBox(height: 16),
                      Center(
                        child: ElevatedButton(
                          onPressed: userRating != null
                              ? () async {
                                  await submitRating(userRating!);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text('Thank you for rating!')),
                                  );
                                }
                              : null,
                          child: Text('Submit Rating'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
