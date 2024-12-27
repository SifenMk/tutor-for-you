import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingCard extends StatefulWidget {
  final Map<String, dynamic> bookingData;
  final bool isTutor;
  final String bookingId;

  BookingCard(
      {required this.bookingData,
      required this.bookingId,
      this.isTutor = false});

  @override
  State<BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<BookingCard> {
  Future<void> updateBookingStatus(String bookingId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({'status': newStatus});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking status updated to $newStatus.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e')),
      );
    }
  }

  Future<void> cancelBooking(String bookingId) async {
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking canceled successfully.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cancel booking: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 8.0),
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(
                        widget.bookingData['tutorPhotoUrl'] ??
                            'https://via.placeholder.com/150'),
                  ),
                  SizedBox(width: 10),
                  Text(
                    widget.isTutor
                        ? widget.bookingData['customerName']
                        : widget.bookingData['tutorName'],
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'Reschedule') {
                      showDialog(
                        context: context,
                        builder: (context) {
                          TextEditingController newDateController =
                              TextEditingController();
                          TextEditingController newTimeController =
                              TextEditingController();

                          return AlertDialog(
                            title: Text('Reschedule Booking'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextField(
                                  controller: newDateController,
                                  decoration: InputDecoration(
                                      labelText: 'New Date (e.g., 2024-12-30)'),
                                ),
                                TextField(
                                  controller: newTimeController,
                                  decoration: InputDecoration(
                                      labelText: 'New Time (e.g., 10:00 AM)'),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  if (newDateController.text.isNotEmpty &&
                                      newTimeController.text.isNotEmpty) {
                                    try {
                                      await FirebaseFirestore.instance
                                          .collection('bookings')
                                          .doc(widget.bookingId)
                                          .update({
                                        'date': newDateController.text.trim(),
                                        'time': newTimeController.text.trim(),
                                        'status': 'rescheduled',
                                      });
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'Booking rescheduled successfully.')),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'Failed to reschedule booking: $e')),
                                      );
                                    }
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Please provide both date and time.')),
                                    );
                                  }
                                },
                                child: Text('Reschedule'),
                              ),
                            ],
                          );
                        },
                      );
                    } else if (value == 'Cancel') {
                      cancelBooking(widget.bookingId);
                    } else if (value == 'Confirm') {
                      updateBookingStatus(widget.bookingId, 'confirmed');
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                        value: 'Confirm', child: Text('Confirm Booking')),
                    PopupMenuItem(
                        value: 'Reschedule', child: Text('Reschedule')),
                    PopupMenuItem(
                        value: 'Cancel', child: Text('Cancel Booking')),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.grey),
              SizedBox(width: 5),
              Text(
                'Date: ${widget.bookingData['date']}',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
          SizedBox(height: 5),
          Row(
            children: [
              Icon(Icons.access_time, color: Colors.grey),
              SizedBox(width: 5),
              Text(
                'Time: ${widget.bookingData['time']}',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
          SizedBox(height: 5),
          Row(
            children: [
              Icon(Icons.info, color: Colors.grey),
              SizedBox(width: 5),
              Text(
                'Status: ${widget.bookingData['status']}',
                style: TextStyle(
                  fontSize: 16,
                  color: widget.bookingData['status'] == 'confirmed' ||
                          widget.bookingData['status'] == 'completed' ||
                          widget.bookingData['status'] == 'accepted'
                      ? Colors.green
                      : widget.bookingData['status'] == 'rescheduled'
                          ? Colors.orange
                          : widget.bookingData['status'] == 'pending'
                              ? Colors.blue
                              : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
