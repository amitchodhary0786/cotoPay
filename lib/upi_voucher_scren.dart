import 'dart:convert';
import 'dart:typed_data';
import 'package:cotopay/vouchers_history.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'approve_vouchers_screen.dart';
import 'issue_voucher_screen.dart';
import 'api_service.dart';
import 'package:cotopay/session_manager.dart';
import 'package:intl/intl.dart';
import 'account_settings_screen.dart';

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

  // selection & summary state
  String _selectedBankName = "All Linked Bank Accounts";
  String? _selectedBankAccount; // accNumber to send to getBankSummary
  DateTime? _lastUpdated;

  // values to show on green card
  String _activeCount = "0";
  double _activeAmount = 0.0;



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
      final response = await _apiService.getBankListUpi(params);

      if (response == null || response['status'] != true || response['data'] == null) {
        throw Exception(response?['message'] ?? 'Failed to load banks');
      }

      final List<dynamic> data = List<dynamic>.from(response['data']);

      if (!mounted) return;

      // set default selected bank: prefer "All Bank" if present
      String defaultName = _selectedBankName;
      String? defaultAcc;
      final allBank = data.firstWhere(
            (b) {
          final bn = (b['bankName'] ?? '').toString().toLowerCase();
          return bn.contains('all');
        },
        orElse: () => null,
      );
      if (allBank != null) {
        defaultName = (allBank['bankName'] ?? 'All Linked Bank Accounts').toString();
        defaultAcc = (allBank['bankAccount'] ?? allBank['acNumber'] ?? allBank['account'])?.toString();
      }

      setState(() {
        _banks = data;
        _loadingBanks = false;
        _lastUpdated = DateTime.now();
        _selectedBankName = defaultName;
        _selectedBankAccount = defaultAcc ?? ''; // empty means all
      });

      // fetch summary for default selection (All)
      await _fetchBankSummary( _selectedBankAccount ?? '');
    } catch (e) {
      debugPrint("Error loading bank list: $e");
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loadingBanks = false;
      });
    }
  }

  Future<void> _fetchBankSummary( String accNumber) async {
    try {
      final userData = await SessionManager.getUserData();
      if (userData == null || userData.employerid == null) {
        throw Exception("User not available");
      }


      // show a small loading effect for card (optional) - here we'll update lastUpdated only when success
      final params = {"orgId": userData.employerid, "accNumber": accNumber};
      final response = await _apiService.getBankSummary(params);

      if (response == null || response['status'] != true) {
        throw Exception(response?['message'] ?? 'Failed to fetch bank summary');
      }

      final issueDetail = response['issueDetail'];
      final totalIssueCount = (issueDetail?['activeCount'] ?? '0').toString();
      final totalIssueAmountRaw = issueDetail?['activeAmount'];
      double totalIssueAmount = 0.0;
      if (totalIssueAmountRaw is num) {
        totalIssueAmount = totalIssueAmountRaw.toDouble();
      } else if (totalIssueAmountRaw is String) {
        totalIssueAmount = double.tryParse(totalIssueAmountRaw) ?? 0.0;
      }

      if (!mounted) return;
      setState(() {
        _activeCount = totalIssueCount;
        _activeAmount = totalIssueAmount;
        _lastUpdated = DateTime.now();
      });
    } catch (e) {
      debugPrint("Error fetching bank summary: $e");
      // do not throw UI-blocking error; keep previous values but update lastUpdated time if you want
      if (!mounted) return;
      setState(() {
        _error = e.toString();
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

                          // Map API fields correctly
                          final bankName = (bank['bankName'] ?? bank['name'] ?? 'Unknown Bank').toString();
                          final account = (bank['bankAccount'] ?? bank['acNumber'] ?? bank['account'] ?? '').toString();
                          final maskedFromApi = bank['bankAccountMask']?.toString();
                          final masked = (maskedFromApi != null && maskedFromApi.trim().isNotEmpty) ? maskedFromApi : _maskAccount(account);

                          final bankLogoBase64 = bank['bankLogo']?.toString();

                          final isDefaultWallet = (bank['accountSeltWallet'] == "Wallet");

                          return ListTile(
                            onTap: () async {
                              // update selected and call summary
                              final userData = await SessionManager.getUserData();
                              if (userData == null || userData.employerid == null) {
                                // fallback: just set name
                                setState(() {
                                  _selectedBankName = bankName;
                                  _selectedBankAccount = account;
                                });
                                Navigator.of(ctx).pop();
                                return;
                              }

                              setState(() {
                                _selectedBankName = bankName;
                                _selectedBankAccount = account;
                                _loadingBanks = false;
                              });

                              Navigator.of(ctx).pop();

                              // call summary API for selected bank
                              await _fetchBankSummary( account ?? '');
                            },
                            leading: _bankIconWidget(bankLogoBase64, size: 44, fallbackText: bankName),
                            title: Text(bankName, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: isDefaultWallet ? const Text('Default', style: TextStyle(fontSize: 12, color: Colors.green)) : null,
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
  Widget _bankIconWidget(String? rawBase64, {double size = 40, String? fallbackText}) {
    if (rawBase64 == null || rawBase64.trim().isEmpty) return _initialsAvatar(fallbackText, size: size);
    try {
      String cleaned = rawBase64.trim();

      // if the API accidentally returns a data URI like "data:image/png;base64,...."
      if (cleaned.contains(',')) {
        cleaned = cleaned.split(',').last;
      }

      // sometimes there might be padding/newlines, remove them
      cleaned = cleaned.replaceAll(RegExp(r'\s+'), '');

      final Uint8List bytes = base64Decode(cleaned);
      return CircleAvatar(radius: size / 2, backgroundColor: Colors.transparent, backgroundImage: MemoryImage(bytes));
    } catch (e) {
      debugPrint("bankIcon decode error: $e");
      return _initialsAvatar(fallbackText, size: size);
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

    const double _cardWidth = 330;
    const double _cardHeight = 44;
    const double _cardRadius = 10;
    const double _horizontalPadding = 10; // corresponds to padding: 10px
    const double _iconContainerSize = 24;
    const double _badgeWidth = 50;
    const double _badgeHeight = 23;

    // responsive sizes
    final horizontalPadding = clampDouble(screenWidth * 0.07, 12, 24);
    final sectionRadius = clampDouble(screenWidth * 0.04, 12, 20);
    final internalRadius = clampDouble(screenWidth * 0.02, 8, 14);
    final iconSize = clampDouble(screenWidth * 0.05, 18, 28);
    final labelFont = clampDouble(screenWidth * 0.038, 14, 18);
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
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600, // Semi Bold
            fontSize: 16,
            height: 1.4, // 140% line height
            letterSpacing: 0,
            color: Color(0xFF4A4E69), // #4A4E69
          ),
        ),


        leading: IconButton(icon: const Icon(Icons.sort, color: Colors.black), onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AccountSettingsScreen()));

          // Navigator.push(
          //   context,
          //   MaterialPageRoute(builder: (context) => DecryptDemoScreen()),
          // );
        }),

        actions: [IconButton(icon: const Icon(Icons.notifications_none, color: Colors.black), onPressed: () {})],


      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Column(
       //   crossAxisAlignment: CrossAxisAlignment.start,
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
                                  SvgPicture.asset(
                                    'assets/bank.svg',
                                    width: iconSize * 0.9,
                                    height: iconSize * 0.9,
                                    fit: BoxFit.contain,
                                  ),
                                  SizedBox(width: horizontalPadding * 0.6),
                                  Expanded(
                                    child: Text(
                                      _selectedBankName,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w400, // Regular
                                        fontSize: 14,
                                        height: 1.4, // 140%
                                        letterSpacing: 0,
                                        color: Color(0xFFFFFFFF), // White
                                      ),
                                    ),
                                  ),



                                  SvgPicture.asset(
                                    'assets/expand.svg',       // update path as required
                                    width: 20,
                                    height: 20,
                                    colorFilter: const ColorFilter.mode(
                                      Colors.white70,                // matches your earlier color usage
                                      BlendMode.srcIn,
                                    ),
                                  )

                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: horizontalPadding),

                          // Active Vouchers row -> now showing values from API
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "Active Vouchers",
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w400,
                                    fontSize: 14,
                                    height: 1.4, // 140% line height
                                    letterSpacing: 0,
                                    color: const Color(0xFFEAF4EF),
                                  ),
                                ),
                              ),

                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    _activeCount,
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w600, // Semi Bold
                                      fontSize: 16,
                                      height: 1.4, // 140%
                                      letterSpacing: 0,
                                      color: const Color(0xFFFFFFFF),
                                    ),
                                  ),
                                  Container(width: 1, height: screenHeight * 0.03, margin: EdgeInsets.symmetric(horizontal: horizontalPadding * 0.6), color: Colors.white.withOpacity(0.4)),
                                  Text(
                                    "₹${_activeAmount.toStringAsFixed(
                                      _activeAmount.truncateToDouble() == _activeAmount ? 0 : 2,
                                    )}",
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w600, // Semi Bold
                                      fontSize: 16,
                                      height: 1.4, // 140%
                                      letterSpacing: 0,
                                      color: const Color(0xFFFFFFFF),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // divider & last updated row
                    // Put this where your original footer Container is
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                      child: Container(
                        color: const Color(0xFF2F945A),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Divider(color: Colors.white.withOpacity(0.18), height: 1),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: horizontalPadding,
                                vertical: horizontalPadding * 0.1,
                              ),
                              child: Row(
                                children: [
                                  // Spacer left to push center alignment to exact middle
                                  const SizedBox(width: 20),

                                  // Centered text (keeps true center regardless of icon width)
                                  Expanded(
                                    child: Center(
                                      child: Text(
                                        _formatLastUpdated(_lastUpdated),
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w400, // Regular
                                          fontSize: 12,
                                          height: 1.4, // 140% line-height
                                          letterSpacing: 0,
                                          color: Color(0xFF9FCEB3), // #9FCEB3
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Refresh icon aligned at right
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 20,
                                      minHeight: 20,
                                    ),
                                    onPressed: () async {
                                      final userData = await SessionManager.getUserData();
                                      if (userData != null && userData.employerid != null) {
                                        await _loadBankList();
                                        await _fetchBankSummary(_selectedBankAccount ?? '');
                                      } else {
                                        await _loadBankList();
                                      }
                                    },
                                    icon: const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: Icon(
                                        Icons.refresh,
                                        size: 20,
                                        color: Color(0xFF9FCEB3),
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
                  ],
                ),
              ),
            ),

            SizedBox(height: horizontalPadding * 0.7),

            // --- WHITE rounded section (Office UPI Vouchers)


        FutureBuilder<int?>(


          future: SessionManager.getRoleId(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(); // can show loader if needed
            }

            final roleId = snapshot.data;

               debugPrint('Role ID: $roleId');


          if (roleId == 8 || roleId == 9 || roleId == 99) {
              return Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(sectionRadius),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // header
                          Padding(
                            padding: EdgeInsets.only(
                              top: horizontalPadding * 0.0,
                              bottom: horizontalPadding * 0.4,
                            ),
                            child: Text(
                              "Office UPI Vouchers",
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600, // Semi Bold
                                fontSize: 16,
                                height: 1.4, // 140%
                                letterSpacing: 0,
                                color: Color(0xFF1F212C), // #1F212C
                              ),
                            ),

                          ),

                          // Issue Voucher
                          InkWell(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (c) => const IssueVoucherScreen()),
                            ),
                            child: Container(
                                padding: const EdgeInsets.all(_horizontalPadding),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF26282C),                // background: #26282C
                                  borderRadius: BorderRadius.circular(_cardRadius),
                                  border: Border.all(
                                    color: const Color(0xFFEDEDF0),              // border: 1px solid #EDEDF0
                                    width: 1,
                                  ),
                                  // subtle elevation if needed (optional)
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [

                                    // LEFT SIDE (Icon + Title)
                                    Expanded(
                                      child: Row(
                                        children: [
                                          // Icon
                                          Container(
                                            padding: EdgeInsets.all(_horizontalPadding * 0.45),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(8),
                                              color: Colors.white.withOpacity(0.06),
                                            ),
                                            child: SvgPicture.asset(
                                              'assets/isue_vou.svg',
                                              width: _iconContainerSize,
                                              height: _iconContainerSize,
                                              colorFilter: const ColorFilter.mode(
                                                Colors.white,
                                                BlendMode.srcIn,
                                              ),
                                            ),
                                          ),

                                          SizedBox(width: _horizontalPadding * 0.8),

                                          // Title — USE EXPANDED HERE
                                          Expanded(
                                            child: Text(
                                              "Issue Voucher",
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontFamily: 'Inter',
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                                height: 1.4,
                                                letterSpacing: 0,
                                                color: Color(0xFFFFFFFF),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    SizedBox(width: 8),

                                    // RIGHT SIDE BADGE
                                    Container(
                                      width: _badgeWidth,
                                      height: _badgeHeight,
                                      decoration: BoxDecoration(
                                        color: Color(0xFFFFC312),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Center(
                                        child: Text(
                                          "Admin",
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontFamily: 'Open Sans',
                                            fontWeight: FontWeight.w400,
                                            fontSize: 11,
                                            height: 1.4,
                                            letterSpacing: 0,
                                            color: Color(0xFF1F212C),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )

                              ),
                          ),

                          SizedBox(height: horizontalPadding * 0.9),

                          // white tiles container

                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(internalRadius),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _listTile(
                                  icon: 'assets/apr.svg',
                                  title: "Approve Vouchers",
                                  iconSize: iconSize,
                                  textSize: labelFont,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (c) => const ApproveVouchersScreen()),
                                  ),
                                ),

                                const Divider(height: 1, color: Color(0xffF1F1F1)),

                                _listTile(
                                  icon: 'assets/countvc.svg',
                                  title: _activeCount,
                                  iconSize: iconSize,
                                  textSize: labelFont,
                                  onTap: () {},
                                ),

                                const Divider(height: 1, color: Color(0xffF1F1F1)),

                                _listTile(
                                  icon: 'assets/countvc.svg',
                                  title: "Voucher History",
                                  iconSize: iconSize,
                                  textSize: labelFont,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (c) => const VouchersScreen()),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // SizedBox(height: horizontalPadding * 0.9),
                        ],
                      ),
                    ),
                  ),
             //     SizedBox(height: horizontalPadding * 1.0),
                ],
              );
            } else {
              return const SizedBox.shrink(); // hide if not roleId 8 or 9
            }

          },
        ),





          ],
        ),
      ),
    );
  }

  Widget _listTile({
    required String icon,           // asset path, e.g. 'assets/apr.svg'
    required String title,
    double iconSize = 24,           // per spec (24x24)
    double textSize = 14,           // per spec (14px)
    required VoidCallback onTap,
  }) {
    // muted leading icon color from your earlier code
   // const Color leadingIconTint = Color(0xFF5E5E6B); // muted color
    const Color titleColor = Color(0xFF4A4E69);     // #4A4E69 (Figma)
   // final Color trailingChevronColor = Colors.grey.shade400;

    Widget leadingIconWidget;
    if (icon.toLowerCase().endsWith('.svg')) {
      leadingIconWidget = SvgPicture.asset(
        icon,
        width: iconSize,
        height: iconSize,
        fit: BoxFit.contain,
        // If you want to tint the svg: uncomment the colorFilter line
      //  colorFilter: const ColorFilter.mode(leadingIconTint, BlendMode.srcIn),
      );
    } else {
      leadingIconWidget = Image.asset(
        icon,
        width: iconSize,
        height: iconSize,
        fit: BoxFit.contain,
   //     color: leadingIconTint, // this tints raster images; remove if undesired
      );
    }

    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          children: [
            leadingIconWidget,
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600, // Semi Bold (600)
                  fontSize: textSize,          // 14 per spec
                  height: 1.4,                 // 140% line-height
                  letterSpacing: 0,
                  color: titleColor,           // #4A4E69
                ),
              ),
            ),
            SvgPicture.asset(
              'assets/arr.svg',
            //  width: 20,
             // height: 20,
            /*  colorFilter: ColorFilter.mode(
           //     trailingChevronColor,
                BlendMode.srcIn,
              ),*/
            )

          ],
        ),
      ),
    );
  }
}
