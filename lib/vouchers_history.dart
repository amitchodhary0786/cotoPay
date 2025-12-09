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
import 'voucher_detail_screen.dart';

// Note: keep your other imports as before.

// No changes needed for FilterBottomSheet, it remains the same.
class FilterBottomSheet extends StatefulWidget {
  final Function(Map<String, bool> selectedCategories, String? selectedTimePeriod) onApplyFilter;
  final Map<String, bool> initialCategories;
  final String? initialTimePeriod;

  const FilterBottomSheet({
    super.key,
    required this.onApplyFilter,
    required this.initialCategories,
    this.initialTimePeriod,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  int _activeFilterIndex = 0;
  late Map<String, bool> _categories;
  late String? _selectedTimePeriod;
  final List<String> _timePeriods = ['Current Month', 'Last Month', 'Current Financial Year', 'Last Financial Year', 'All History'];

  @override
  void initState() {
    super.initState();
    _categories = Map.from(widget.initialCategories);
    _selectedTimePeriod = widget.initialTimePeriod;
  }

  void _clearFilters() {
    setState(() {
      _categories.updateAll((key, value) => false);
      _selectedTimePeriod = 'All History';
    });
  }

  void _applyAndClose() {
    widget.onApplyFilter(_categories, _selectedTimePeriod);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text('FILTER BY', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, letterSpacing: 0.8)),
          ),
          const Divider(height: 24),
          SizedBox(
            height: 280,
            child: Row(children: [_buildLeftPane(), const VerticalDivider(width: 1, thickness: 1), _buildRightPane()]),
          ),
          const Divider(height: 1),
          Padding(padding: const EdgeInsets.all(16.0), child: _buildActionButtons())
        ],
      ),
    );
  }

  Widget _buildLeftPane() {
    return SizedBox(
      width: 150,
      child: Column(
        children: [
          _buildFilterSelector('Category Type', 0),
          _buildFilterSelector('Select Time Period', 1),
        ],
      ),
    );
  }

  Widget _buildFilterSelector(String title, int index) {
    final bool isActive = _activeFilterIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _activeFilterIndex = index;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        color: isActive ? Colors.blue.withOpacity(0.05) : Colors.transparent,
        child: Text(title, style: TextStyle(fontWeight: isActive ? FontWeight.bold : FontWeight.normal, color: isActive ? Colors.blue.shade700 : Colors.black87)),
      ),
    );
  }

  Widget _buildRightPane() {
    return Expanded(child: AnimatedSwitcher(duration: const Duration(milliseconds: 200), child: _activeFilterIndex == 0 ? _buildCategoryOptions() : _buildTimePeriodOptions()));
  }

  Widget _buildCategoryOptions() {
    return ListView(
      key: const ValueKey('categories'),
      padding: EdgeInsets.zero,
      children: _categories.keys.map((String key) {
        return SizedBox(
          height: 48,
          child: CheckboxListTile(
            title: Text(key, style: const TextStyle(fontSize: 14)),
            value: _categories[key],
            onChanged: (bool? value) {
              setState(() {
                _categories[key] = value ?? false;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: Colors.green,
            contentPadding: const EdgeInsets.only(left: 8),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimePeriodOptions() {
    return ListView(
      key: const ValueKey('time_periods'),
      padding: EdgeInsets.zero,
      children: _timePeriods.map((String value) {
        return SizedBox(
          height: 48,
          child: RadioListTile<String>(
            title: Text(value, style: const TextStyle(fontSize: 14)),
            value: value,
            groupValue: _selectedTimePeriod,
            onChanged: (String? newValue) {
              setState(() {
                _selectedTimePeriod = newValue;
              });
            },
            activeColor: Colors.green,
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: const EdgeInsets.only(left: 8),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons() {
    return Row(children: [
      Expanded(
        child: OutlinedButton(
          onPressed: _clearFilters,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: const Text('Clear All', style: TextStyle(color: Colors.black54)),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: ElevatedButton(
          onPressed: _applyAndClose,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Apply'),
        ),
      )
    ]);
  }
}


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

  int? _roleId;

  @override
  void initState() {
    super.initState();
    _loadBankList();
    _loadRoleId();
  }

  Future<void> _loadRoleId() async {
    try {
      final id = await SessionManager.getRoleId();
      if (!mounted) return;
      setState(() {
        _roleId = id;
      });
    } catch (e) {
      debugPrint("Failed to load role id: $e");
    }
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
      await _fetchBankSummary(_selectedBankAccount ?? '');
    } catch (e) {
      debugPrint("Error loading bank list: $e");
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loadingBanks = false;
      });
    }
  }

  Future<void> _fetchBankSummary(String accNumber) async {
    try {
      final userData = await SessionManager.getUserData();
      if (userData == null || userData.employerid == null) {
        throw Exception("User not available");
      }

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
                              await _fetchBankSummary(account);
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
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,      // Semi Bold
            fontSize: 16,                     // 16px
            height: 1.4,                      // 140%
            letterSpacing: 0,
            color: Color(0xFF1F212C),         // #1F212C
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

                          // Active Vouchers row -> now showing values from API
                          Row(
                            children: [
                              Expanded(
                                child: Text("Active Vouchers", style: TextStyle(color: Colors.white, fontSize: labelFont, fontWeight: FontWeight.w500)),
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(_activeCount, style: TextStyle(color: Colors.white, fontSize: titleFont * 0.9, fontWeight: FontWeight.w700)),
                                  Container(width: 1, height: screenHeight * 0.03, margin: EdgeInsets.symmetric(horizontal: horizontalPadding * 0.6), color: Colors.white.withOpacity(0.4)),
                                  Text("₹${_activeAmount.toStringAsFixed(_activeAmount.truncateToDouble() == _activeAmount ? 0 : 2)}", style: TextStyle(color: Colors.white, fontSize: titleFont * 0.9, fontWeight: FontWeight.w700)),
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
                                Expanded(
                                  child: Text(_formatLastUpdated(_lastUpdated), style: TextStyle(color: Colors.white70, fontSize: 11), overflow: TextOverflow.ellipsis),
                                ),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  onPressed: () async {
                                    // refresh both list and summary
                                    final userData = await SessionManager.getUserData();
                                    if (userData != null && userData.employerid != null) {
                                      await _loadBankList();
                                      await _fetchBankSummary(_selectedBankAccount ?? '');
                                    } else {
                                      await _loadBankList();
                                    }
                                  },
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
            if (_roleId == 8 || _roleId == 9) ...[
              Column(
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
                      padding: EdgeInsets.all(horizontalPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // header
                          Padding(
                            padding: EdgeInsets.only(
                              top: horizontalPadding * 0.6,
                              bottom: horizontalPadding * 0.4,
                            ),
                            child: Text(
                              "Office UPI Vouchers",
                              style: TextStyle(
                                fontSize: titleFont,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                          ),

                          // Issue Voucher
                          InkWell(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (c) => const IssueVoucherScreen(),
                              ),
                            ),
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                horizontal: horizontalPadding * 0.9,
                                vertical: horizontalPadding * 0.75,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(internalRadius),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  )
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(horizontalPadding * 0.25),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.white.withOpacity(0.06),
                                    ),
                                    child: Icon(
                                      Icons.confirmation_number,
                                      color: Colors.white,
                                      size: iconSize * 0.95,
                                    ),
                                  ),
                                  SizedBox(width: horizontalPadding * 0.8),
                                  Expanded(
                                    child: Text(
                                      "Issue Voucher",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: labelFont,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: horizontalPadding * 0.6,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF2C94C),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      "Admin",
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: smallFont * 0.95,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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
                              children: [
                                _listTile(
                                  icon: Icons.verified_outlined,
                                  title: "Approve Vouchers",
                                  iconSize: iconSize,
                                  textSize: labelFont,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (c) => const ApproveVouchersScreen(),
                                    ),
                                  ),
                                ),
                                Divider(height: 1, color: Colors.grey.shade200),
                                _listTile(
                                  icon: Icons.confirmation_number_outlined,
                                  title: _activeCount,
                                  iconSize: iconSize,
                                  textSize: labelFont,
                                  onTap: () {},
                                ),
                                Divider(height: 1, color: Colors.grey.shade200),
                                _listTile(
                                  icon: Icons.history,
                                  title: "Voucher History",
                                  iconSize: iconSize,
                                  textSize: labelFont,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (c) => const VouchersScreen(),
                                    ),
                                  ),
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
              )
            ] else
              const SizedBox.shrink(),

            // the rest of the UI (vouchers list) is below
            // (I'll include VouchersScreen content below)
            // For brevity and safety, I'm switching the next screen to the VouchersScreen you provided originally.
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

// ------------------------ VouchersScreen ------------------------

class VouchersScreen extends StatefulWidget {
  final ApiService? apiService;

  const VouchersScreen({super.key, this.apiService});

  @override
  State<VouchersScreen> createState() => _VouchersScreenState();
}

class _VouchersScreenState extends State<VouchersScreen> {
  late final ApiService _apiService;
  final TextEditingController _vouchersSearchController = TextEditingController();
  final TextEditingController _transactionsSearchController = TextEditingController(); // kept if you reuse later

  List<dynamic> _originalVouchers = [];
  List<dynamic> _filteredVouchers = [];
  bool _isVouchersLoading = true;
  String? _vouchersError;

  Map<String, bool> _voucherSelectedCategories = {'Fuel': false, 'Meal': false, 'Travel': false, 'Accommodation': false, 'Entertainment': false};
  String? _voucherSelectedTimePeriod = 'All History';

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? ApiService();
    _vouchersSearchController.addListener(_applyVoucherFilters);
    _loadVoucherData();
  }

  @override
  void dispose() {
    _vouchersSearchController.removeListener(_applyVoucherFilters);
    _vouchersSearchController.dispose();
    _transactionsSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadVoucherData() async {
    if (mounted) setState(() {
      _isVouchersLoading = true;
      _vouchersError = null;
    });

    try {
      final userData = await SessionManager.getUserData();
      final params = {"orgId": userData?.employerid ?? "", "timePeriod": "AH"};
      final response = await _apiService.getVoucherList(params);
      if (mounted) {
        if (response['status'] == true && response['data'] is List) {
          setState(() {
            _originalVouchers = response['data'];
            _isVouchersLoading = false;
          });
        } else {
          setState(() {
            _originalVouchers = [];
            _isVouchersLoading = false;
            _vouchersError = response['message'] ?? 'Failed to load vouchers';
          });
        }
        _applyVoucherFilters();
      }
    } catch (e) {
      if (mounted) setState(() {
        _isVouchersLoading = false;
        _vouchersError = e.toString();
      });
    }
  }

  void _applyVoucherFilters() {
    List<dynamic> result = _filterGenericList(
      _originalVouchers,
      _vouchersSearchController.text,
          (item) => [item['purposeDesc'], item['name']],
          (item) => item['expDate'],
      activeFilters: _voucherSelectedCategories,
      timePeriod: _voucherSelectedTimePeriod,
    );
    if (mounted) setState(() => _filteredVouchers = result);
  }

  List<dynamic> _filterGenericList(
      List<dynamic> originalList,
      String query,
      List<String?> Function(dynamic) searchFields,
      String? Function(dynamic) dateField, {
        required Map<String, bool> activeFilters,
        required String? timePeriod,
      }) {
    final q = query.toLowerCase();
    final activeCategories = activeFilters.entries.where((e) => e.value).map((e) => e.key.toLowerCase()).toList();
    var filtered = originalList.where((item) {
      final searchCorpus = searchFields(item).where((s) => s != null).map((s) => s!.toLowerCase()).join(' ');
      final categorySource = searchFields(item).first?.toLowerCase() ?? '';
      final matchesQuery = q.isEmpty || searchCorpus.contains(q);
      final matchesCategory = activeCategories.isEmpty || activeCategories.any((cat) => categorySource.contains(cat));
      return matchesQuery && matchesCategory;
    }).toList();

    if (timePeriod != null && timePeriod != 'All History') {
      filtered = filtered.where((item) {
        final dateStr = dateField(item);
        final itemDate = _parseDate(dateStr);
        if (itemDate == null) return false;
        final now = DateTime.now();
        switch (timePeriod) {
          case 'Current Month':
            return itemDate.year == now.year && itemDate.month == now.month;
          case 'Last Month':
            final last = DateTime(now.year, now.month - 1);
            return itemDate.year == last.year && itemDate.month == last.month;
          case 'Current Financial Year':
            int year = (now.month < 4) ? now.year - 1 : now.year;
            return itemDate.isAfter(DateTime(year, 3, 31)) && itemDate.isBefore(DateTime(year + 1, 4, 1));
          case 'Last Financial Year':
            int year = (now.month < 4) ? now.year - 2 : now.year - 1;
            return itemDate.isAfter(DateTime(year, 3, 31)) && itemDate.isBefore(DateTime(year + 1, 4, 1));
          default:
            return true;
        }
      }).toList();
    }

    return filtered;
  }

  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return null;
    final formats = [DateFormat("yyyy-MM-dd HH:mm:ss"), DateFormat("d MMM yyyy"), DateFormat("yyyy-MM-dd"), DateFormat("dd-MM-yyyy"), DateFormat("MM/dd/yyyy")];
    for (var format in formats) {
      try {
        return format.parse(dateStr);
      } catch (_) {}
    }
    debugPrint('Date parsing failed for ALL formats: $dateStr');
    return null;
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        initialCategories: _voucherSelectedCategories,
        initialTimePeriod: _voucherSelectedTimePeriod,
        onApplyFilter: (newCategories, newTimePeriod) {
          setState(() {
            _voucherSelectedCategories = newCategories;
            _voucherSelectedTimePeriod = newTimePeriod;
          });
          _applyVoucherFilters();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black), onPressed: () => Navigator.pop(context)),
        // Add these two lines to left-align the title
        centerTitle: false,
        titleSpacing: 0,
        title: const Text('Vouchers', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [IconButton(icon: const Icon(Icons.download_outlined, color: Colors.black), onPressed: () {})],
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(children: [
          Row(children: [
            Expanded(
              child: TextField(
                controller: _vouchersSearchController,
                decoration: InputDecoration(
                  hintText: 'Search Vouchers',
                  prefixIcon: const Icon(Icons.search, color: Colors.green),
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
              child: IconButton(onPressed: _showFilterSheet, icon: const Icon(Icons.tune, color: Colors.black54)),
            )
          ]),
          const SizedBox(height: 16),
          if (_isVouchersLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_vouchersError != null)
            Expanded(child: Center(child: Text('Error: $_vouchersError')))
          else
            Expanded(
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('${_filteredVouchers.length} AVAILABLE', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                  IconButton(icon: const Icon(Icons.refresh, color: Colors.grey), onPressed: _loadVoucherData),
                ]),
                const SizedBox(height: 8),
                if (_filteredVouchers.isEmpty)
                  Expanded(
                    child: _originalVouchers.isEmpty
                        ? _buildEmptyState(message: "No Voucher issued yet!", showButton: true)
                        : _buildEmptyState(message: "No vouchers match your filters."),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: _filteredVouchers.length,
                      itemBuilder: (context, index) => _buildVoucherCard(voucherData: _filteredVouchers[index]),
                    ),
                  ),
              ]),
            )
        ]),
      ),
    );
  }

  Widget _buildEmptyState({required String message, bool showButton = false}) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            // Using a fallback icon in case the asset is not found
            Image.asset('assets/no_vouchers.webp', width: 200, height: 200, errorBuilder: (context, error, stackTrace) => Icon(Icons.inbox_outlined, size: 100, color: Colors.grey.shade400)),
            const SizedBox(height: 24),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87)),
            if (showButton) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(200, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Issue Vouchers', style: TextStyle(fontSize: 16)),
              )
            ]
          ]),
        ),
      ),
    );
  }

  // UPDATED WIDGET: Replaced _buildVoucherCard with the responsive version.

  Widget _buildVoucherCard({required Map<String, dynamic> voucherData}) {
    String title = (voucherData['purposeDesc'] ?? '').toString().replaceAll('Vouhcer', 'Voucher');
    if (title.trim().isEmpty) title = 'N/A';
    String subtitle = (voucherData['name'] ?? 'Self').toString();

    // handle different possible API keys and normalise
    String redemptionRaw = (voucherData['redemtionType'] ?? voucherData['redemptionType'] ?? '').toString();
    String redemptionType = redemptionRaw.trim().isEmpty ? 'Unknown' : redemptionRaw.trim().toLowerCase().capitalize();

    double amount = 0.0;
    final amtRaw = voucherData['amount'];
    if (amtRaw is num) amount = amtRaw.toDouble();
    else if (amtRaw is String) amount = double.tryParse(amtRaw) ?? 0.0;

    String validity = _getValidityString(voucherData['expDate']?.toString());

    // Important: read voucherStatus, but fall back to 'type' if API uses that
    String statusRaw = voucherData['type'];
    final status = statusRaw.toLowerCase();

    final bool isRejected = status == 'failed';
    final bool isActive = status == 'active';
    final bool isExpired = status == 'expired';

    // card border color based on status
    Color cardBorderColor = Color(0xffF1F1F1);
    if (isRejected) cardBorderColor = Color(0xffF1F1F1);
    else if (isActive) cardBorderColor = Color(0xffF1F1F1);
    else if (isExpired) cardBorderColor = Color(0xffF1F1F1);


    return Card(
        color: Colors.white,
      elevation: 0.4,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: cardBorderColor.withOpacity(0.45), width: 1.2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: isActive ? () => Navigator.push(context, MaterialPageRoute(builder: (context) => VoucherDetailScreen(voucherData: voucherData))) : null,
        child: Container(
          padding: const EdgeInsets.all(16),
          height: 125,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.black.withOpacity(0.05),
                    child: Icon(_getIconForPurpose(title), color: Colors.black87, size: 24),

                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                      Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,   // Semi Bold
                        fontSize: 14,                  // 14px
                        height: 1.4,                   // 140%
                        letterSpacing: 0,
                        color: Color(0xFF000000),      // #000000
                      ),
                    ),

                      const SizedBox(height: 4),
                    Text(
                      subtitle,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,   // Regular
                        fontSize: 12,                  // 12px
                        height: 1.4,                   // 140%
                        letterSpacing: 0,
                        color: Color(0xFF6B6B6B),      // #6B6B6B
                      ),
                    ),
                    ],
                    ),
                  ),

                  // status badge / arrow
                  if (isRejected)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.pink.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('Failed', style: TextStyle(color: Colors.pink.shade700, fontSize: 12, fontWeight: FontWeight.w600)),
                    )
                  else if (isExpired)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('Expired', style: TextStyle(color: Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.w600)),
                    )
                  else if (isActive)
                      Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400)
                ],
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          (redemptionType.toLowerCase() == 'multiple')
                              ? SvgPicture.asset(
                            'assets/multiple.svg',
                            width: 20,
                            height: 20,
                            color: Color(0xff2F945A),
                          )
                              : SvgPicture.asset(
                            'assets/single.svg',
                            width: 20,
                            height: 20,
                            color: Color(0xff2F945A),
                          ),
                          const SizedBox(width: 6),
        Text(
          redemptionType,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,     // Regular
            fontSize: 12,                    // 12px
            height: 1.4,                     // 140%
            letterSpacing: 0,
            color: Color(0xFF1F002A),        // #1F002A
          ),
        ),

        ],
                      ),
                      if (!isRejected) ...[
                        const SizedBox(height: 4),
    Text(
    validity,
    style: const TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w400,       // Regular
    fontSize: 12,                      // 12px
    height: 1.4,                       // 140%
    letterSpacing: 0,
    color: Color(0xFFFF545A),          // #FF545A
    ),
    ),
    ],
                    ],
                  ),

          Text(
            NumberFormat.currency(
              locale: 'en_IN',
              symbol: '₹',
              decimalDigits: 0,
            ).format(amount),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,   // Semi Bold
              fontSize: 16,                  // 16px
              height: 1.4,                   // 140%
              letterSpacing: 0,
              color: Color(0xFF000000),      // #000000
            ),
          ),

          ],
              )
            ],
          ),
        ),
      ),
    );

  }









  // UPDATED HELPER: Changed icon for 'meal' to better match the design.
  IconData _getIconForPurpose(String purpose) {
    String p = purpose.toLowerCase();
    if (p.contains('fuel') || p.contains('petroleum')) return Icons.local_gas_station_outlined;
    if (p.contains('meal') || p.contains('food')) return Icons.coffee_outlined;
    if (p.contains('motorcycle')) return Icons.two_wheeler_outlined;
    if (p.contains('groceries')) return Icons.shopping_cart_outlined;
    return Icons.card_giftcard_outlined;
  }

  String _getValidityString(String? expDateStr) {
    if (expDateStr == null || expDateStr.trim().isEmpty) return 'No expiry';
    try {
      final expiryDate = DateTime.parse(expDateStr);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
      final difference = expiry.difference(today).inDays;
      if (difference < 0) return 'Expired';
      if (difference == 0) return 'Expires today';
      if (difference <= 30) return 'Valid for $difference days';
      return 'Expires on ${DateFormat('d MMM yyyy').format(expiry)}';
    } catch (e) {
      debugPrint("Could not parse expiry date: $expDateStr");
      return 'Expires: $expDateStr';
    }
  }
}

extension NullableStringHelpers on String? {
  String capitalize() {
    if (this == null || this!.trim().isEmpty) return this ?? '';
    final String trimmed = this!.trim();
    return trimmed[0].toUpperCase() + trimmed.substring(1).toLowerCase();
  }
}
