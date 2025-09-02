import 'package:flutter/material.dart';
import 'package:fyp25/tickets/proceed_payment.dart';

class BookTicketPage extends StatefulWidget {
  final Map<String, dynamic> ticketData;

  const BookTicketPage({Key? key, required this.ticketData}) : super(key: key);

  @override
  State<BookTicketPage> createState() => _BookTicketPageState();
}

class _BookTicketPageState extends State<BookTicketPage> {
  DateTime? selectedDate;
  Map<String, Map<String, int>> ticketQuantities = {};

  @override
  Widget build(BuildContext context) {
    final images = widget.ticketData['images'] as List<dynamic>? ?? [];
    final imageUrl = images.length > 1 ? images[1] : (images.isNotEmpty ? images[0] : '');

    final name = widget.ticketData['title'] ?? 'No Title';
    final packagesRaw = widget.ticketData['packages'];
    final packages = (packagesRaw is List) ? packagesRaw : [];

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBanner(imageUrl),
            const SizedBox(height: 16),
            Text(name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _buildDatePicker(),
            const SizedBox(height: 24),
            const Text('Ticket Categories:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...packages.map((pkg) => _buildTicketCard(pkg)).toList(),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(41, 70, 158, 1.0),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _handleBuyNow,
                icon: const Icon(Icons.shopping_cart, color: Colors.white),
                label: const Text('Buy Now', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBanner(String imageUrl) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: imageUrl.isNotEmpty
              ? Image.network(imageUrl, width: double.infinity, height: 400, fit: BoxFit.cover)
              : _imagePlaceholder(),
        ),
        Positioned(
          top: 16,
          left: 16,
          child: CircleAvatar(
            backgroundColor: Colors.black.withOpacity(0.5),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Visit Date:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickDate,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: Color.fromRGBO(41, 70, 158, 1.0)),
                const SizedBox(width: 12),
                Text(
                  selectedDate != null
                      ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                      : 'Tap to select a date',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTicketCard(Map<String, dynamic> package) {
    final packageName = package['package_name'] ?? 'Unnamed Package';
    final tickets = package['tickets'] as List<dynamic>? ?? [];

    ticketQuantities.putIfAbsent(packageName, () => {});

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(packageName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const Divider(),
            ...tickets.map((ticketData) {
              final ticket = ticketData as Map<String, dynamic>;
              final type = ticket['type'] ?? 'Unknown';
              final priceStr = ticket['price'] ?? '0';
              final price = double.tryParse(priceStr.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;

              ticketQuantities[packageName]!.putIfAbsent(type, () => 0);
              final qty = ticketQuantities[packageName]![type]!;
              final total = (qty * price).toStringAsFixed(2);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: Text(type)),
                    Expanded(flex: 2, child: Text('RM ${price.toStringAsFixed(2)}', textAlign: TextAlign.center)),
                    Expanded(
                      flex: 3,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _iconButton(Icons.remove_circle_outline, () {
                            setState(() {
                              if (qty > 0) ticketQuantities[packageName]![type] = qty - 1;
                            });
                          }),
                          Text('$qty'),
                          _iconButton(Icons.add_circle_outline, () {
                            setState(() {
                              ticketQuantities[packageName]![type] = qty + 1;
                            });
                          }),
                        ],
                      ),
                    ),
                    Expanded(flex: 2, child: Text('RM $total', textAlign: TextAlign.center)),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  void _handleBuyNow() {
    if (selectedDate == null) return _showSnackBar('Please select a date');

    final filteredTickets = <String, Map<String, int>>{};
    double totalAmount = 0.0;

    final packages = widget.ticketData['packages'] as List? ?? [];

    ticketQuantities.forEach((pkg, subs) {
      final filteredSub = <String, int>{};
      subs.forEach((type, qty) {
        if (qty > 0) {
          filteredSub[type] = qty;

          final package = packages.cast<Map<String, dynamic>>().firstWhere(
                (p) => p['package_name'] == pkg,
            orElse: () => <String, dynamic>{},
          );

          final ticketList = package['tickets'] as List? ?? [];
          final ticket = ticketList.cast<Map<String, dynamic>>().firstWhere(
                (t) => t['type'] == type,
            orElse: () => <String, dynamic>{},
          );

          final priceStr = ticket['price'] ?? '0';
          final price = double.tryParse(priceStr.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
          totalAmount += qty * price;
        }
      });
      if (filteredSub.isNotEmpty) filteredTickets[pkg] = filteredSub;
    });

    if (filteredTickets.isEmpty) return _showSnackBar('Please select at least one ticket');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentPage(
          ticketName: widget.ticketData['title'],
          ticketQuantities: filteredTickets,
          ticketPricing: widget.ticketData['packages'],
          totalAmount: totalAmount,
          selectedDate: selectedDate!,
        ),
      ),
    );
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _imagePlaceholder() => Container(
    height: 200,
    color: Colors.grey[300],
    child: const Center(child: Text('No image')),
  );

  Widget _iconButton(IconData icon, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(icon, color: const Color.fromRGBO(41, 70, 158, 1.0)),
      onPressed: onPressed,
    );
  }
}