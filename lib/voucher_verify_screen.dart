// voucher_verify_screen.dart
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'api_service.dart';
import 'package:cotopay/session_manager.dart';

class VoucherVerifyScreen extends StatefulWidget {
  final ApiService apiService;
  final Map<String, dynamic>? bankInfo;
  final List<Map<String, dynamic>> entries;

  const VoucherVerifyScreen({
    Key? key,
    required this.apiService,
    this.bankInfo,
    required this.entries,
  }) : super(key: key);

  @override
  State<VoucherVerifyScreen> createState() => _VoucherVerifyScreenState();
}

class _VoucherVerifyScreenState extends State<VoucherVerifyScreen> {
  bool _consentChecked = false;
  bool _loading = false;
  String _statusMessage = '';

  // These must match backend secret/clientKey
  static const String SECRET_KEY = '0123456789012345';
  static const String CLIENT_KEY = 'client-secret-key';
  static const String MANDATE_TYPE = '01'; // as example

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Verify Details'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 16),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // top dark bank card similar to Figma
              _buildTopBankCard(),
              const SizedBox(height: 16),

              _buildHeaderCard(),
              const SizedBox(height: 8),

              // entries list
              ...widget.entries.asMap().entries.map((pair) {
                final idx = pair.key;
                final e = pair.value;
                return _buildEntryCard(idx + 1, e);
              }).toList(),

              const SizedBox(height: 16),
              Row(children: [
                Checkbox(value: _consentChecked, onChanged: (v) => setState(() => _consentChecked = v ?? false)),
                Expanded(
                  child: Text(
                    'I confirm that the details uploaded above are correct to the best of my knowledge, and are approved by the competent authority in my organization.',
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ),
              ]),

              const SizedBox(height: 12),
              if (_statusMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(_statusMessage, style: const TextStyle(color: Colors.red)),
                ),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: (!_consentChecked || _loading) ? null : _issueVoucher,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (_consentChecked && !_loading) ? const Color(0xFF3366FF) : const Color(0xFFDFEAFE),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('ISSUE VOUCHER', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBankCard() {
    final bank = widget.bankInfo;
    // mimic dark rounded card with pill and amount on right (Figma)
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF26282C),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        // left: cotoBalance label
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(text: 'coto', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                  const WidgetSpan(child: SizedBox(width: 6)),
                  TextSpan(text: 'Balance', style: TextStyle(color: Colors.white.withOpacity(0.95), fontWeight: FontWeight.w500, fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF26282C),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Text(bank?['masked'] ?? 'xxxx1234', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ),
            ]),
          ]),
        ),

        // right: amount display
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(
            NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2).format(_parseBalance(bank?['availableBalance'])),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20),
          ),
          const SizedBox(height: 6),
          Text('Available Balance', style: TextStyle(color: Colors.white70, fontSize: 12)),
        ]),
      ]),
    );
  }

  double _parseBalance(dynamic v) {
    if (v == null) return 0.0;
    try {
      return double.tryParse(v.toString()) ?? 0.0;
    } catch (_) {
      return 0.0;
    }
  }

  Widget _buildHeaderCard() {
    final bank = widget.bankInfo;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.white, border: Border.all(color: Colors.grey.shade200)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Verify Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 6),
        const Text('Please cross-check the details for the issuance of vouchers.', style: TextStyle(color: Colors.black54)),
        if (bank != null) ...[
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(bank['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(bank['masked'] ?? '', style: const TextStyle(color: Colors.black54)),
          ])
        ]
      ]),
    );
  }

  Widget _buildEntryCard(int index, Map<String, dynamic> e) {
    // small helper to format amount
    String formatAmount(String? a) {
      if (a == null || a.isEmpty) return '';
      return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(double.tryParse(a) ?? 0);
    }

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300), color: Colors.white),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.local_offer_outlined, size: 20),
          const SizedBox(width: 8),
          Text(e['voucherName'] ?? 'Fuel Voucher', style: const TextStyle(fontWeight: FontWeight.w700)),
          const Spacer(),
          InkWell(
            onTap: () {
              // optional: allow remove or edit — in verify screen we can ignore
            },
            child: const Icon(Icons.delete_outline, color: Colors.red),
          ),
        ]),
        const SizedBox(height: 10),
        _twoColRow('Name', e['name']?.toString() ?? '', 'Number', e['mobile']?.toString() ?? ''),
        const SizedBox(height: 8),
        _twoColRow('Amount', formatAmount(e['amount']?.toString()), 'Redemption Type', e['redemptionType']?.toString() ?? ''),
        const SizedBox(height: 8),
        _twoColRow('Start Date', e['startDate']?.toString() ?? DateFormat('dd/MM/yyyy').format(DateTime.now()), 'Validity (days)', e['validity']?.toString() ?? ''),
      ]),
    );
  }

  Widget _twoColRow(String aLabel, String aVal, String bLabel, String bVal) {
    return Row(
      children: [
        Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(aLabel, style: const TextStyle(color: Colors.black54, fontSize: 12)),
              const SizedBox(height: 4),
              Text(aVal, style: const TextStyle(fontSize: 14)),
            ])),
        const SizedBox(width: 12),
        Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(bLabel, style: const TextStyle(color: Colors.black54, fontSize: 12)),
              const SizedBox(height: 4),
              Text(bVal, style: const TextStyle(fontSize: 14)),
            ])),
      ],
    );
  }

  Future<void> _issueVoucher() async {
    setState(() {
      _loading = true;
      _statusMessage = '';
    });

    try {
      final user = await SessionManager.getUserData();
      final orgId = user?.employerid;
      final createdBy = user?.username ?? user?.username ?? 'Unknown';

      // merchant/subMerchant/payerVA/accountNumber should come from config / selected bank
      final merchantId = '610954'; // REPLACE with real merchantId from config/session
      final subMerchantId = merchantId;
      final accountNumber = widget.bankInfo?['accountNumber'] ?? widget.bankInfo?['masked'] ?? '';
      final payerVA = widget.bankInfo?['payerVA'] ?? 'merchant@icici'; // replace or fetch from bank config

      // create erupiVoucherCreateDetails list
      final List<Map<String, dynamic>> details = widget.entries.map((e) {
        return {
          "requestId": null,
          "voucherId": null,
          "name": e['name'] ?? '',
          "mobile": e['mobile'] ?? '',
          "amount": e['amount'] ?? '',
          "startDate": e['startDate'] ?? DateFormat('yyyy-MM-dd').format(DateTime.now()),
          "expDate": e['expDate'],
          "purposeCode": e['purposeCode'] ?? e['voucherCode'] ?? '',
          "mcc": e['mcc'] ?? '',
          "mccDescription": e['mccDescription'] ?? '',
          "purposeDescription": e['purposeDescription'] ?? '',
          "type": null,
          "bankcode": widget.bankInfo?['bankcode'] ?? '',
          "voucherCode": e['purposeCode'] ?? '',
          "voucherType": null,
          "voucherDesc": e['purposeDescription'] ?? '',
          "redemptionType": e['redemptionType'] ?? '',
          "validity": e['validity'] ?? ''
        };
      }).toList();

      final consent = _consentChecked ? 'yes' : 'no';

      // Build hashing string (order exactly as backend expects)
      final dataString = (consent) +
          (createdBy) +
          (orgId?.toString() ?? '') +
          (merchantId) +
          (subMerchantId) +
          (accountNumber) +
          (payerVA) +
          (MANDATE_TYPE) +
          (CLIENT_KEY) +
          (SECRET_KEY);

      final hash = _sha256Hex(dataString);

      final requestBody = {
        "merchantId": merchantId,
        "subMerchantId": subMerchantId,
        "mandateType": MANDATE_TYPE,
        "clientKey": CLIENT_KEY,
        "hash": hash,
        "activeStatus": "",
        "payeeVPA": null,
        "consent": consent,
        "otpValidationStatus": null,
        "creationDate": null,
        "createdby": createdBy,
        "accountId": null,
        "orgId": orgId,
        "accountNumber": accountNumber,
        "response": null,
        "responseApi": null,
        "merchanttxnid": null,
        "creationmode": null,
        "payerVA": payerVA,
        "bankcode": widget.bankInfo?['bankcode'] ?? '',
        "erupiVoucherCreateDetails": details,
      };

      // call API (expects ApiService.createSingleVoucher implemented)
      final resp = await widget.apiService.createSingleVoucher(requestBody);

      if (resp != null && (resp['status'] == true || resp['success'] == true)) {
        // success - show dialog and then pop
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Column(mainAxisSize: MainAxisSize.min, children: const [
              Icon(Icons.check_circle, color: Colors.green, size: 56),
              SizedBox(height: 12),
              Text('Congratulations!', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 6),
              Text('Voucher Successfully Issued', textAlign: TextAlign.center),
            ]),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Done'))
            ],
          ),
        );
        // navigate back or to any screen you want
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        setState(() {
          _statusMessage = (resp != null && resp['message'] != null) ? resp['message'].toString() : 'Failed to issue voucher. Please try again.';
        });
      }
    } catch (e, st) {
      debugPrint('Voucher verify error: $e\n$st');
      setState(() {
        _statusMessage = 'An error occurred: ${e.toString()}';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  String _sha256Hex(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
