import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tut4u/screen/BookingPage.dart';
import 'package:tut4u/screen/CustomerBookingsPage.dart';
import 'package:tut4u/screen/TutorProfilePage.dart';
import 'package:tut4u/screen/login.dart';
import 'package:tut4u/components/slide_show.dart';

class CustomerDashboard extends StatefulWidget {
  final String name;

  CustomerDashboard({required this.name});

  @override
  _CustomerDashboardState createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final PageController _pageController = PageController();
  int _currentPage = 0;

  Stream<QuerySnapshot> getRecommendedTutors() {
    return FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'Tutor')
        // .orderBy('rating', descending: true)
        .limit(5)
        .snapshots();
  }

  Stream<QuerySnapshot> searchTutors(String query) {
    if (query.isEmpty) {
      return getRecommendedTutors();
    }
    return FirebaseFirestore.instance
        .collection('users')
        .where(Filter.or(
          Filter.and(
            Filter(
              'name',
              isGreaterThanOrEqualTo: query,
            ),
            Filter('name', isLessThanOrEqualTo: '${query}\uf8ff'),
          ),
          Filter.and(
            Filter(
              'expertise',
              isGreaterThanOrEqualTo: query,
            ),
            Filter('expertise', isLessThanOrEqualTo: '$query\uf8ff'),
          ),
        ))
        // .where('name', isGreaterThanOrEqualTo: query)
        // .where('name', isLessThanOrEqualTo: query + '\uf8ff')
        .snapshots();
  }

  Stream<QuerySnapshot> getUpcomingBookings() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    return FirebaseFirestore.instance
        .collection('bookings')
        .where('customerId', isEqualTo: userId)
        .snapshots();
  }

  void navigateToBookingPage(Map<String, dynamic> tutorData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingPage(tutorData: tutorData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: PageView.builder(
        controller: _pageController,
        itemBuilder: (context, index) {
          if (index == 0) {
            return homePage();
          } else if (index == 1) {
            return CustomerBookingsPage();
          } else {
            return Center(
              child: Text('Profile Page'),
            );
          }
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        onTap: (index) {
          _pageController.animateToPage(
            index,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
          setState(() {
            _currentPage = index;
          });
        },

        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home,
                color: _currentPage == 0 ? Colors.blue : Colors.grey),
            label: 'Home',
            backgroundColor: _currentPage == 0 ? Colors.blue : Colors.grey,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month,
                color: _currentPage == 1 ? Colors.blue : Colors.grey),
            label: 'Messages',
            backgroundColor: _currentPage == 1 ? Colors.blue : Colors.grey,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person,
                color: _currentPage == 2 ? Colors.blue : Colors.grey),
            label: 'Profile',
            backgroundColor: _currentPage == 2 ? Colors.blue : Colors.grey,
          ),
        ],
        currentIndex: 0, // Default to 'Home'
      ),
    );
  }

  Widget homePage() {
    final user = FirebaseAuth.instance.currentUser;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Message
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Welcome, ${widget.name}!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                if (user == null)
                  TextButton(
                    onPressed: () {
                      // Navigate to login page
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) => LoginPage()));
                    },
                    child: Text(
                      'Login',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                if (user != null)
                  TextButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) => LoginPage()));
                    },
                    child: Text(
                      'Logout',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 16),

            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Find a tutor...',
                prefixIcon: Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                ),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            SizedBox(height: 24),

            _searchQuery.isEmpty
                ? const SlideshowComponent(slides: [
                    {
                      'image': 'assets/images/banner.jpg',
                      'title': 'The place of Remarkable Tutors!'
                    },
                    {
                      'image': 'assets/images/banner.jpg',
                      'title': 'አስጠኚን ለርሶ!!!'
                    },
                    {
                      'image': 'assets/images/banner.jpg',
                      'title': 'We are here to serve you!'
                    },
                    {
                      'image': 'assets/images/banner.jpg',
                      'title': 'No Worry With Us!'
                    },
                  ])
                : SizedBox.shrink(),

            // Search Results or Recommended Tutors
            Text(
              _searchQuery.isEmpty ? 'Recommended Tutors' : 'Search Results',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: searchTutors(_searchQuery),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No tutors found.'));
                }

                final tutors = snapshot.data!.docs;
                print(tutors[0].data());
                return SizedBox(
                  height: 300,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: tutors.length,
                    itemBuilder: (context, index) {
                      final tutor = tutors[index];
                      final tutorData = tutor.data() as Map<String, dynamic>;
                      return SizedBox(
                        width: 300,
                        height: 300,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TutorProfilePage(
                                  tutorId: tutor['id'],
                                ),
                              ),
                            );
                          },
                          child: Container(
                            margin: EdgeInsets.only(right: 16),
                            padding: EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10.0),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Image.network(
                                  "${tutorData['profileImage']}",
                                  height: 150,
                                  width: 300,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.asset(
                                      'assets/images/profile.jpg',
                                      height: 150,
                                      width: 300,
                                    );
                                  },
                                ),
                                const SizedBox(width: 24),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      tutorData['name'] ?? 'No Name',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Icon(Icons.star,
                                            color: Colors.orange, size: 16),
                                        SizedBox(width: 4),
                                        Text(
                                          '${tutorData['rating']}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Expertise: ${tutorData['expertise']}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Spacer(),
                                ElevatedButton(
                                  onPressed: () =>
                                      navigateToBookingPage(tutorData),
                                  child: Text('Book Now'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    minimumSize: Size(double.infinity,
                                        36), // Stretch button to full width
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
