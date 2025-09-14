import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'approve_vouchers_screen.dart';
import 'issue_voucher_screen.dart';

// Keep your existing imports for ApiService / SessionManager
import 'api_service.dart';
import 'package:cotopay/session_manager.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'account_settings_screen.dart';
import 'util/decrypt_screen.dart';

class UpiVouchersScreen extends StatefulWidget {
  const UpiVouchersScreen({super.key});

  @override
  State<UpiVouchersScreen> createState() => _UpiVouchersScreenState();
}

class _UpiVouchersScreenState extends State<UpiVouchersScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _banks = [];
  bool _loadingBanks = true;
  String? _error;
  String _selectedBankName = "All Linked Bank Accounts"; // default label
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    _loadBankList();
  }

  Future<void> _loadBankList() async {
    setState(() {
      _loadingBanks = true;
      _error = null;
    });
    try {
      final userData = await SessionManager.getUserData();
      if (userData == null || userData.employerid == null) {
        throw Exception("User not available");
      }
      final params = {"orgId": userData.employerid};
      final response = await _apiService.getBankList(params);
      if (response == null || response['status'] != true || response['data'] == null) {
        throw Exception(response?['message'] ?? 'Failed to load banks');
      }
      final List<dynamic> data = List<dynamic>.from(response['data']);
      if (!mounted) return;
      setState(() {
        _banks = data;
        _loadingBanks = false;
        _lastUpdated = DateTime.now();
      });
    } catch (e) {
      debugPrint("Error loading bank list: $e");
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loadingBanks = false;
      });
    }
  }

  // Bottom sheet bank selector
  void _showBankSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // grabber
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                  child: Align(alignment: Alignment.centerLeft, child: Text('SELECT BANK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                ),

                if (_loadingBanks)
                  const Padding(padding: EdgeInsets.symmetric(vertical: 32.0), child: Center(child: CircularProgressIndicator()))
                else if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16),
                    child: Column(
                      children: [
                        Text('Failed to load banks', style: TextStyle(color: Colors.red.shade700)),
                        const SizedBox(height: 8),
                        Text(_error!, style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            _loadBankList();
                          },
                          child: const Text("Retry"),
                        ),
                      ],
                    ),
                  )
                else if (_banks.isEmpty)
                    const Padding(padding: EdgeInsets.symmetric(vertical: 32.0), child: Text('No banks available'))
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _banks.length,
                        separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade200),
                        itemBuilder: (context, index) {
                          final bank = _banks[index];
                          final bankName = (bank['bankName'] ?? bank['name'] ?? 'Unknown Bank').toString();
                          final account = (bank['acNumber'] ?? bank['account'] ?? '').toString();
                          final masked = _maskAccount(account);
                          final bankIconBase64 = bank['bankIcon']?.toString();

                          return ListTile(
                            onTap: () {
                              setState(() {
                                _selectedBankName = bankName;
                              });
                              Navigator.of(ctx).pop();
                            },
                            leading: _bankIconWidget(bankIconBase64, size: 44),
                            title: Text(bankName, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: (bank['accountSeltWallet'] == "Wallet") ? const Text('Default', style: TextStyle(fontSize: 12, color: Colors.green)) : null,
                            trailing: Text(masked, style: const TextStyle(color: Colors.grey)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          );
                        },
                      ),
                    ),
              ],
            ),
          ),
        );
      },
    );
  }

  // decode base64 icon (if present)
  Widget _bankIconWidget(String? rawBase64, {double size = 40}) {
    if (rawBase64 == null || rawBase64.trim().isEmpty) return _initialsAvatar(null, size: size);
    try {
      String cleaned = rawBase64;
      if (cleaned.contains(',')) cleaned = cleaned.split(',').last;
      final Uint8List bytes = base64Decode(cleaned);
      return CircleAvatar(radius: size / 2, backgroundColor: Colors.transparent, backgroundImage: MemoryImage(bytes));
    } catch (e) {
      debugPrint("bankIcon decode error: $e");
      return _initialsAvatar(null, size: size);
    }
  }

  Widget _initialsAvatar(String? name, {double size = 40}) {
    final color = Colors.green.shade50;
    final initials = (name != null && name.isNotEmpty) ? name.trim()[0].toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: Center(child: Text(initials, style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.w700))),
    );
  }

  String _maskAccount(String account) {
    if (account.isEmpty) return '';
    final cleaned = account.replaceAll(RegExp(r'\s+'), '');
    if (cleaned.length <= 4) return cleaned;
    final last = cleaned.substring(cleaned.length - 4);
    return 'xxxx$last';
  }

  String _formatLastUpdated(DateTime? dt) {
    if (dt == null) return '';
    final time = DateFormat('HH:mm:ss').format(dt);
    final date = DateFormat('EEE d MMM yyyy').format(dt);
    return 'Last updated on  •  $time  •  $date';
  }

  double clampDouble(double value, double min, double max) => value.clamp(min, max);

  @override
  Widget build(BuildContext context) {
    // screen metrics
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final bool isTablet = screenWidth >= 600;

    // responsive sizes
    final horizontalPadding = clampDouble(screenWidth * 0.04, 12, 24);
    final sectionRadius = clampDouble(screenWidth * 0.04, 12, 20);
    final internalRadius = clampDouble(screenWidth * 0.02, 8, 14);
    final iconSize = clampDouble(screenWidth * 0.05, 18, 28);
    final titleFont = clampDouble(screenWidth * 0.05, 16, 22);
    final labelFont = clampDouble(screenWidth * 0.038, 14, 18);
    final smallFont = clampDouble(screenWidth * 0.032, 12, 14);
    final greenCardRadius = clampDouble(screenWidth * 0.038, 12, 24);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 16.0,
        title: const Text(
          "Vouchers",
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),

        leading: IconButton(icon: const Icon(Icons.sort, color: Colors.black), onPressed: () {
           Navigator.push(context, MaterialPageRoute(builder: (context) => const AccountSettingsScreen()));
        }),

        actions: [IconButton(icon: const Icon(Icons.notifications_none, color: Colors.black), onPressed: () {})],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: horizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- GREEN CARD (bank selector + active vouchers + last updated)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF2F945A), // exact green
                borderRadius: BorderRadius.circular(greenCardRadius),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(greenCardRadius),
                child: Column(
                  children: [
                    // top content (selector + active)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: horizontalPadding * 0.9),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // selector
                          GestureDetector(
                            onTap: _showBankSelector,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: horizontalPadding * 0.6, vertical: horizontalPadding * 0.45),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.03),
                                borderRadius: BorderRadius.circular(internalRadius),
                                border: Border.all(color: Colors.white.withOpacity(0.12)),
                              ),
                              child: Row(
                                children: [
                                  Image.asset(
                                    'assets/images/bank.png',
                                    width: iconSize * 0.9,
                                    height: iconSize * 0.9,
                                    fit: BoxFit.contain,
                                  ),
                                  SizedBox(width: horizontalPadding * 0.6),
                                  Expanded(
                                    child: Text(
                                      _selectedBankName,
                                      style: TextStyle(color: Colors.white, fontSize: labelFont, fontWeight: FontWeight.w600),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: iconSize * 0.9),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: horizontalPadding),

                          // Active Vouchers row
                          Row(
                            children: [
                              Expanded(
                                child: Text("Active Vouchers", style: TextStyle(color: Colors.white, fontSize: labelFont, fontWeight: FontWeight.w500)),
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text("0", style: TextStyle(color: Colors.white, fontSize: titleFont * 0.9, fontWeight: FontWeight.w700)),
                                  Container(width: 1, height: screenHeight * 0.03, margin: EdgeInsets.symmetric(horizontal: horizontalPadding * 0.6), color: Colors.white.withOpacity(0.4)),
                                  Text("₹0", style: TextStyle(color: Colors.white, fontSize: titleFont * 0.9, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // divider & last updated row
                    Container(
                      color: const Color(0xFF2F945A),
                      child: Column(
                        children: [
                          Divider(color: Colors.white.withOpacity(0.18), height: 1),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: horizontalPadding * 0.1),
                            child: Row(
                              children: [
                            //    Icon(Icons.history, color: Colors.white70, size: iconSize * 0.8),
                                Expanded(
                                  child: Text(_formatLastUpdated(_lastUpdated), style: TextStyle(color: Colors.white70, fontSize: 11), overflow: TextOverflow.ellipsis),
                                ),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  onPressed: _loadBankList,
                                  icon: Icon(Icons.refresh, color: Colors.white70, size: iconSize * 0.95),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: horizontalPadding * 1.1),

            // --- WHITE rounded section (Office UPI Vouchers)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(sectionRadius),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: Padding(
                padding: EdgeInsets.all(horizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // header
                    Padding(
                      padding: EdgeInsets.only(top: horizontalPadding * 0.6, bottom: horizontalPadding * 0.4),
                      child: Text("Office UPI Vouchers",
                          style: TextStyle(fontSize: titleFont, fontWeight: FontWeight.w700, color: Colors.black87)),
                    ),

                    // top black pill (Issue Voucher)
                    InkWell(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const IssueVoucherScreen())),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(horizontal: horizontalPadding * 0.9, vertical: horizontalPadding * 0.75),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(internalRadius),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(horizontalPadding * 0.25),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.white.withOpacity(0.06),
                              ),
                              child: Icon(Icons.confirmation_number, color: Colors.white, size: iconSize * 0.95),
                            ),
                            SizedBox(width: horizontalPadding * 0.8),
                            Expanded(
                              child: Text("Issue Voucher",
                                  style: TextStyle(color: Colors.white, fontSize: labelFont, fontWeight: FontWeight.w600)),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: horizontalPadding * 0.6, vertical: 6),
                              decoration: BoxDecoration(color: const Color(0xFFF2C94C), borderRadius: BorderRadius.circular(20)),
                              child: Text("Admin",
                                  style: TextStyle(color: Colors.black87, fontSize: smallFont * 0.95, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: horizontalPadding * 0.9),

                    // white tiles container with rounded inner container, border and separators
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(internalRadius),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          // Approve Vouchers tile
                          _listTile(
                            icon: Icons.verified_outlined,
                            title: "Approve Vouchers",
                            iconSize: iconSize,
                            textSize: labelFont,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const  ApproveVouchersScreen())),
                          ),
                          Divider(height: 1, color: Colors.grey.shade200),
                          // 0 tile
                          _listTile(
                            icon: Icons.confirmation_number_outlined,
                            title: "0",
                            iconSize: iconSize,
                            textSize: labelFont,
                            onTap: () {

                            }
                            //=> Navigator.push(context, MaterialPageRoute(builder: (c) => const  DecryptDemoScreen())),

                          ),
                          Divider(height: 1, color: Colors.grey.shade200),
                          // Voucher History tile
                          _listTile(
                            icon: Icons.history,
                            title: "Voucher History",
                            iconSize: iconSize,
                            textSize: labelFont,
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: horizontalPadding * 0.9),
                  ],
                ),
              ),
            ),

            SizedBox(height: horizontalPadding * 1.0),
          ],
        ),
      ),
    );
  }

  Widget _listTile({required IconData icon, required String title, required double iconSize, required double textSize, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: iconSize, color: const Color(0xFF5E5E6B)), // muted color
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: TextStyle(fontSize: textSize, fontWeight: FontWeight.w600, color: const Color(0xFF3D3D4A)))),
            Icon(Icons.arrow_forward_ios, size: iconSize * 0.6, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
