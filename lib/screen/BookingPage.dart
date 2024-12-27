import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookingPage extends StatefulWidget {
  final Map<String, dynamic> tutorData;

  BookingPage({required this.tutorData});

  @override
  _BookingPageState createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = "${picked.toLocal()}".split(' ')[0];
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _timeController.text = picked.format(context);
      });
    }
  }

  Future<void> bookTutor() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You need to be logged in to book a tutor.')),
        );
        return;
      }

      print(widget.tutorData['id']);
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final customerId = user.uid;
      final customerName = doc['name'] ?? 'Customer Name';
      final tutorId = widget.tutorData['id'];
      final tutorName = widget.tutorData['name'];
      final date = _dateController.text.trim();
      final time = _timeController.text.trim();

      if (date.isEmpty || time.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please fill in all fields.')),
        );
        return;
      }

      // Check if booking conflicts exist (Optional)
      final existingBookings = await FirebaseFirestore.instance
          .collection('bookings')
          .where('tutorId', isEqualTo: tutorId)
          .where('date', isEqualTo: date)
          .where('time', isEqualTo: time)
          .get();

      if (existingBookings.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('The tutor is not available at this time.')),
        );
        return;
      }

      // Create booking
      await FirebaseFirestore.instance.collection('bookings').add({
        'customerId': customerId,
        'customerName': customerName,
        'tutorId': tutorId,
        'tutorName': tutorName,
        'date': date,
        'time': time,
        'status': 'pending', // Optional field
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking confirmed!')),
      );

      Navigator.pop(context); // Go back to the previous screen
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to book tutor: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book Tutor'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tutor Details
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage(widget.tutorData['photoUrl'] ??
                      'https://via.placeholder.com/150'),
                ),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.tutorData['name'] ?? 'Tutor Name',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text('Expertise: ${widget.tutorData['expertise']}'),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.orange),
                        Text('${widget.tutorData['rating']}'),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 24),

            // Booking Form
            Text(
              'Schedule a Session',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _dateController,
              decoration: InputDecoration(
                labelText: 'Preferred Date (e.g., 2024-12-30)',
                border: OutlineInputBorder(),
              ),
              readOnly: true,
              onTap: () => _selectDate(context),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _timeController,
              decoration: InputDecoration(
                labelText: 'Preferred Time (e.g., 10:00 AM)',
                border: OutlineInputBorder(),
              ),
              readOnly: true,
              onTap: () => _selectTime(context),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: bookTutor,
              child: Text('Confirm Booking'),
            ),
          ],
        ),
      ),
    );
  }
}
