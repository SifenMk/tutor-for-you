import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingCard extends StatefulWidget {
  final Map<String, dynamic> bookingData;
  final bool isTutor;
  final String bookingId;

  const BookingCard({
    super.key,
    required this.bookingData,
    required this.bookingId,
    this.isTutor = false,
  });

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

      // ignore: use_build_context_synchronously
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

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking canceled successfully.')),
      );
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cancel booking: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row (Profile Picture, Name, and Popup Menu)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(
                      widget.bookingData['tutorPhotoUrl'] ??
                          'https://via.placeholder.com/150',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.isTutor
                        ? widget.bookingData['customerName'] ?? 'Customer'
                        : widget.bookingData['tutorName'],
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ],
              ),
              PopupMenuButton<String>(
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
                          title: const Text('Reschedule Booking'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                controller: newDateController,
                                decoration: const InputDecoration(
                                  labelText: 'New Date (e.g., 2024-12-30)',
                                ),
                              ),
                              TextField(
                                controller: newTimeController,
                                decoration: const InputDecoration(
                                  labelText: 'New Time (e.g., 10:00 AM)',
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
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
                                    // ignore: use_build_context_synchronously
                                    Navigator.pop(context);
                                    // ignore: use_build_context_synchronously
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Booking rescheduled successfully.'),
                                      ),
                                    );
                                  } catch (e) {
                                    // ignore: use_build_context_synchronously
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Failed to reschedule booking: $e'),
                                      ),
                                    );
                                  }
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Please provide both date and time.'),
                                    ),
                                  );
                                }
                              },
                              child: const Text('Reschedule'),
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
                  const PopupMenuItem(
                    value: 'Confirm',
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Confirm Booking'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'Reschedule',
                    child: Row(
                      children: [
                        Icon(Icons.schedule, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('Reschedule'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'Cancel',
                    child: Row(
                      children: [
                        Icon(Icons.cancel, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Cancel Booking'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Booking Details
          _buildDetailRow(
            icon: Icons.calendar_today,
            label: 'Date',
            value: widget.bookingData['date'],
          ),
          _buildDetailRow(
            icon: Icons.access_time,
            label: 'Time',
            value: widget.bookingData['time'],
          ),
          _buildDetailRow(
            icon: Icons.info,
            label: 'Status',
            value: widget.bookingData['status'],
            valueColor: widget.bookingData['status'] == 'confirmed' ||
                    widget.bookingData['status'] == 'completed' ||
                    widget.bookingData['status'] == 'accepted'
                ? Colors.green
                : widget.bookingData['status'] == 'rescheduled'
                    ? Colors.orange
                    : widget.bookingData['status'] == 'pending'
                        ? Colors.blue
                        : Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 20),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: valueColor ?? Colors.grey.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
