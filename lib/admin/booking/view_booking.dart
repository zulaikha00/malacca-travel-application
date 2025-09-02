import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ViewBookingPage extends StatelessWidget {
  final Map<String, dynamic> bookingData;

  const ViewBookingPage({super.key, required this.bookingData});

  @override
  Widget build(BuildContext context) {
    // Extract data safely
    final String userName = bookingData['user_name'] ?? 'N/A';
    final String userEmail = bookingData['user_email'] ?? 'N/A';
    final String userPhone = bookingData['user_phone'] ?? 'N/A';
    final String ticketName = bookingData['ticket_name'] ?? 'N/A';
    final Map ticketQuantities = bookingData['ticket_quantities'] ?? {};
    final int totalAmount = bookingData['total_amount'] ?? 0;
    final String qrUrl = bookingData['qr_url'] ?? '';
    final DateTime visitDate = bookingData['visit_date']?.toDate() ?? DateTime.now();
    final String formattedVisitDate = DateFormat.yMMMEd().format(visitDate);

    return Scaffold(
      appBar: AppBar(
          title: Builder(
            builder: (context) {
              final screenWidth = MediaQuery.of(context).size.width;
              final isPhone = screenWidth < 600;

              return Text(
                'Booking Details',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: isPhone ? 16 : 20, // 👈 Adjust size based on screen
                ),
              );
            },
          ),
        backgroundColor: Color.fromRGBO(41, 70, 158, 1.0),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // 🎟️ Ticket name
            Text(
              ticketName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // 👤 User Info
            _infoRow('Name', userName),
            _infoRow('Email', userEmail),
            _infoRow('Phone', userPhone),
            _infoRow('Visit Date', formattedVisitDate),
            const Divider(height: 30),

            // 📦 Ticket Quantities
            const Text(
              'Tickets:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...ticketQuantities.entries.map((entry) {
              final category = entry.key;
              final subItems = entry.value as Map;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('- $category', style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  ...subItems.entries.map((sub) => Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Text('${sub.key}: ${sub.value} pcs'),
                  )),
                  const SizedBox(height: 8),
                ],
              );
            }),

            const Divider(height: 30),

            // 💵 Total Amount
            _infoRow('Total Amount', 'RM $totalAmount'),

            const SizedBox(height: 24),

            // 🔳 QR Code
            if (qrUrl.isNotEmpty) ...[
              const Text(
                'Booking QR Code:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Center(
                child: Image.network(
                  qrUrl,
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                  const Text('Failed to load QR code'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 🧾 Reusable row to show label and value
  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
