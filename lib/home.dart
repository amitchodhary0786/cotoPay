import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:cotopay/issue_voucher_screen.dart';
import 'upi_voucher_scren.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'session_manager.dart';
import 'api_service.dart';
import 'voucher_detail_screen.dart';
import 'account_settings_screen.dart';
import 'history_screen.dart';
import 'notifications_screen.dart';
import 'qr_scanner_screen.dart';
import 'rewards_screen.dart';
import 'issue_how_voucher_works.dart';
import 'package:cotopay/util/refreshservice.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  String _name = 'Loading...';
  Future<List<dynamic>>? _voucherListFuture;
  final ApiService _apiService = ApiService();

  // subscription to global refresh events
  StreamSubscription<void>? _refreshSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadInitialData();

    // subscribe to RefreshService so other screens can call RefreshService.refresh()
    _refreshSub = RefreshService.onRefresh.listen((_) {
      if (mounted) {
        debugPrint('🔁 HomeScreen received refresh event');
        _loadInitialData();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshSub?.cancel();
    super.dispose();
  }

  // Called when app lifecycle changes (resumed, paused, etc.)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      debugPrint('🔁 App resumed - refreshing HomeScreen data');
      _loadInitialData();
    }
  }

  Future<void> _loadInitialData() async {
    final userData = await SessionManager.getUserData();
    if (!mounted) return;

    setState(() {
      _name = userData?.username ?? 'N/A';
    });

    if (userData != null && userData.employerid != null) {
      final params = {
        "orgId": userData.employerid,
        "timePeriod": "AH",
        "mobile": userData.mobile
      };

      // Reassign future so FutureBuilder re-runs (and API is hit)
      setState(() {
        _voucherListFuture = _apiService.getVoucherList(params).then((response) {
          if (response != null && response['status'] == true && response['data'] is List) {
            debugPrint("📤 Home Response  $response");
            return response['data'] as List<dynamic>;
          } else {
            throw Exception(response?['message'] ?? 'Failed to load vouchers');
          }
        });
      });
    } else {
      setState(() {
        _voucherListFuture = Future.value(<dynamic>[]);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHomePageSelected = _selectedIndex == 0;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isHomePageSelected ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            HomeContent(name: _name, voucherListFuture: _voucherListFuture),
            // Vouchers screen: navigate and after return refresh
            UpiVouchersScreen(),
            Container(), // Placeholder for QR Scanner
            const SafeArea(child: RewardsScreen()),
            const SafeArea(child: HistoryScreen()),
          ],
        ),
        bottomNavigationBar: _buildBottomNavBar(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: _buildFab(),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomAppBar(
      surfaceTintColor: Colors.white,
      color: Colors.white,
      height: 70,
      elevation: 8,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _bottomNavItem(
              label: 'Home',
              selectedIcon: Icons.home,
              unselectedIcon: Icons.home_outlined,
              index: 0),
          _bottomNavItem(
              label: 'Vouchers',
              selectedIcon: Icons.confirmation_number,
              unselectedIcon: Icons.confirmation_number_outlined,
              index: 1),
          const SizedBox(width: 48),
          _bottomNavItem(
              label: 'Rewards',
              selectedIcon: Icons.card_giftcard,
              unselectedIcon: Icons.card_giftcard_outlined,
              index: 3),
          _bottomNavItem(
              label: 'History',
              selectedIcon: Icons.history,
              unselectedIcon: Icons.history_outlined,
              index: 4),
        ],
      ),
    );
  }

  Widget _bottomNavItem(
      {required String label,
        required IconData selectedIcon,
        required IconData unselectedIcon,
        required int index}) {
    final bool isSelected = _selectedIndex == index;
    final color = isSelected ? const Color(0xff34A853) : Colors.grey.shade600;
    return InkWell(
      onTap: () async {
        if (index == 1) {
          // navigate to vouchers screen and refresh on return
          await Navigator.push(context, MaterialPageRoute(builder: (context) => const UpiVouchersScreen()));
          // ensure data updated after returning
          _loadInitialData();
        } else {
          setState(() {
            _selectedIndex = index;
          });
        }
      },
      child: Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(isSelected ? selectedIcon : unselectedIcon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _buildFab() {
    return FloatingActionButton(
      onPressed: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (context) => const QrScannerScreen()));
        // refresh when coming back from scanner
        _loadInitialData();
      },
      backgroundColor: const Color(0xff34A853),
      shape: const CircleBorder(),
      child: Image.asset('assets/scan.png', width: 28, height: 28, color: Colors.white),
    );
  }
}

/* --------------------
   HOME CONTENT (kept mostly same)
   - added RefreshService.refresh() calls after pushes inside HomeContent
   -------------------- */

class HomeContent extends StatelessWidget {
  final String name;
  final Future<List<dynamic>>? voucherListFuture;

  const HomeContent({super.key, required this.name, this.voucherListFuture});

  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return null;
    final formats = [
      "yyyy-MM-dd HH:mm:ss",
      "yyyy-MM-dd",
      "d MMM yyyy",
      "dd-MM-yyyy",
      "MM/dd/yyyy",
    ];
    for (var format in formats) {
      try {
        return DateFormat(format).parse(dateStr);
      } catch (_) {}
    }
    debugPrint('Date parsing failed for ALL formats: $dateStr');
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final screenWidth = MediaQuery.of(context).size.width;
    final double cardWidth = (screenWidth < 360)
        ? screenWidth * 0.82
        : (screenWidth < 600 ? math.min(280, screenWidth * 0.65) : 320);
    final double carouselHeight = math.max(160, cardWidth * 0.9);

    return Column(
      children: [
        Container(color: const Color(0xff1C1C1E), padding: EdgeInsets.only(top: statusBarHeight), child: _buildTopBar(context)),
        Expanded(
          child: SingleChildScrollView(
            child: Container(
              color: const Color(0xff1C1C1E),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  FutureBuilder<List<dynamic>>(
                    future: voucherListFuture,
                    builder: (context, snapshot) {
                      int activeVoucherCount = 0;
                      double totalAmount = 0.0;
                      if (snapshot.connectionState == ConnectionState.done && snapshot.hasData && !snapshot.hasError) {
                        final createdVouchers = snapshot.data!.where((voucher) => voucher['type'] == 'Active').toList();
                        activeVoucherCount = createdVouchers.length;
                        totalAmount = createdVouchers.fold(0.0, (sum, item) => sum + ((item['amount'] as num?)?.toDouble() ?? 0.0));
                      }
                      return _buildVoucherBalanceCard(count: activeVoucherCount, totalAmount: totalAmount);
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: carouselHeight,
                    child: FutureBuilder<List<dynamic>>(
                      future: voucherListFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: Colors.white));
                        }
                        if (snapshot.hasError) {
                          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                        }

                        final createdVouchers = snapshot.hasData ? snapshot.data!.where((voucher) => voucher['type'] == 'Active').toList() : [];

                        if (createdVouchers.isEmpty) {
                          return Center(
                              child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                    Text('Buy your first voucher to experience the magic of UPI Vouchers!',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: math.max(14, screenWidth * 0.04))),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.amber,
                                            foregroundColor: Colors.black,
                                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                        icon: const Icon(Icons.star, size: 20),
                                        label: const Text('Experience UPI Magic', style: TextStyle(fontWeight: FontWeight.bold)),
                                        onPressed: () async {
                                          await Navigator.push(context, MaterialPageRoute(builder: (context) => const HowUpiVouchersWorks()));
                                          // after return, ask home to refresh via global service
                                          RefreshService.refresh();
                                        }),
                                  ])));
                        }

                        return ListView.builder(
                            clipBehavior: Clip.none,
                            scrollDirection: Axis.horizontal,
                            padding: EdgeInsets.symmetric(horizontal: math.max(12, screenWidth * 0.04)),
                            itemCount: createdVouchers.length,
                            itemBuilder: (context, index) {
                              final voucherData = createdVouchers[index];
                              final double rightPadding = (index == createdVouchers.length - 1) ? math.max(12, screenWidth * 0.04) : 16.0;
                              return Padding(
                                  padding: EdgeInsets.only(right: rightPadding),
                                  child: _buildVoucherCard(context, voucherData: voucherData, cardWidth: cardWidth));
                            });
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: _buildActionButtons(screenWidth: screenWidth)),
                  const SizedBox(height: 16),
                  _buildOffersSection(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
              icon: const Icon(Icons.sort, color: Colors.white),
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (context) => const AccountSettingsScreen()));
                RefreshService.refresh();
              }),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Hi, $name', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
          ),
          IconButton(
              icon: const Icon(Icons.notifications_none, color: Colors.white),
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsScreen()));
                RefreshService.refresh();
              }),
        ],
      ),
    );
  }

  Widget _buildVoucherCard(BuildContext context, {required Map<String, dynamic> voucherData, required double cardWidth}) {
    String title = voucherData['purposeDesc'] ?? 'N/A';
    String bankIconBase64 = voucherData['bankIcon'] ?? '';
    String redemptionType = voucherData['redemtionType'] ?? 'N/A';

    DateTime? expiryDate = _parseDate(voucherData['expDate']);
    String expiryText = expiryDate != null ? DateFormat('yyyy-MM-dd').format(expiryDate) : 'N/A';

    double amount = (voucherData['amount'] as num?)?.toDouble() ?? 0.0;
    String displayAmount = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2).format(amount);

    Widget bankIconWidget() {
      if (bankIconBase64.isNotEmpty) {
        try {
          final imageBytes = base64Decode(bankIconBase64);
          return Image.memory(imageBytes, width: 24, height: 24, fit: BoxFit.contain);
        } catch (e) {
          return const Icon(Icons.business, color: Colors.white, size: 24);
        }
      }
      return const Icon(Icons.business, color: Colors.white, size: 24);
    }

    final double titleFont = math.max(13, cardWidth * 0.055);
    final double amountFont = math.max(18, cardWidth * 0.08);

    return GestureDetector(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (context) => VoucherDetailScreen(voucherData: voucherData)));
        // refresh home after returning from details
        RefreshService.refresh();
      },
      child: Container(
        width: cardWidth,
        decoration: BoxDecoration(color: const Color(0xff2C2C2E), borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: bankIconWidget()),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: titleFont), maxLines: 1, overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 12),
          const Text('Amount', style: TextStyle(color: Colors.white70, fontSize: 11)),
          Text(displayAmount, style: TextStyle(color: Colors.white, fontSize: amountFont, fontWeight: FontWeight.bold)),
          const Spacer(),
          Divider(color: Colors.white.withOpacity(0.2), height: 1, thickness: 0.5),
          const SizedBox(height: 10),
          Row(children: [
            Icon(Icons.shield_outlined, color: Colors.white.withOpacity(0.9), size: 16),
            const SizedBox(width: 6),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(redemptionType, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
              Text('Expires on $expiryText', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10)),
            ]),
            const Spacer(),
            const Icon(Icons.arrow_forward, color: Colors.white, size: 16),
          ]),
        ]),
      ),
    );
  }

  Widget _buildActionButtons({required double screenWidth}) {
    final buttonWidth = math.max(88.0, (screenWidth - 48) / 3);
    return Wrap(spacing: 8, runSpacing: 8, children: [
      SizedBox(width: buttonWidth, child: _actionButton(imagePath: 'assets/issue_icon.png', label: 'Issue')),
      SizedBox(width: buttonWidth, child: _actionButton(imagePath: 'assets/add_icon.png', label: 'Add Bill')),
      SizedBox(width: buttonWidth, child: _actionButton(imagePath: 'assets/offer_icon.png', label: 'Rewards')),
    ]);
  }

  Widget _actionButton({required String imagePath, required String label}) {
    return Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: const Color(0xff2C2C2E), borderRadius: BorderRadius.circular(12)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Image.asset(imagePath, width: 20, height: 20, color: Colors.white),
          const SizedBox(width: 8),
          Flexible(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
        ]));
  }

  Widget _buildVoucherBalanceCard({required int count, required double totalAmount}) {
    String displayAmount = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    ).format(totalAmount);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xff2C2C2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset('assets/upi_logo.png', height: 22),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'ACTIVE VOUCHERS',
                    style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 0.5),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xff48484A),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      count.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.info_outline, color: Colors.white54, size: 16),
                ],
              ),
              Text(
                displayAmount,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOffersSection() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24.0))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 12),
        Center(child: Container(width: 48, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2.5)))),
        const SizedBox(height: 16),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 16.0), child: Text('OFFERS ON VOUCHERS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87, letterSpacing: 0.5))),
        const SizedBox(height: 8),
        _offerTile(icon: Icons.local_gas_station_outlined, title: 'Indian Oil', subtitle: 'Get up to 50% Cashback'),
        _offerTile(icon: Icons.local_shipping_outlined, title: 'Onboard 20+ Vehicles', subtitle: 'Get up to 50% Cashback'),
        _offerTile(icon: Icons.list_alt, title: 'Issue 5 Fuel Vouchers', subtitle: 'Get up to 50% Cashback'),
        const SizedBox(height: 90),
      ]),
    );
  }

  Widget _offerTile({required IconData icon, required String title, required String subtitle}) {
    return ListTile(
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xffE8F5E9), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: const Color(0xff34A853), size: 24)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
      onTap: () {},
    );
  }
}