import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:cotopay/util/refreshservice.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import 'account_settings_screen.dart';
import 'api_service.dart';
import 'history_screen.dart';
import 'issue_how_voucher_works.dart';
import 'notifications_screen.dart';
import 'qr_scanner_screen.dart';
import 'rewards_screen.dart';
import 'session_manager.dart';
import 'upi_voucher_scren.dart';
import 'voucher_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  bool _expanded = false;

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
        "mobile": ""
        // "mobile": userData.mobile
      };

      // Reassign future so FutureBuilder re-runs (and API is hit)
      setState(() {
        _voucherListFuture =
            _apiService.getVoucherList(params).then((response) {
              if (response != null &&
                  response['status'] == true &&
                  response['data'] is List) {
                debugPrint("📤 Home Response  $response");
                return response['data'] as List<dynamic>;
              } else {
                throw Exception(
                    response?['message'] ?? 'Failed to load vouchers');
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
      value: isHomePageSelected
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        extendBody: true,
        backgroundColor: Colors.white,
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            HomeContent(name: _name, voucherListFuture: _voucherListFuture,onIndexChange: (index){
              setState(() {
                _selectedIndex = index;
              });
            },),
            const SafeArea(child: UpiVouchersScreen()),
            //   const SafeArea(child: DecryptDemoScreen()),

            Container(),
            const SafeArea(child: RewardsScreen()),
            const SafeArea(child: HistoryScreen()),
          ],
        ),

        // Center the FAB
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

        // Centered FAB (slightly lowered so it visually sits inside the notch)
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(top: 78),
          child: SizedBox(
            width: 64,
            height: 64,
            child: FloatingActionButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => const QrScannerScreen()),
                );
                _loadInitialData();
              },

              backgroundColor: const Color(0xFF2F945A), // Figma bg color

              shape: const CircleBorder(
                side: BorderSide(
                  width: 2, // border-width: 2px
                  color: Color(0xFFEAF4EF), // border color #EAF4EF
                ),
              ),

              child: Padding(
                padding: const EdgeInsets.all(12), // padding: 12px
                child: SvgPicture.asset(
                  'assets/scan.svg',
                  width: 40,
                  height: 40,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
        ),

        // Responsive bottom bar (5 equal slots: 0,1,2(center placeholder),3,4)
        bottomNavigationBar: _buildBottomNavBarResponsive(),
      ),
    );
  }

  /*Widget _buildBottomNavBarResponsive() {
    // keep fabDiameter same as the FAB sized box above
    const double fabDiameter = 64.0;
    // smaller notch padding so reserved center space doesn't consume too much width
    const double notchPadding = 12.0;
    final double reservedCenterWidth = fabDiameter + notchPadding;

    // total height allocated to bottom bar (enough to hold icon + label)
    const double bottomBarHeight = 68.0;

    // This matches the Padding used below — we MUST subtract it from constraints
    const double horizontalPadding = 8.0;
    const double verticalPadding = 4.0;

    return BottomAppBar(
      color: Colors.white,
      elevation: 6,
      shape: const CircularNotchedRectangle(),
      notchMargin: 6,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: bottomBarHeight,
          child: LayoutBuilder(builder: (context, constraints) {
            final totalWidth = constraints.maxWidth;

            // SUBTRACT the horizontal padding so the computed slot widths fit inside the padded Row.
            final usableWidth = totalWidth - (horizontalPadding * 2);

            // Now reserve center width and divide remaining for 4 slots.
            final availableForSlots = usableWidth - reservedCenterWidth;
            final double slotWidth = (availableForSlots / 4.0).clamp(56.0, 160.0);

            // compute icon / font sizes once here so they are identical for all tiles
            final double iconSize = (slotWidth * 0.42).clamp(18.0, 28.0);
            final double fontSize = (slotWidth * 0.18).clamp(10.0, 13.0);

            return Padding(
              // must match horizontalPadding used above
              padding: const EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // left slot 0
                  _navTileFixed(width: slotWidth, iconPath: 'assets/home_b.png', label: 'Home', index: 0, iconSize: iconSize, fontSize: fontSize),
                  // left slot 1
                  _navTileFixed(width: slotWidth, iconPath: 'assets/voucher_b.png', label: 'Vouchers', index: 1, iconSize: iconSize, fontSize: fontSize),

                  // center reserved area for FAB (in layout only, empty widget)
                  SizedBox(width: reservedCenterWidth),

                  // right slot 3
                  _navTileFixed(width: slotWidth, iconPath: 'assets/offer_b.png', label: 'Rewards', index: 3, iconSize: iconSize, fontSize: fontSize),
                  // right slot 4
                  _navTileFixed(width: slotWidth, iconPath: 'assets/his_b.png', label: 'History', index: 4, iconSize: iconSize, fontSize: fontSize),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
*/

  Widget _buildBottomNavBarResponsive() {
    const double fabDiameter = 64.0;
    const double notchPadding = 12.0;
    const double reservedCenterWidth = fabDiameter + notchPadding;

    const double bottomBarHeight = 68.0;

    const double horizontalPadding = 8.0;
    const double verticalPadding = 4.0;

    return BottomAppBar(
      color: const Color(0xFFFFFFFF), // <-- Figma background color
      elevation: 6,
      //  shape: const CircularNotchedRectangle(),
      notchMargin: 6,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: bottomBarHeight,
          child: LayoutBuilder(builder: (context, constraints) {
            final totalWidth = constraints.maxWidth;
            final usableWidth = totalWidth - (horizontalPadding * 2);

            final availableForSlots = usableWidth - reservedCenterWidth;
            final double slotWidth =
            (availableForSlots / 4.0).clamp(56.0, 160.0);

            /// override iconSize ALWAYS with Figma value: 24px
            final double iconSize = 24;

            /// override fontSize ALWAYS with 11px from Figma
            final double fontSize = 11;

            return Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: horizontalPadding, vertical: verticalPadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _navTileFixed(
                      width: slotWidth,
                      iconPath: 'assets/home_b.svg',
                      label: 'Home',
                      index: 0,
                      iconSize: iconSize,
                      fontSize: fontSize),
                  _navTileFixed(
                      width: slotWidth,
                      iconPath: 'assets/voucher_b.svg',
                      label: 'Vouchers',
                      index: 1,
                      iconSize: iconSize,
                      fontSize: fontSize),
                  const SizedBox(width: reservedCenterWidth),
                  _navTileFixed(
                      width: slotWidth,
                      iconPath: 'assets/offer_b.svg',
                      label: 'Rewards',
                      index: 3,
                      iconSize: iconSize,
                      fontSize: fontSize),
                  _navTileFixed(
                      width: slotWidth,
                      iconPath: 'assets/his_b.svg',
                      label: 'History',
                      index: 4,
                      iconSize: iconSize,
                      fontSize: fontSize),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

/*
  Widget _navTileFixed({
    required double width,
    required String iconPath,
    required String label,
    required int index,
    required double iconSize,
    required double fontSize,
  })
  {
    final bool isSelected = _selectedIndex == index;
    final Color activeColor = const Color(0xFF34A853);
    final Color inactiveColor = Colors.grey.shade600;
    final color = isSelected ? activeColor : inactiveColor;

    // Prefer ImageIcon for reliable tinting. If your PNGs aren't monochrome use the ImageIcon with AssetImage.
    final Widget displayedIcon = SizedBox(
      width: iconSize,
      height: iconSize,
      child: ImageIcon(
        AssetImage(iconPath),
        size: iconSize,
        color: color,
      ),
    );

    return InkWell(
      onTap: () {
        if (!mounted) return;
        if (_selectedIndex == index) {
          if (index == 0) _loadInitialData();
          return;
        }
        setState(() {
          _selectedIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            displayedIcon,
            const SizedBox(height: 4),
            // hide label on very small slots (avoid wrapping)
            if (width >= 64)
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  fontSize: fontSize,
                  fontWeight: FontWeight.w400,
                  color: color,
                  height: 1.0,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }
*/

  Widget _navTileFixed({
    required double width,
    required String iconPath, // now supports SVG
    required String label,
    required int index,
    required double iconSize,
    required double fontSize,
  }) {
    final bool isSelected = _selectedIndex == index;

    const Color activeColor = Color(0xFF2F945A); // white on green bg
    final Color inactiveColor = const Color(0xFF86889B).withOpacity(0.7);
    final color = isSelected ? activeColor : inactiveColor;

    return InkWell(
      onTap: () {
        if (!mounted) return;
        setState(() {
          _selectedIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- SVG ICON (Figma: 24x24, opacity 1) ---
            SizedBox(
              width: 24,
              height: 24,
              child: SvgPicture.asset(
                iconPath,
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
              ),
            ),

            const SizedBox(height: 4),

            if (width >= 56)
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Open Sans',
                  fontSize: 11,
                  // Figma: 11px
                  fontWeight: FontWeight.w400,
                  // Regular
                  height: 1.4,
                  // 140%
                  letterSpacing: 0.0,
                ).copyWith(color: color),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  final String name;
  final Future<List<dynamic>>? voucherListFuture;
  final void Function(int) onIndexChange;

  const HomeContent({super.key, required this.name, this.voucherListFuture, required this.onIndexChange,});

  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr
        .trim()
        .isEmpty) {
      return null;
    }
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
    final double statusBarHeight = MediaQuery
        .of(context)
        .padding
        .top;
    // final screenWidth = MediaQuery.of(context).size.width;
    // final screenHeight = MediaQuery.of(context).size.height;

    const double visibleHeight = 410.0; // fixed visible area (px)
    const double visibleTop =
    494.0; // (optional) if you want to position using absolute top
    final Size screenSize = MediaQuery
        .of(context)
        .size;
    final double screenHeight = screenSize.height;
    final double screenWidth = screenSize.width;

    // card width / carousel height (responsive)
    final double cardWidth = (screenWidth < 360)
        ? screenWidth * 0.82
        : (screenWidth < 600 ? math.min(300, screenWidth * 0.66) : 340);
    final double carouselHeight = math.max(150, cardWidth * 0.65);

    // Estimate top area height so the draggable sheet starts below it.
    final double topAreaEstimatedHeight =
        statusBarHeight + 12 + 110 + carouselHeight + 16 + 88;

    final double initialSheetFraction =
        (screenHeight - topAreaEstimatedHeight) / screenHeight;
    final double initialChildSize =
    (visibleHeight / screenHeight).clamp(0.05, 0.9);

    return Stack(
      children: [
        Container(color: const Color(0xff1C1C1E)),
        SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top bar
              Container(
                  color: const Color(0xff1C1C1E), child: _topBar(context)),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FutureBuilder<List<dynamic>>(
                  future: voucherListFuture,
                  builder: (context, snapshot) {
                    int activeVoucherCount = 0;
                    double totalAmount = 0.0;
                    if (snapshot.connectionState == ConnectionState.done &&
                        snapshot.hasData &&
                        !snapshot.hasError) {
                      final createdVouchers = snapshot.data!
                          .where((voucher) => voucher['type'] == 'Active')
                          .toList();
                      activeVoucherCount = createdVouchers.length;
                      totalAmount = createdVouchers.fold(
                          0.0,
                              (sum, item) =>
                          sum +
                              ((item['amount'] as num?)?.toDouble() ?? 0.0));
                    }
                    return _voucherBalanceCard(context,
                        count: activeVoucherCount, totalAmount: totalAmount);
                  },
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: carouselHeight,
                child: FutureBuilder<List<dynamic>>(
                  future: voucherListFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child:
                          CircularProgressIndicator(color: Colors.white));
                    }
                    /*if (snapshot.hasError) {
                      return Center(
                          child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                    }*/

                    final createdVouchers = snapshot.hasData
                        ? snapshot.data!
                        .where((voucher) => voucher['type'] == 'Active')
                        .toList()
                        : [];

                    if (createdVouchers.isEmpty) {
                      return Center(
                          child: Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal:
                                  math.max(24.0, screenWidth * 0.06)),
                              child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                        'Buy your first voucher to experience the magic of UPI Vouchers!',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            color:
                                            Colors.white.withOpacity(0.8),
                                            fontSize: math.max(
                                                13, screenWidth * 0.038))),
                                    const SizedBox(height: 12),
                                    ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.amber,
                                            foregroundColor: Colors.black,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 20, vertical: 10),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                BorderRadius.circular(12))),
                                        icon: const Icon(Icons.star, size: 18),
                                        label: const Text(
                                            'Experience UPI Magic',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        onPressed: () async {
                                          await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                  const HowUpiVouchersWorks()));
                                          RefreshService.refresh();
                                        }),
                                  ])));
                    }

                    return ListView.builder(
                        clipBehavior: Clip.none,
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(
                            horizontal: math.max(12, screenWidth * 0.04)),
                        itemCount: createdVouchers.length,
                        itemBuilder: (context, index) {
                          final voucherData = createdVouchers[index];
                          final double rightPadding =
                          (index == createdVouchers.length - 1)
                              ? math.max(12, screenWidth * 0.04)
                              : 16.0;
                          return Padding(
                              padding: EdgeInsets.only(right: rightPadding),
                              child: _voucherCard(context,
                                  voucherData: voucherData,
                                  cardWidth: cardWidth));
                        });
                  },
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _actionButtons(screenWidth: screenWidth,context)),
              const SizedBox(height: 14),
            ],
          ),
        ),
        DraggableScrollableSheet(
          initialChildSize: initialChildSize,
          // user cannot collapse below visibleHeight
          minChildSize: initialChildSize,
          // allow user to expand up to 70% of screen
          maxChildSize: 0.75,
          builder: (context, scrollController) {
            return Container(
              // decoration + bottom border
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.vertical(top: Radius.circular(20.0)),
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 8)
                ],
                border: Border(
                    bottom: BorderSide(
                        width: 1.0,
                        color: Color(0xFFE0E0E0))), // 1px bottom border
              ),
              // content
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      // optional spacing tweak
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'OFFERS ON VOUCHERS'.toUpperCase(),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                            // Medium 500
                            fontSize: 12.0,
                            height: 1.4,
                            // 140% line-height
                            letterSpacing: 0.48,
                            // 4% of 12px
                            color: Color(0xFF1F212C), // black87
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Divider(
                    color: Color(0xFFF1F1F1),
                    thickness: 1,
                    height: 1,
                  ),

//                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.only(bottom: 90, top: 6),
                      children: [
                        // _offerTile(
                        //     icon: Icons.local_gas_station_outlined,
                        //     title: 'Indian Oil',
                        //     subtitle: 'Get up to 50% Cashback'),
                        _offerTile(
                            icon: Icons.local_shipping_outlined,
                            title: 'Onboard 20+ Vehicles',
                            subtitle: 'Get up to ₹100 Cashback'),
                        _offerTile(
                            icon: Icons.list_alt,
                            title: 'Issue 5 Fuel Vouchers',
                            subtitle: 'Get up to ₹100 Cashback'),
                        const SizedBox(height: 8),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // Small top bar inside HomeContent
  Widget _topBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.sort, color: Colors.white),
            onPressed: () async {
              await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AccountSettingsScreen()));
              RefreshService.refresh();
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Hi, $name',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () async {
              await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const NotificationsScreen()));
              RefreshService.refresh();
            },
          ),
        ],
      ),
    );
  }

  Widget _voucherBalanceCard(BuildContext context,
      {required int count, required double totalAmount}) {
    String displayAmount = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹ ',
      decimalDigits: 2,
    ).format(totalAmount);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xff1D1E22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(width: 1, color: const Color(0xFF86889B)),
      ),
      child: StatefulBuilder(
        builder: (context, setState) {
          // local state variable inside builder
          bool _expanded = false;
          // NOTE: We can't declare _expanded here and expect it to persist between rebuilds.
          // Use a captured variable via closure using a local variable outside builder:
          return _VoucherBalanceInner(
            count: count,
            displayAmount: displayAmount,
          );
        },
      ),
    );
  }

  Widget _voucherCard(BuildContext context,
      {required Map<String, dynamic> voucherData, required double cardWidth}) {
    String title = voucherData['purposeDesc'] ?? 'N/A';
    String bankIconBase64 = voucherData['bankIcon'] ?? '';
    String redemptionType = voucherData['redemtionType'] ?? 'N/A';

    debugPrint('redemptionType => $redemptionType');
    print('redemptionType = $redemptionType');
    print('asset loaded = ' +
        (redemptionType.toLowerCase() == 'multiple'
            ? 'multiple.svg'
            : 'single.svg'));

    DateTime? expiryDate = _parseDate(voucherData['expDate']);
    String expiryText = expiryDate != null
        ? DateFormat('yyyy-MM-dd').format(expiryDate)
        : 'N/A';

    double amount = (voucherData['amount'] as num?)?.toDouble() ?? 0.0;
    String displayAmount =
    NumberFormat.currency(locale: 'en_IN', symbol: '₹ ', decimalDigits: 2)
        .format(amount);

    Widget bankIconWidget() {
      if (bankIconBase64.isNotEmpty) {
        try {
          final imageBytes = base64Decode(bankIconBase64);
          return Image.memory(imageBytes,
              width: 22, height: 22, fit: BoxFit.contain);
        } catch (e) {
          return const Icon(Icons.business, color: Colors.white, size: 24);
        }
      }
      return const Icon(Icons.business, color: Colors.white, size: 24);
    }

    final double titleFont = math.max(12, cardWidth * 0.05);
    final double amountFont = math.max(16, cardWidth * 0.075);

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    VoucherDetailScreen(voucherData: voucherData)));
        RefreshService.refresh();
      },
      child: SizedBox(
        width: 225,
        child: Stack(
          clipBehavior: Clip.none, // allows SVG to overflow card
          children: [
            // ⭐ LEFT CURVED LINE SVG (added here)
            Positioned(
              left: -7.5,
              top: 0,
              bottom: 0,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  bottomLeft: Radius.circular(16),
                ),
                child: SizedBox(
                  height: 148,
                  child: SvgPicture.asset(
                    'assets/left_line.svg',
                    fit: BoxFit.fitHeight,
                  ),
                ),
              ),
            ),

            // ⭐ MAIN CARD
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xff26282C),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 12,
                    ),
                    VerticalDivider(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                      thickness: 1,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const SizedBox(
                            height: 5,
                          ),
                          Padding(
                            padding: const EdgeInsetsGeometry.all(10.0),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xffE3E3E3)
                                            .withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: bankIconWidget(),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontFamily: 'Inter',
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16.0,
                                              height: 1.6,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const Text(
                                            'CotoPay',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontWeight: FontWeight.w400,
                                              fontSize: 12.0,
                                              height: 1.4,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ]),
                                  const SizedBox(height: 5),
                                  const Text(
                                    'Amount',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w400,
                                      fontSize: 12.0,
                                      height: 1.4,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    displayAmount,
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 20.0,
                                      height: 1.4,
                                      color: Colors.white,
                                    ),
                                  ),
                                ]),
                          ),
                          const SizedBox(
                            height: 4,
                          ),
                          Divider(
                              color: Colors.white.withOpacity(0.2), height: 1),
                          const SizedBox(
                            height: 4,
                          ),
                          Padding(
                              padding: const EdgeInsetsGeometry.all(10.0),
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  // TEXT BLOCK
                                  Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          (redemptionType.toLowerCase() ==
                                              'multiple')
                                              ? SvgPicture.asset(
                                            'assets/multiple.svg',
                                            width: 20,
                                            height: 20,
                                            colorFilter: ColorFilter.mode(
                                              Colors.white
                                                  .withOpacity(0.9),
                                              BlendMode.srcIn,
                                            ),
                                          )
                                              : SvgPicture.asset(
                                            'assets/single.svg',
                                            width: 20,
                                            height: 20,
                                            colorFilter: ColorFilter.mode(
                                              Colors.white
                                                  .withOpacity(0.9),
                                              BlendMode.srcIn,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                left: 5.0),
                                            child: Text(
                                              redemptionType,
                                              style: const TextStyle(
                                                fontFamily: 'Inter',
                                                fontWeight: FontWeight.w400,
                                                fontSize: 14.0,
                                                height: 1.4,
                                                color: Colors.white,
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                      Padding(
                                        padding:
                                        const EdgeInsets.only(left: 2.0),
                                        child: Text(
                                          'Expires on $expiryText',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w400,
                                            fontSize: 12.0,
                                            height: 1.4,
                                            color:
                                            Colors.white.withOpacity(0.7),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const Spacer(),

                                  // RIGHT ARROW
                                  SvgPicture.asset(
                                    'assets/arr.svg',
                                    width: 18,
                                    height: 9,
                                    fit: BoxFit.contain,
                                  ),
                                ],
                              )),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Put this where your other widget methods are (keep `import 'dart:math' as math;` at top)
  Widget _actionButtons(BuildContext context,{required double screenWidth}) {
    const double designButtonWidth = 125.0;
    const double designButtonHeight = 52.0;
    const double horizontalPadding = 16.0;
    const double spacingBetweenButtons = 8.0;

    final double available = math.max(
      0.0,
      screenWidth - (horizontalPadding * 2) - (spacingBetweenButtons * 2),
    );

    final double candidateWidth = available / 3.0;
    final double buttonWidth = candidateWidth.clamp(88.0, 160.0);
    final double scale = (buttonWidth / designButtonWidth).clamp(0.7, 1.3);

    final double buttonHeight = (designButtonHeight * scale).clamp(44.0, 70.0);

    // Figma → fixed sizes:
    const double iconSize = 24.0;
    const double fontSize = 14.0;

    final double gap = (8.0 * scale).clamp(6.0, 12.0);
    final double radius = (10.0 * scale).clamp(8.0, 16.0);
    final double padV = (16.0 * scale).clamp(10.0, 20.0);
    final double padH = (10.0 * scale).clamp(8.0, 20.0);

    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: spacingBetweenButtons,
        runSpacing: spacingBetweenButtons,
        children: [
          SizedBox(
            width: buttonWidth,
            height: buttonHeight,
            child: _actionButton(
                imagePath: 'assets/issue_icon.svg',
                label: 'Issue',
                iconSize: iconSize,
                fontSize: fontSize,
                gap: gap,
                radius: radius,
                padV: padV,
                padH: padH,
                onTap: () {
                  onIndexChange(1);
                }
            ),
          ),
          SizedBox(
            width: buttonWidth,
            height: buttonHeight,
            child: _actionButton(
              imagePath: 'assets/add_icon.svg',
              label: 'Add Bill',
              iconSize: iconSize,
              fontSize: fontSize,
              gap: gap,
              radius: radius,
              padV: padV,
              padH: padH,
            ),
          ),
          SizedBox(
            width: buttonWidth,
            height: buttonHeight,
            child: _actionButton(
              imagePath: 'assets/offer_icon.svg',
              label: 'Rewards',
              iconSize: iconSize,
              fontSize: fontSize,
              gap: gap,
              radius: radius,
              padV: padV,
              padH: padH,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String imagePath, // now expects SVG path (or PNG too)
    required String label,
    double iconSize = 24.0, // Figma 24px
    double fontSize = 14.0, // Figma 14px
    double gap = 8.0,
    double radius = 10.0,
    double padV = 16.0,
    double padH = 10.0,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap ?? () {},
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: padV, horizontal: padH),
        decoration: BoxDecoration(
          color: const Color(0xff2C2C2E),
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Use SvgPicture.asset for SVGs (falls back to Image.asset if you pass a PNG)
            SizedBox(
              width: iconSize,
              height: iconSize,
              child: imagePath.toLowerCase().endsWith('.svg')
                  ? SvgPicture.asset(
                imagePath,
                width: iconSize,
                height: iconSize,
                fit: BoxFit.contain,
                // tint the SVG (like color in Image.asset)
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              )
                  : Image.asset(
                imagePath,
                width: iconSize,
                height: iconSize,
                fit: BoxFit.contain,
                color: Colors.white,
              ),
            ),

            SizedBox(width: gap),

            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                  fontSize: fontSize,
                  height: 1.4,
                  letterSpacing: 0.0,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _offerTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      child: ListTile(
        leading: Opacity(
          opacity: 1.0,
          child: Container(
            width: 40,
            height: 40,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF4EF), // background
              borderRadius: BorderRadius.circular(8.33), // 8.33px radius
              border: Border.all(
                color: const Color(0xFFBFDECC), // #BFDECC
                width: 0.69, // 0.69px
              ),
            ),
            child: Icon(
              icon,
              size: 24,
              color: const Color(0xff34A853),
            ),
          ),
        ),

        // TITLE TEXT (Inter SemiBold, 14px, 140%)
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 14,
            height: 1.4,
            // 140%
            letterSpacing: 0.0,
            color: Color(0xFF1F212C),
          ),
        ),

        // SUBTITLE TEXT (Inter Regular, 12px, 140%)
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
            fontSize: 12,
            height: 1.4,
            // 140%
            letterSpacing: 0.0,
            color: Color(0xFF2F945A), // change if you want white
          ),
        ),

        onTap: () {},
      ),
    );
  }
}

class _VoucherBalanceInner extends StatefulWidget {
  final int count;
  final String displayAmount;

  const _VoucherBalanceInner(
      {required this.count, required this.displayAmount});

  @override
  State<_VoucherBalanceInner> createState() => _VoucherBalanceInnerState();
}

class _VoucherBalanceInnerState extends State<_VoucherBalanceInner> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_expanded)
          Padding(
            padding: const EdgeInsets.only(left: 2.45, top: 2.09),
            child: SvgPicture.asset(
              'assets/upi_logo.svg',
              width: 59.78786849975586,
              height: 22.389692306518555,
            ),
          ),
        if (_expanded)
          Opacity(
            opacity: 1.0,
            child: SizedBox(
              /* width: 330,
              height: 30,*/
              child: Text(
                'This is the value of active vouchers at the time of creation.The current balance of the active vouchers may vary as per usage.',
                textAlign: TextAlign.left,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Open Sans',
                  fontWeight: FontWeight.w400,
                  fontSize: 11.0,
                  height: 1.4,
                  letterSpacing: 0.0,
                  color: Color(0xFFC7C8D1),
                ),
              ),
            ),
          ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'ACTIVE VOUCHERS',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    fontSize: 10.0,
                    height: 1.4,
                    letterSpacing: 0.0,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xff48484A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    widget.count.toString(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: _expanded
                      ? SvgPicture.asset('assets/revoke.svg',
                      width: 20, height: 20)
                      : SvgPicture.asset('assets/info.svg',
                      width: 20, height: 20),
                ),
                const SizedBox(width: 8),
              ],
            ),
            Text(
              widget.displayAmount,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 24.0,
                height: 1.0,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
