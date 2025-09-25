import 'package:cotopay/session_manager.dart';
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'TrialPaymentFlow.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:intl/intl.dart';

class CotoBalanceCard extends StatefulWidget {
  const CotoBalanceCard({super.key});

  @override
  State<CotoBalanceCard> createState() => _CotoBalanceCardState();
}

class _CotoBalanceCardState extends State<CotoBalanceCard> with WidgetsBindingObserver {
  final ApiService _apiService = ApiService();
  String _balance = "0.00";
  bool _loadingBalance = true;
  bool _loadingTransactions = true;
  List<dynamic> _transactions = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadInitialData();
    _loadTransactions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint("🔄 App Resumed → Refreshing balance & transactions");
      _loadInitialData();
      _loadTransactions();
    }
  }

  Future<Map<String, dynamic>> getCashFreeOrderIdList(Map<String, dynamic> params) async {
    const url = "http://52.66.10.111:8085/cashFree/Api/get/cashFreeOrderIdList";
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(params),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint("❌ API error: ${response.statusCode}");
        return {"status": false, "data": []};
      }
    } catch (e) {
      debugPrint("❌ Exception in API: $e");
      return {"status": false, "data": []};
    }
  }

  Future<void> _loadInitialData() async {
    try {
      final userData = await SessionManager.getUserData();
      if (userData != null && userData.employerid != null) {
        final params = {"orgId": userData.employerid, "acNumber": "12345678912345"};
        final response = await _apiService.getCotoBalance(params);
        if (response['status'] == true) {
          setState(() {
            _balance = response['balance']?.toString() ?? "0.00";
            _loadingBalance = false;
          });
        } else {
          setState(() => _loadingBalance = false);
        }
      } else {
        setState(() => _loadingBalance = false);
      }
    } catch (e) {
      debugPrint("❌ Error loading balance: $e");
      setState(() => _loadingBalance = false);
    }
  }

  Future<void> _loadTransactions() async {
    try {
      final userData = await SessionManager.getUserData();
      if (userData != null && userData.employerid != null) {
        final params = {"orgId": userData.employerid, "applicationType": "mobile"};
        final response = await getCashFreeOrderIdList(params);
        debugPrint("📤 Transaction Response: $response");
        if (response['status'] == true && response['data'] != null) {
          setState(() {
            _transactions = response['data'];
            _loadingTransactions = false;
          });
        } else {
          setState(() {
            _transactions = [];
            _loadingTransactions = false;
          });
        }
      } else {
        setState(() {
          _transactions = [];
          _loadingTransactions = false;
        });
      }
    } catch (e) {
      debugPrint("❌ Error loading transactions: $e");
      setState(() => _loadingTransactions = false);
    }
  }

  String _formatDate(String? raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('d MMM').format(dt); // -> "3 July"
    } catch (_) {
      // fallback: if already "3 July", return as-is
      if (RegExp(r'^\d{1,2}\s+\w+').hasMatch(raw)) return raw;
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    // primary card color (matches your design)
    const Color cardColor = Color(0xFF2F945A); // slight tweak to match image
    const Color cardColorBottom = Color(0xFF2F945A); // slightly darker for bottom segmented bar

    // Responsive calculations
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final bool isTablet = screenWidth >= 600;
    final double horizontalMargin = clampDouble(screenWidth * 0.03, 12, 40);

    final double cardMaxWidth = isTablet ? 760 : 900; // make card wide (image is wide)
    final double cardWidth = min(screenWidth - (horizontalMargin * 2), cardMaxWidth);
    final double cardHeight = clampDouble(cardWidth * 0.36, 140, 260); // height proportional to width

    // typography sizes
    final double leftTitleFontBig = clampDouble(cardWidth * 0.07, 26, 42); // 'coto'
    final double leftTitleSmall = clampDouble(leftTitleFontBig * 0.55, 14, 26); // 'Balance'
    final double balanceFont = clampDouble(cardWidth * 0.07, 22, 48);
    final double subtitleFont = clampDouble(cardWidth * 0.025, 12, 18);

    // bottom segmented bar height
    final double bottomBarHeight = clampDouble(cardHeight * 0.38, 56, 84);

    // divider indent for transactions list (keeps alignment)
    final double avatarSize = clampDouble(cardHeight * 0.22, 36, 56);
    final double dividerIndent = avatarSize + 12 + horizontalMargin;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          "Coto Balance",
          style: TextStyle(color: Colors.black, fontSize: clampDouble(screenWidth * 0.045, 16, 20), fontWeight: FontWeight.w500),
        ),
        actions: const [
          Padding(padding: EdgeInsets.only(right: 8.0), child: Icon(Icons.notifications_none, color: Colors.black)),
        ],
      ),
      // Outer padding same as previous ListView padding
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalMargin),
        child: Column(
          children: [
            SizedBox(height: clampDouble(screenHeight * 0.02, 12, 30)),

            // CARD — visually matches the provided image (fixed, non-scrollable)
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: cardMaxWidth),
                child: Container(
                  width: cardWidth,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // top area
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: clampDouble(cardWidth * 0.05, 16, 32),
                          vertical: clampDouble(cardHeight * 0.1, 12, 20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title: coto Balance
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'coto',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: leftTitleFontBig,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Balance',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.95),
                                    fontSize: leftTitleFontBig,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Amount section aligned to right
                            Row(
                              children: [
                                const Spacer(),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    _loadingBalance
                                        ? SizedBox(
                                      width: clampDouble(balanceFont * 0.9, 26, 40),
                                      height: clampDouble(balanceFont * 0.9, 26, 40),
                                      child: const CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                        : Text(
                                      NumberFormat.currency(
                                        symbol: '₹',
                                        decimalDigits: 2,
                                        locale: 'en_IN',
                                      ).format(double.tryParse(_balance.replaceAll(',', '')) ?? 0),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: balanceFont,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      "Available Balance",
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: subtitleFont,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // separator line
                      Container(height: 1, color: Colors.white.withOpacity(0.14)),

                      // bottom segmented bar
                      Container(
                        height: bottomBarHeight,
                        color: cardColor, // same shade
                        child: Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final result = await TrialPaymentFlow.showAmountSelection(context);
                                  if (result == true) {
                                    _loadInitialData();
                                    _loadTransactions();
                                  }
                                },
                                child: Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "Trial",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: clampDouble(leftTitleSmall * 1.1, 16, 24),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Icon(Icons.add, color: Colors.white, size: 20),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Container(width: 1, color: Colors.white.withOpacity(0.12)),
                            Expanded(
                              child: InkWell(
                                onTap: () {},
                                child: Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "Redeem",
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: clampDouble(leftTitleSmall * 1.1, 16, 24),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.open_in_new, color: Colors.white70, size: 20),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: clampDouble(screenHeight * 0.03, 12, 36)),

            // Transactions header (fixed)
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("TRANSACTIONS", style: TextStyle(color: Colors.black87, fontSize: clampDouble(screenWidth * 0.038, 12, 16), fontWeight: FontWeight.bold)),
                  SizedBox(height: clampDouble(screenHeight * 0.01, 8, 14)),
                ],
              ),
            ),

            // The only scrollable area — wraps the list with RefreshIndicator
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await _loadInitialData();
                  await _loadTransactions();
                },
                // Build transaction list as a scrollable ListView
                child: _buildTransactionList(screenWidth, screenHeight, avatarSize, dividerIndent),
              ),
            ),
            // bottom spacing (after the list)
            SizedBox(height: clampDouble(screenHeight * 0.02, 12, 30)),
          ],
        ),
      ),
    );
  }

  /// Returns a scrollable ListView (or a one-item list for loading/empty state)
  Widget _buildTransactionList(double screenWidth, double screenHeight, double avatarSize, double dividerIndent) {
    // loading: show a vertically centered loader inside a scrollable (so pull-to-refresh works)
    if (_loadingTransactions) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: clampDouble(screenHeight * 0.05, 20, 40)),
          const Center(child: CircularProgressIndicator()),
          SizedBox(height: clampDouble(screenHeight * 0.5, 200, 400)), // give space so loader is centered-ish
        ],
      );
    }

    // empty: show a message but keep list scrollable
    if (_transactions.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: clampDouble(screenHeight * 0.04, 16, 32)),
          const Center(child: Text("No transactions found")),
          SizedBox(height: clampDouble(screenHeight * 0.5, 200, 400)),
        ],
      );
    }

    // populated list
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: _transactions.length + 1, // +1 for bottom spacing
      separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade300, indent: dividerIndent),
      itemBuilder: (context, index) {
        if (index == _transactions.length) {
          // bottom spacing at the end of list
          return SizedBox(height: clampDouble(screenHeight * 0.06, 28, 64));
        }

        final txn = _transactions[index];
        final orderStatus = (txn['orderStatus'] ?? '').toString();
        final title = (txn['title'] ?? (orderStatus == "PAID" ? "Trial Payment" : "Order")).toString();
        final vendor = (txn['customerName'] ?? 'CotoPay').toString();

        String rawDate = (txn['orderDate'] ?? txn['createdAt'] ?? txn['date'] ?? '3 Jul').toString();
        final dateStr = _formatDate(rawDate);

        final amount = txn['orderAmount'] != null ? "₹${txn['orderAmount']}" : "₹0";

        return Padding(
          padding: EdgeInsets.symmetric(vertical: clampDouble(screenHeight * 0.012, 8, 14)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // avatar
              Container(
                width: avatarSize,
                height: avatarSize,
                decoration: const BoxDecoration(color: Color(0xFFE8F5E9), shape: BoxShape.circle),
                child: Center(child: Icon(Icons.receipt_long, color: const Color(0xFF2F945A), size: clampDouble(avatarSize * 0.55, 16, 28))),
              ),
              SizedBox(width: clampDouble(screenWidth * 0.03, 8, 16)),

              // text column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: clampDouble(screenWidth * 0.042, 13, 16))),
                    SizedBox(height: clampDouble(screenHeight * 0.008, 4, 8)),
                    Text(vendor, style: TextStyle(color: const Color(0xFF2F945A), fontSize: clampDouble(screenWidth * 0.036, 12, 14), fontWeight: FontWeight.w600)),
                    SizedBox(height: clampDouble(screenHeight * 0.006, 3, 6)),
                    Text(dateStr, style: TextStyle(color: Colors.grey.shade600, fontSize: clampDouble(screenWidth * 0.032, 11, 13))),
                  ],
                ),
              ),

              // amount right aligned
              Text(amount, style: TextStyle(fontWeight: FontWeight.bold, fontSize: clampDouble(screenWidth * 0.042, 13, 16))),
            ],
          ),
        );
      },
    );
  }

  double clampDouble(double value, double min, double max) => value.clamp(min, max);
}
