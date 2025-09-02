import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:firebase_auth/firebase_auth.dart';

class PaymentPage extends StatefulWidget {
  final String ticketName;
  final Map<String, Map<String, int>> ticketQuantities; // e.g. { 'Ticket - Malaysian': { 'Adult': 2, 'Child': 1 } }
  final double totalAmount;
  final dynamic ticketPricing; // ✅ Changed to dynamic to support List structure
  final DateTime selectedDate;

  const PaymentPage({
    Key? key,
    required this.ticketName,
    required this.ticketQuantities,
    required this.totalAmount,
    required this.ticketPricing,
    required this.selectedDate,
  }) : super(key: key);

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _formKey = GlobalKey<FormState>();
  String name = '', phone = '', email = '';

  /// 🔁 Handle Stripe payment and call Cloud Functions
  Future<void> _startPayment() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to proceed.')),
        );
        return;
      }

      // ✅ Call Cloud Function to create payment intent
      final HttpsCallable createIntent =
      FirebaseFunctions.instance.httpsCallable('createPaymentIntent');

      final metadata = {
        'user_name': name,
        'user_phone': phone,
        'visit_date': widget.selectedDate.toIso8601String(),
        'ticket_name': widget.ticketName,
        'total_amount': widget.totalAmount.toString(),
      };

      final result = await createIntent.call({
        'amount': widget.totalAmount,
        'email': email,
        'metadata': metadata,
      });

      final clientSecret = result.data['clientSecret'];

      // ✅ Present Stripe Payment Sheet
      await stripe.Stripe.instance.initPaymentSheet(
        paymentSheetParameters: stripe.SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Melaka Booking',
        ),
      );

      await stripe.Stripe.instance.presentPaymentSheet();

      // ✅ Call backend to save booking and send email
      final HttpsCallable finalizeBooking =
      FirebaseFunctions.instance.httpsCallable('finalizeBookingAndEmail');

      await finalizeBooking.call({
        'ticketName': widget.ticketName,
        'userName': name,
        'userPhone': phone,
        'userEmail': email,
        'visitDate': widget.selectedDate.toIso8601String(),
        'ticketQuantities': widget.ticketQuantities,
        'totalAmount': widget.totalAmount,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Payment & Booking Successful!')),
      );

      Navigator.pop(context); // Optional: go back after success
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Payment failed: $e')),
      );
    }
  }

  /// 🧾 Generate ticket summary widgets dynamically
  Widget _buildTicketSummary() {
    final widgets = <Widget>[];

    widget.ticketQuantities.forEach((category, subMap) {
      widgets.add(Text(
        category,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ));

      subMap.forEach((type, qty) {
        if (qty > 0) {
          // ✅ Look for matching package by name
          final package = (widget.ticketPricing as List).firstWhere(
                (pkg) => pkg['package_name'] == category,
            orElse: () => null,
          );

          String rawPrice = '0.0';

          // ✅ If found, look for matching ticket type and extract price
          if (package != null && package['tickets'] is List) {
            final ticket = (package['tickets'] as List).firstWhere(
                  (t) => t['type'] == type,
              orElse: () => null,
            );

            if (ticket != null && ticket['price'] != null) {
              rawPrice = ticket['price'].toString();
            }
          }

          final price =
              double.tryParse(rawPrice.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;

          widgets.add(Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 6),
            child: Text('$type: $qty × RM ${price.toStringAsFixed(2)}'),
          ));
        }
      });

      widgets.add(const SizedBox(height: 8));
    });

    return Column(children: widgets);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Builder(
          builder: (context) {
            final screenWidth = MediaQuery.of(context).size.width;
            final isPhone = screenWidth < 600;

            return Text(
              'Checkout',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: isPhone ? 16 : 20,
              ),
            );
          },
        ),
        backgroundColor: const Color.fromRGBO(41, 70, 158, 1.0),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ✅ Ticket Summary
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.only(bottom: 24),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🎟️ Ticket Summary',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    _buildTicketSummary(),
                    const Divider(),
                    Text(
                      'Total Amount: RM ${widget.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Visit Date: ${widget.selectedDate.day}/${widget.selectedDate.month}/${widget.selectedDate.year}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

            /// ✅ User Info Form
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '👤 Your Information',
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // Name
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                      v == null || v.isEmpty ? 'Enter your name' : null,
                      onSaved: (v) => name = v!,
                    ),
                    const SizedBox(height: 12),

                    // Phone
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (v) =>
                      v == null || v.isEmpty ? 'Enter your phone' : null,
                      onSaved: (v) => phone = v!,
                    ),
                    const SizedBox(height: 12),

                    // Email
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => v == null || !v.contains('@')
                          ? 'Enter valid email'
                          : null,
                      onSaved: (v) => email = v!,
                    ),
                  ],
                ),
              ),
            ),

            /// ✅ Confirm & Pay Button
            Center(
              child: ElevatedButton.icon(
                onPressed: _startPayment,
                icon: const Icon(Icons.lock, color: Colors.white),
                label: const Text(
                  'Confirm & Pay',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(41, 70, 158, 1.0),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
