import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'api_service.dart';

class DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 2;
    var max = size.height;
    var dashWidth = 5;
    var dashSpace = 4;
    double startY = 0;
    while (max >= startY) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashWidth), paint);
      startY += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}


class VoucherDetailScreen extends StatefulWidget {
  final Map<String, dynamic> voucherData;

  const VoucherDetailScreen({super.key, required this.voucherData});

  @override
  State<VoucherDetailScreen> createState() => _VoucherDetailScreenState();
}

class _VoucherDetailScreenState extends State<VoucherDetailScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _detailedData;

  @override
  void initState() {
    super.initState();
    _fetchVoucherDetails();
  }

  Future<void> _fetchVoucherDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final voucherId = widget.voucherData['id'];
      if (voucherId == null) throw Exception("Voucher ID is missing");
      final params = {"id": voucherId, "response": "", "responseApi": ""};
      final response = await _apiService.getVoucherHistoryDetails(params);
      if (mounted) {
        if (response['status'] == true && response['data'] != null) {
          setState(() {
            _detailedData = response['data'];
            _isLoading = false;
          });
        } else {
          throw Exception(response['message'] ?? "Failed to load details");
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      appBar: AppBar(
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        backgroundColor: const Color(0xFF1C1C1E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Voucher Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          IconButton(icon: const Icon(Icons.download_outlined, color: Colors.white), onPressed: () {}),
        ],
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text("Error: $_error", style: const TextStyle(color: Colors.white70)));
    }
    if (_detailedData == null) {
      return const Center(child: Text("No details found.", style: const TextStyle(color: Colors.white70)));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: _buildVoucherInfoCard(),
        ),
        Expanded(
          child: Container(
            clipBehavior: Clip.hardEdge,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: SingleChildScrollView(
              child: _buildTransactionsList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVoucherInfoCard() {
    final data = _detailedData!;
    String purpose = data['voucherDesc'] ?? 'N/A';
    String redemptionType = (data['redemtionType'] as String?)?.capitalize() ?? 'N/A';
    double voucherValue = double.tryParse(data['voucherAmount']?.toString() ?? '0.0') ?? 0.0;
    double balance = double.tryParse(data['activeAmount']?.toString() ?? '0.0') ?? 0.0;
    String voucherStatus = (data['voucherStatus'] as String?)?.capitalize() ?? 'N/A';
    String? logoBase64 = data['voucherLogo'];
    String? umn = data['umn'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2E965E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                child: _buildVoucherLogo(logoBase64, purpose),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(purpose, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(redemptionType == 'Single' ? Icons.refresh : Icons.repeat, size: 16, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(redemptionType, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(voucherValue),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 2),
                  const Text('Voucher value', style: TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ],
          ),
          Divider(color: Colors.white.withOpacity(0.2), height: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(label1: 'Sponsored by', value1: 'CotoPay', label2: 'Issuer Bank', value2: '-'),
              const SizedBox(height: 12),
              _buildDetailRow(label1: 'Issue Date', value1: _formatDisplayDate(data['issueDate']), label2: 'Expiry Date', value2: _formatDisplayDate(data['expDate'])),
              const SizedBox(height: 12),
              if (umn != null && umn.isNotEmpty) _buildDetailColumn('UMN', umn),
            ],
          ),
          Divider(color: Colors.white.withOpacity(0.2), height: 24),
          Row(
            children: [
              const Text('Balance:', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
              const Spacer(),
              Chip(
                label: Text(voucherStatus, style: const TextStyle(color: Color(0xFF1E6C45), fontWeight: FontWeight.bold, fontSize: 12)),
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
              ),
              const SizedBox(width: 8),
              Text(NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(balance),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildVoucherLogo(String? base64String, String purpose) {
    if (base64String != null && base64String.isNotEmpty) {
      try {
        Uint8List imageBytes = base64Decode(base64String);
        return Image.memory(imageBytes, width: 24, height: 24, fit: BoxFit.contain,
            errorBuilder: (c, e, s) => _getIconForPurpose(purpose));
      } catch (e) {
        return _getIconForPurpose(purpose);
      }
    }
    return _getIconForPurpose(purpose);
  }

  Icon _getIconForPurpose(String purpose) {
    String p = purpose.toLowerCase();
    IconData iconData = Icons.card_giftcard_rounded;
    if (p.contains('fuel')) iconData = Icons.local_gas_station_rounded;
    if (p.contains('meal') || p.contains('food')) iconData = Icons.restaurant_menu_rounded;
    if (p.contains('general')) iconData = Icons.shopping_bag_outlined;
    return Icon(iconData, color: Colors.white, size: 24);
  }

  Widget _buildDetailRow({required String label1, required String value1, required String label2, required String value2}) {
    return Row(children: [Expanded(child: _buildDetailColumn(label1, value1)), const SizedBox(width: 10), Expanded(child: _buildDetailColumn(label2, value2))]);
  }

  Widget _buildDetailColumn(String label, String value) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)), const SizedBox(height: 2),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))]);
  }

  Widget _buildTransactionsList() {
    final transactions = _detailedData?['redeemData'] as List<dynamic>? ?? [];
    double totalSpent = transactions.fold(0.0, (sum, item) => sum + (double.tryParse(item['amount']?.toString() ?? '0.0') ?? 0.0));
    String redemptionStatus = "Fully Redeemed";
    if (totalSpent > 0) {
      double voucherValue = double.tryParse(_detailedData!['voucherAmount']?.toString() ?? '0.0') ?? 0.0;
      if (totalSpent < voucherValue) redemptionStatus = "Partially Redeemed";
    } else {
      redemptionStatus = "Unused";
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 16),
          child: Text('TRANSACTIONS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey[600], letterSpacing: 0.5)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
          child: Row(children: [
            Text('Amount Spent', style: TextStyle(fontSize: 15, color: Colors.grey.shade700, fontWeight: FontWeight.w500)), const SizedBox(width: 8),
            Text(NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(totalSpent),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Spacer(),
            Chip(
                label: Text(redemptionStatus, style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold, fontSize: 11)),
                backgroundColor: Colors.orange.shade100, padding: const EdgeInsets.symmetric(horizontal: 8), visualDensity: VisualDensity.compact)
          ]),
        ),
        const SizedBox(height: 24),
        if (transactions.isEmpty)
          Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 40), child: Text("No transactions yet.", style: TextStyle(color: Colors.grey[600]))))
        else
          ListView.builder(
            shrinkWrap: true, padding: EdgeInsets.zero, physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length,
            itemBuilder: (context, index) => _buildTransactionItem(transactions[index], index + 1, transactions.length),
          ),
      ]),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> txData, int index, int totalCount) {
    final amount = double.tryParse(txData['amount']?.toString() ?? '0.0') ?? 0.0;
    return IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Column(children: [
        CircleAvatar(radius: 12, backgroundColor: Colors.grey.shade200, child: Text('$index', style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold))),
        if (index < totalCount) Expanded(child: CustomPaint(painter: DottedLinePainter(), size: const Size(2, double.infinity)))
      ]),
      const SizedBox(width: 12),
      Expanded(
        child: Container(
          margin: EdgeInsets.only(bottom: index < totalCount ? 16 : 0), padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
          child: Column(children: [
            _buildTxRow('Transaction date', _formatDisplayDate(txData['transactionDate']), 'Transaction RRN', txData['merchantTranId'] ?? 'N/A'),
            const SizedBox(height: 12),
            _buildTxRow('Merchant Name', txData['merchantName'] ?? 'N/A', 'Amount',
                NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(amount)),
          ]),
        ),
      )
    ]));
  }

  Widget _buildTxRow(String label1, String value1, String label2, String value2) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: _buildTxDetailColumn(label1, value1)), const SizedBox(width: 10), Expanded(child: _buildTxDetailColumn(label2, value2))
    ]);
  }

  Widget _buildTxDetailColumn(String label, String value) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)), const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
    ]);
  }

  String _formatDisplayDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(dateStr));
    } catch (_) {
      return dateStr;
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return "";
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}