import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tut4u/profile_page.dart';
import 'package:tut4u/screen/BookingPage.dart';
import 'package:tut4u/screen/CustomerBookingsPage.dart';
import 'package:tut4u/screen/TutorProfilePage.dart';
import 'package:tut4u/screen/login.dart';
import 'package:tut4u/components/slide_show.dart';

class CustomerDashboard extends StatefulWidget {
  final String name;

  const CustomerDashboard({super.key, required this.name});

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

  Stream<List<DocumentSnapshot>> searchTutors(String query) {
    if (query.isEmpty) {
      return getRecommendedTutors().map((snapshot) => snapshot.docs);
    }

    // Query for tutors whose name contains the query
    Stream<QuerySnapshot> nameQuery = FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'Tutor')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query\uf8ff')
        .snapshots();

    // Query for tutors whose expertise contains the query
    // Assuming 'expertise' is an array field
    Stream<QuerySnapshot> expertiseQuery = FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'Tutor')
        .where('expertise', arrayContains: query)
        .snapshots();

    // Combine the two streams and remove duplicates
    return Rx.combineLatestList([nameQuery, expertiseQuery]).map((snapshots) {
      Set<DocumentSnapshot> combinedSet = {};
      for (var snapshot in snapshots) {
        combinedSet.addAll(snapshot.docs);
      }
      return combinedSet.toList();
    });
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
            return UserProfilePage();
          }
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        onTap: (index) {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
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
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Welcome, ${widget.name}!',
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                if (user == null)
                  TextButton(
                    onPressed: () {
                      // Navigate to login page
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) => LoginPage()));
                    },
                    child: const Text(
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
                    child: const Text(
                      'Logout',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            GreatSearchBar(
              onSearch: (query) {
                setState(() {
                  _searchQuery = query;
                });
              },
              hintText: 'Find a tutor...',
              backgroundColor: Colors.grey.shade100,
              iconColor: Colors.grey.shade600,
              textColor: Colors.black,
            ),
            const SizedBox(height: 24),

            _searchQuery.isEmpty
                ? const SlideshowComponent(slides: [
                    {
                      'image': 'assets/images/banner.jpg',
                      'title': 'The place of Remarkable Tutors!'
                    },
                    {
                      'image': 'assets/images/banner2.jpg',
                      'title': 'አስጠኚን ለርሶ!!!'
                    },
                    {
                      'image': 'assets/images/banner3.png',
                      'title': 'We are here to serve you!'
                    },
                    {
                      'image': 'assets/images/banner4.jpg',
                      'title': 'No Worry With Us!'
                    },
                  ])
                : const SizedBox.shrink(),
            const SizedBox(height: 24),
            // Recommended Tutors
            Text(
              _searchQuery.isEmpty ? 'Recommended Tutors' : 'Search Results',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<DocumentSnapshot<Object?>>>(
              stream: searchTutors(_searchQuery),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No tutors found.'));
                }

                final tutors = snapshot.data!;
                print(tutors[0].data());
                return SizedBox(
                  height: 350,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: tutors.length,
                    itemBuilder: (context, index) {
                      final tutor = tutors[index];
                      final tutorData = tutor.data() as Map<String, dynamic>;
                      return SizedBox(
                          width: 300,
                          height: 350,
                          child: TutorCard(
                            tutorData: tutorData,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      TutorProfilePage(tutorId: tutor['id']),
                                ),
                              );
                            },
                            onBookNow: () {
                              navigateToBookingPage(tutorData);
                            },
                          ));
                    },
                  ),
                );
              },
            ),

            FAQSection(),
          ],
        ),
      ),
    );
  }
}

class TutorCard extends StatelessWidget {
  final Map<String, dynamic> tutorData;
  final VoidCallback onTap;
  final VoidCallback onBookNow;

  const TutorCard({
    super.key,
    required this.tutorData,
    required this.onTap,
    required this.onBookNow,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Image
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.network(
                tutorData['profileImage'],
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset(
                    'assets/images/profile.jpg',
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and Rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        tutorData['name'] ?? 'No Name',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star,
                              color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            '${tutorData['rating'] ?? '0.0'}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
            
                  // Expertise
                  Text(
                    'Expertise: ${tutorData['expertise'] ?? 'Not specified'}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),
            
                  // Book Now Button
                  ElevatedButton(
                    onPressed: onBookNow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade900,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      minimumSize: const Size(double.infinity, 0),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today,
                            size: 18, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Book Now',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GreatSearchBar extends StatefulWidget {
  final ValueChanged<String> onSearch;
  final String hintText;
  final Color backgroundColor;
  final Color iconColor;
  final Color textColor;

  const GreatSearchBar({
    super.key,
    required this.onSearch,
    this.hintText = 'Search...',
    this.backgroundColor = Colors.white,
    this.iconColor = Colors.grey,
    this.textColor = Colors.black,
  });

  @override
  _GreatSearchBarState createState() => _GreatSearchBarState();
}

class _GreatSearchBarState extends State<GreatSearchBar> {
  final TextEditingController _controller = TextEditingController();
  bool _isFocused = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onClear() {
    _controller.clear();
    widget.onSearch('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) {
        setState(() {
          _isFocused = hasFocus;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: BorderRadius.circular(30),
          boxShadow: _isFocused
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(
              Icons.search,
              color: widget.iconColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: TextStyle(color: widget.iconColor),
                  border: InputBorder.none,
                ),
                style: TextStyle(color: widget.textColor),
                onChanged: widget.onSearch,
              ),
            ),
            if (_controller.text.isNotEmpty)
              IconButton(
                icon: Icon(
                  Icons.clear,
                  color: widget.iconColor,
                ),
                onPressed: _onClear,
              ),
          ],
        ),
      ),
    );
  }
}

class FAQSection extends StatelessWidget {
  const FAQSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Frequently Asked Questions',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade900,
            ),
          ),
          const SizedBox(height: 16),
          ..._buildFAQItems(),
        ],
      ),
    );
  }

  List<Widget> _buildFAQItems() {
    final faqs = [
      {
        'question': 'How do I find a tutor?',
        'answer':
            'You can search for tutors using the search bar on the home page. Enter the subject or expertise you need help with, and browse through the list of available tutors.',
      },
      {
        'question': 'How do I book a session?',
        'answer':
            'Once you find a tutor, click on their profile and select the "Book Now" button. Choose a date and time that works for you, and confirm your booking.',
      },
      {
        'question': 'Can I reschedule a session?',
        'answer':
            'Yes, you can reschedule a session by going to your bookings page and selecting the "Reschedule" option. Make sure to notify your tutor in advance.',
      },
      {
        'question': 'What payment methods are accepted?',
        'answer':
            'We accept various payment methods, including credit/debit cards, PayPal, and mobile money. You can choose your preferred payment method during checkout.',
      },
      {
        'question': 'How do I contact customer support?',
        'answer':
            'You can reach our customer support team by emailing support@tut4u.com or calling +123-456-7890. We are available 24/7 to assist you.',
      },
    ];

    return faqs.map((faq) {
      return FAQItem(
        question: faq['question']!,
        answer: faq['answer']!,
      );
    }).toList();
  }
}

class FAQItem extends StatefulWidget {
  final String question;
  final String answer;

  const FAQItem({
    super.key,
    required this.question,
    required this.answer,
  });

  @override
  _FAQItemState createState() => _FAQItemState();
}

class _FAQItemState extends State<FAQItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        title: Text(
          widget.question,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.blue.shade900,
          ),
        ),
        trailing: Icon(
          _isExpanded ? Icons.expand_less : Icons.expand_more,
          color: Colors.blue.shade900,
        ),
        onExpansionChanged: (expanded) {
          setState(() {
            _isExpanded = expanded;
          });
        },
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              widget.answer,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
