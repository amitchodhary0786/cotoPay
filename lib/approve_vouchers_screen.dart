import 'package:flutter/material.dart';
import 'dart:math';

class ApproveVouchersScreen extends StatefulWidget {
  const ApproveVouchersScreen({super.key});

  @override
  State<ApproveVouchersScreen> createState() => _ApproveVouchersScreenState();
}

class _ApproveVouchersScreenState extends State<ApproveVouchersScreen> {
  // sample data — replace with your API data
  final List<Map<String, dynamic>> _items = [
    {
      'title': 'Meal Voucher',
      'name': 'Ramesh Kumar',
      'number': '9873949123',
      'amount': '₹1,000',
      'approvedBy': '-',
      'remarks': 'Voucher needed for lunch with the team',
      'checked': true,
    },
    {
      'title': 'Meal Voucher',
      'name': 'Ramesh Kumar',
      'number': '9873949123',
      'amount': '₹1,000',
      'approvedBy': '-',
      'remarks': 'Voucher needed for lunch with the team',
      'checked': false,
    },
  ];

  // helper to clamp values for responsive sizes
  double clampDouble(double value, double min, double max) => value.clamp(min, max);

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;

    final horizontalPadding = clampDouble(sw * 0.04, 12, 24);
    final titleFont = clampDouble(sw * 0.05, 16, 20);
    final bodyFont = clampDouble(sw * 0.038, 13, 16);
    final smallFont = clampDouble(sw * 0.032, 11, 14);
    final iconSize = clampDouble(sw * 0.06, 20, 28);
    final cardRadius = clampDouble(sw * 0.04, 12, 18);
    final pillRadius = 999.0;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: horizontalPadding,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'Approve Vouchers',
          style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: horizontalPadding * 0.8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "List of Approved Vouchers – Approve or Reject the voucher requests below.",
              style: TextStyle(fontSize: bodyFont, color: Colors.black87),
            ),
            SizedBox(height: horizontalPadding),

            // list
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.only(bottom: max(120, sh * 0.12)),
                itemCount: _items.length,
                separatorBuilder: (_, __) => SizedBox(height: horizontalPadding * 0.9),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return _voucherCard(
                    context,
                    title: item['title'],
                    name: item['name'],
                    number: item['number'],
                    amount: item['amount'],
                    approvedBy: item['approvedBy'],
                    remarks: item['remarks'],
                    checked: item['checked'] as bool,
                    onCheckedChanged: (val) => setState(() => _items[index]['checked'] = val),
                    cardRadius: cardRadius,
                    iconSize: iconSize,
                    titleFont: titleFont,
                    bodyFont: bodyFont,
                    smallFont: smallFont,
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // fixed bottom buttons
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(horizontalPadding, 12, horizontalPadding, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _onRejectPressed,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade600,
                    side: BorderSide(color: Colors.red.shade200, width: 1.5),
                    padding: EdgeInsets.symmetric(vertical: clampDouble(12, 10, 16)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(pillRadius)),
                    backgroundColor: Colors.white,
                    elevation: 0,
                  ),
                  child: Text('Reject', style: TextStyle(color: Colors.red.shade600, fontSize: bodyFont, fontWeight: FontWeight.w600)),
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: ElevatedButton(
                  onPressed: _onApprovePressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3366FF), // blue
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: clampDouble(12, 10, 16)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(pillRadius)),
                    elevation: 0,
                  ),
                  child: Text('Approve', style: TextStyle(fontSize: bodyFont, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _voucherCard(
      BuildContext context, {
        required String title,
        required String name,
        required String number,
        required String amount,
        required String approvedBy,
        required String remarks,
        required bool checked,
        required void Function(bool?) onCheckedChanged,
        required double cardRadius,
        required double iconSize,
        required double titleFont,
        required double bodyFont,
        required double smallFont,
      }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: EdgeInsets.all(cardRadius * 0.8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // top row: icon + title + checkbox
            Row(
              children: [
                // square icon box
                Container(
                  width: iconSize + 6,
                  height: iconSize + 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F3F6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.receipt_long, size: iconSize * 0.95, color: Colors.black54),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(title, style: TextStyle(fontSize: titleFont * 0.95, fontWeight: FontWeight.w700, color: Colors.black87)),
                ),

                // checkbox at top-right
                Checkbox(
                  value: checked,
                  onChanged: onCheckedChanged,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  activeColor: const Color(0xFF3366FF),
                ),
              ],
            ),

            SizedBox(height: 10),

            // Name / Number row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // left column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Name', style: TextStyle(fontSize: smallFont, color: Colors.grey.shade600)),
                      SizedBox(height: 4),
                      Text(name, style: TextStyle(fontSize: bodyFont, fontWeight: FontWeight.w600, color: Colors.black87)),
                    ],
                  ),
                ),

                // right column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Number', style: TextStyle(fontSize: smallFont, color: Colors.grey.shade600)),
                      SizedBox(height: 4),
                      Text(number, style: TextStyle(fontSize: bodyFont, fontWeight: FontWeight.w600, color: Colors.black87)),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 8),

            // Amount / Approved by
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Amount', style: TextStyle(fontSize: smallFont, color: Colors.grey.shade600)),
                      SizedBox(height: 4),
                      Text(amount, style: TextStyle(fontSize: bodyFont, fontWeight: FontWeight.w600, color: Colors.black87)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Approved by', style: TextStyle(fontSize: smallFont, color: Colors.grey.shade600)),
                      SizedBox(height: 4),
                      Text(approvedBy, style: TextStyle(fontSize: bodyFont, fontWeight: FontWeight.w600, color: Colors.black87)),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 12),

            // Remarks box (read-only)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                remarks,
                style: TextStyle(fontSize: smallFont, color: Colors.grey.shade700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // button handlers (replace with real logic)
  void _onRejectPressed() {
    // example: collect selected items & call API
    final selected = _items.where((e) => e['checked'] == true).toList();
    debugPrint('Reject: ${selected.length} items');
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rejected selected vouchers (demo)')));
  }

  void _onApprovePressed() {
    final selected = _items.where((e) => e['checked'] == true).toList();
    debugPrint('Approve: ${selected.length} items');
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Approved selected vouchers (demo)')));
  }
}
