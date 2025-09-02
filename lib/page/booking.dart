import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookingPage extends StatefulWidget {
  @override
  _BookingPageState createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final _showQr = <String, bool>{};

  /// Format the Firestore Timestamp to readable string
  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return "${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:00";
  }

  /// Build list of ticket quantities
  Widget _buildQuantities(Map<String, dynamic> quantities) {
    List<Widget> items = [];

    quantities.forEach((passType, subMap) {
      (subMap as Map<String, dynamic>).forEach((subType, value) {
        items.add(Text("• $passType - $subType: $value", style: const TextStyle(fontSize: 14)));
      });
    });

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: items);
  }

  /// Confirm dialog to delete booking
  void _confirmDeleteBooking(String bookingId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        title: const Text("Delete Ticket"),
        content: const Text("Are you sure you want to delete this booking?"),
        titleTextStyle: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
        contentTextStyle: TextStyle(
          color: isDark ? Colors.white70 : Colors.black87,
          fontSize: 16,
        ),
        actions: [
          TextButton(
            child: Text("Cancel", style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[800])),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete_forever, size: 18),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            label: const Text("Delete"),
            onPressed: () async {
              await FirebaseFirestore.instance.collection("booking").doc(bookingId).delete();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Booking deleted.")),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Build a single booking card
  Widget _buildBookingCard(String bookingId, Map<String, dynamic> data, {bool isPast = false}) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Ticket title and delete icon in same row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    "🎟 Ticket: ${data['ticket_name'] ?? 'N/A'}",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isPast)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: 'Delete Ticket',
                    onPressed: () => _confirmDeleteBooking(bookingId),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            const Text("🧾 Quantities:", style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            _buildQuantities(Map<String, dynamic>.from(data['ticket_quantities'] ?? {})),

            const Divider(height: 24),

            Text("📅 Visit Date: ${_formatDate(data['visit_date'])}"),
            const SizedBox(height: 4),
            Text("💰 Total Paid: RM ${(data['total_amount'] ?? 0).toStringAsFixed(2)}"),
            const SizedBox(height: 4),

            /// Name with support for long names
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("👤 Name: ", style: TextStyle(fontWeight: FontWeight.w500)),
                Expanded(
                  child: Text(
                    data['user_name'] ?? 'N/A',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            /// QR Toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _showQr[bookingId] == true ? "🔓 QR Code Shown" : "🔐 QR Code Hidden",
                  style: const TextStyle(color: Colors.grey),
                ),
                TextButton.icon(
                  icon: Icon(_showQr[bookingId] == true ? Icons.visibility_off : Icons.qr_code),
                  label: Text(_showQr[bookingId] == true ? 'Hide QR Code' : 'Show QR Code'),
                  onPressed: () {
                    setState(() {
                      _showQr[bookingId] = !(_showQr[bookingId] ?? false);
                    });
                  },
                ),
              ],
            ),

            if (_showQr[bookingId] == true && data['qr_url'] != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Image.network(
                    data['qr_url'],
                    width: 180,
                    height: 180,
                    errorBuilder: (_, __, ___) => const Text("⚠️ Failed to load QR"),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Build the full page
  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
            title: Builder(
              builder: (context) {
                final screenWidth = MediaQuery.of(context).size.width;
                final isPhone = screenWidth < 600;

                return Text(
                  'Booking',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: isPhone ? 16 : 20, // 👈 Adjust size based on screen
                  ),
                );
              },
            ),
        backgroundColor: const Color.fromRGBO(41, 70, 158, 1.0),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: currentUser == null
          ? const Center(child: Text("You must be logged in to see your bookings."))
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("booking")
            .where("uid", isEqualTo: currentUser.uid)
            .orderBy("visit_date", descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Error loading bookings"));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final bookings = snapshot.data!.docs;
          if (bookings.isEmpty) return const Center(child: Text("No bookings found"));

          final now = DateTime.now();
          final upcoming = bookings.where((doc) {
            final visitDate = (doc['visit_date'] as Timestamp?)?.toDate();
            return visitDate != null && visitDate.isAfter(now);
          }).toList();

          final past = bookings.where((doc) {
            final visitDate = (doc['visit_date'] as Timestamp?)?.toDate();
            return visitDate != null && visitDate.isBefore(now);
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              /// Upcoming Section
              const Center(child: Text("📌 New Booking", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              const SizedBox(height: 10),
              if (upcoming.isNotEmpty)
                _buildBookingCard(upcoming.first.id, upcoming.first.data() as Map<String, dynamic>)
              else
                Column(
                  children: [
                    Image.asset(
                      'assets/background/kitty.png',
                      width: 100,
                      height: 100,
                      errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, size: 60, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    const Text("No upcoming booking found 🐾", style: TextStyle(fontSize: 16, color: Colors.grey)),
                  ],
                ),
              const SizedBox(height: 30),

              /// Past Section
              const Center(child: Text("📅 Previous Bookings", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              const SizedBox(height: 10),
              if (past.isNotEmpty)
                ...past.reversed.map((doc) => _buildBookingCard(doc.id, doc.data() as Map<String, dynamic>, isPast: true)).toList()
              else
                const Text("No previous bookings."),
            ],
          );
        },
      ),
    );
  }
}
