import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class TransactionDetailScreen extends StatelessWidget {
  final Map<String, dynamic> transactionData;

  const TransactionDetailScreen({super.key, required this.transactionData});

  void _shareTransactionDetails(BuildContext context) {
    final String textToShare = """
Transaction Details:
- To: ${transactionData['title']}
- Amount: ${transactionData['amount']}
- Status: Completed
- Date: ${transactionData['date']}, ${transactionData['time']}
- UPI Transaction ID: ${transactionData['upiTransactionId']}
- Voucher ID: ${transactionData['voucherId']}
- Transaction RRN: ${transactionData['transactionRrn']}
- UMN: ${transactionData['umn']}
""";
    Share.share(textToShare, subject: 'Transaction Details');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border, color: Colors.black),
            onPressed: () {
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Top section
          _buildTopSection(),
          const SizedBox(height: 20),
          // Bottom details card
          Expanded(
            child: _buildDetailsCard(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSection() {
    return Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.green.shade50,
          child:
          Icon(Icons.receipt_long_outlined, color: Colors.green.shade700),
        ),
        const SizedBox(height: 8),
        Text(
          'To ${transactionData['title']}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Text(
          '${transactionData['amount']}',
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 16),
            SizedBox(width: 4),
            Text('Completed', style: TextStyle(color: Colors.green)),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${transactionData['date']}, ${transactionData['time']}',
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildDetailsCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: Colors.green.shade50,
                      child: Icon(Icons.wallet_giftcard,
                          color: Colors.green.shade700, size: 20),
                    ),
                    title: const Text('UPI Voucher from CotoPay',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Voucher ID'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
                        child: _buildDetailRow('Voucher ID', transactionData['voucherId']),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 16),
                  _buildDetailRow('Merchant Name', '${transactionData['title']}'),
                  _buildDetailRow('UPI transaction ID', '${transactionData['upiTransactionId']}'),
                  _buildDetailRow('Voucher ID', '${transactionData['voucherId']}'),
                  _buildDetailRow('Transaction RRN', '${transactionData['transactionRrn']}'),
                  _buildUmnRow('UMN', '${transactionData['umn']}'),
                ],
              ),
            ),
          ),
          // Bottom Buttons
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey)),
          Text(value,
              style:
              const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildUmnRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(title, style: const TextStyle(color: Colors.grey)),
              const SizedBox(width: 4),
              Tooltip(
                message: 'Unique Mandate Number',
                child:
                Icon(Icons.info_outline, color: Colors.grey[400], size: 16),
              ),
            ],
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _shareTransactionDetails(context),
              icon: const Icon(Icons.share_outlined, size: 18),
              label: const Text('Share'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                side: BorderSide(color: Colors.blue.shade600),
                foregroundColor: Colors.blue.shade600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
              },
              icon: const Icon(Icons.upload_file_outlined, size: 18),
              label: const Text('Upload Bill'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}