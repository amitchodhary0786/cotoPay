
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'api_service.dart';
import 'session_manager.dart';
import 'account_settings_screen.dart';
import 'transaction_detail_screen.dart';
import 'voucher_detail_screen.dart';
import 'dart:convert';

class _FilterBottomSheet extends StatefulWidget {
  final Function(Map<String, bool> selectedCategories, String? selectedTimePeriod) onApplyFilter;
  final Map<String, bool> initialCategories;
  final String? initialTimePeriod;

  const _FilterBottomSheet({
    super.key,
    required this.onApplyFilter,
    required this.initialCategories,
    this.initialTimePeriod,
  });

  @override
  State<_FilterBottomSheet> createState() => __FilterBottomSheetState();
}

class __FilterBottomSheetState extends State<_FilterBottomSheet> {
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
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('FILTER BY', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, letterSpacing: 0.8))),
              const Divider(height: 24),
              SizedBox(height: 280, child: Row(children: [_buildLeftPane(), const VerticalDivider(width: 1, thickness: 1), _buildRightPane()])),
              const Divider(height: 1),
              Padding(
                  padding: const EdgeInsets.all(16.0), child: _buildActionButtons())
            ]));
  }

  Widget _buildLeftPane() {
    return SizedBox(
      width: 150,
      child: Column(children: [
        _buildFilterSelector('Category Type', 0),
        _buildFilterSelector('Select Time Period', 1),
      ],),
    );
  }

  Widget _buildFilterSelector(String title, int index) {
    final bool isActive = _activeFilterIndex == index;
    return InkWell(
        onTap: () { setState(() { _activeFilterIndex = index; }); },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          color: isActive ? Colors.blue.withOpacity(0.05) : Colors.transparent,
          child: Text(title, style: TextStyle(fontWeight: isActive ? FontWeight.bold : FontWeight.normal, color: isActive ? Colors.blue.shade700 : Colors.black87)),
        ));
  }

  Widget _buildRightPane() {
    return Expanded(child: AnimatedSwitcher(duration: const Duration(milliseconds: 200), child: _activeFilterIndex == 0 ? _buildCategoryOptions() : _buildTimePeriodOptions()));
  }

  Widget _buildCategoryOptions() {
    return ListView(key: const ValueKey('categories'), padding: EdgeInsets.zero, children: _categories.keys.map((String key) {
      return SizedBox(height: 48, child: CheckboxListTile(title: Text(key, style: const TextStyle(fontSize: 14)), value: _categories[key], onChanged: (bool? value) { setState(() { _categories[key] = value!; }); }, controlAffinity: ListTileControlAffinity.leading, activeColor: Colors.green, contentPadding: const EdgeInsets.only(left: 8)));
    }).toList());
  }

  Widget _buildTimePeriodOptions() {
    return ListView(key: const ValueKey('time_periods'), padding: EdgeInsets.zero, children: _timePeriods.map((String value) {
      return SizedBox(height: 48, child: RadioListTile<String>(title: Text(value, style: const TextStyle(fontSize: 14)), value: value, groupValue: _selectedTimePeriod, onChanged: (String? newValue) { setState(() { _selectedTimePeriod = newValue; }); }, activeColor: Colors.green, controlAffinity: ListTileControlAffinity.leading, contentPadding: const EdgeInsets.only(left: 8)));
    }).toList());
  }

  Widget _buildActionButtons() {
    return Row(children: [Expanded(child: OutlinedButton(onPressed: _clearFilters, style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), side: BorderSide(color: Colors.grey.shade300)), child: const Text('Clear All', style: TextStyle(color: Colors.black54)))), const SizedBox(width: 12), Expanded(child: ElevatedButton(onPressed: _applyAndClose, style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Apply')))]);
  }
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();

  final TextEditingController _vouchersSearchController = TextEditingController();
  List<dynamic> _originalVouchers = [];
  List<dynamic> _filteredVouchers = [];
  bool _isVouchersLoading = true;
  String? _vouchersError;

  final TextEditingController _transactionsSearchController = TextEditingController();
  List<dynamic> _originalTransactions = [];
  List<dynamic> _filteredTransactions = [];
  bool _isTransactionsLoading = true;
  String? _transactionsError;
  bool _hasLoadedTransactions = false;

  Map<String, bool> _voucherSelectedCategories = {'Fuel': false, 'Meal': false, 'Travel': false, 'Accommodation': false, 'Entertainment': false};
  String? _voucherSelectedTimePeriod = 'All History';
  Map<String, bool> _transactionSelectedCategories = {'Fuel': false, 'Meal': false, 'Travel': false, 'Accommodation': false, 'Entertainment': false};
  String? _transactionSelectedTimePeriod = 'All History';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _vouchersSearchController.addListener(_applyVoucherFilters);
    _transactionsSearchController.addListener(_applyTransactionFilters);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) setState(() {});
      if (_tabController.index == 1 && !_hasLoadedTransactions) _loadTransactionData();
    });
    _loadVoucherData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _vouchersSearchController.dispose();
    _transactionsSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadVoucherData() async {
    if (mounted) setState(() { _isVouchersLoading = true; _vouchersError = null; });
    try {
      final userData = await SessionManager.getUserData();
      //Amit Comment
     // final params = {"orgId": userData?.employerid ?? "", "timePeriod": "Yes" ,   "mobile": userData?.mobile};
      final params = {"orgId": userData?.employerid ?? "", "timePeriod": "AH" ,   "mobile": userData?.mobile};
      final response = await _apiService.getVoucherList(params);
      if (mounted) {
        if (response['status'] == true && response['data'] is List) {
          setState(() { _originalVouchers = response['data']; _isVouchersLoading = false; });
        } else {
          setState(() { _originalVouchers = []; _isVouchersLoading = false; _vouchersError = response['message'] ?? 'Failed to load vouchers'; });
        }
        _applyVoucherFilters();
      }
    } catch (e) {
      if (mounted) setState(() { _isVouchersLoading = false; _vouchersError = e.toString(); });
    }
  }

  Future<void> _loadTransactionData() async {
    if (mounted) setState(() { _isTransactionsLoading = true; _transactionsError = null; });
    try {
      final userData = await SessionManager.getUserData();
      //Amit Comment
     // final params = {"orgId": userData?.employerid, "timePeriod": "Yes", "mobile": userData?.mobile};
      final params = {"orgId": userData?.employerid ?? "", "timePeriod": "AH" ,   "mobile": userData?.mobile};
      final response = await _apiService.getVoucherListRedeem(params);
      if (mounted) {
        if (response['status'] == true && response['data'] is List) {
          setState(() { _originalTransactions = response['data']; _isTransactionsLoading = false; _hasLoadedTransactions = true; });
        } else {
          setState(() { _originalTransactions = []; _isTransactionsLoading = false; _transactionsError = response['message'] ?? 'Failed to load transactions'; });
        }
        _applyTransactionFilters();
      }
    } catch (e) {
      if (mounted) setState(() { _isTransactionsLoading = false; _transactionsError = e.toString(); });
    }
  }

  void _applyVoucherFilters() {
    List<dynamic> result = _filterGenericList(_originalVouchers, _vouchersSearchController.text, (item) => [item['purposeDesc'], item['name']], (item) => item['expDate'], activeFilters: _voucherSelectedCategories, timePeriod: _voucherSelectedTimePeriod);
    if (mounted) setState(() => _filteredVouchers = result);
  }

  void _applyTransactionFilters() {
    List<dynamic> result = _filterGenericList(_originalTransactions, _transactionsSearchController.text, (item) => [item['purposeDesc'], item['bankcode']], (item) => item['creationDate'], activeFilters: _transactionSelectedCategories, timePeriod: _transactionSelectedTimePeriod);
    if (mounted) setState(() => _filteredTransactions = result);
  }

  List<dynamic> _filterGenericList(List<dynamic> originalList, String query, List<String?> Function(dynamic) searchFields, String? Function(dynamic) dateField, {required Map<String, bool> activeFilters, required String? timePeriod}) {
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
          case 'Current Month': return itemDate.year == now.year && itemDate.month == now.month;
          case 'Last Month': final last = DateTime(now.year, now.month - 1); return itemDate.year == last.year && itemDate.month == last.month;
          case 'Current Financial Year': int year = (now.month < 4) ? now.year - 1 : now.year; return itemDate.isAfter(DateTime(year, 3, 31)) && itemDate.isBefore(DateTime(year + 1, 4, 1));
          case 'Last Financial Year': int year = (now.month < 4) ? now.year - 2 : now.year - 1; return itemDate.isAfter(DateTime(year, 3, 31)) && itemDate.isBefore(DateTime(year + 1, 4, 1));
          default: return true;
        }
      }).toList();
    }
    return filtered;
  }

  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return null;
    final formats = [DateFormat("yyyy-MM-dd HH:mm:ss"), DateFormat("d MMM yyyy"), DateFormat("yyyy-MM-dd"), DateFormat("dd-MM-yyyy"), DateFormat("MM/dd/yyyy")];
    for (var format in formats) { try { return format.parse(dateStr); } catch (_) {} }
    debugPrint('Date parsing failed for ALL formats: $dateStr');
    return null;
  }

  void _showFilterSheet() {
    final isVoucherTab = _tabController.index == 0;
    final initialCategories = isVoucherTab ? _voucherSelectedCategories : _transactionSelectedCategories;
    final initialTimePeriod = isVoucherTab ? _voucherSelectedTimePeriod : _transactionSelectedTimePeriod;
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => _FilterBottomSheet(initialCategories: initialCategories, initialTimePeriod: initialTimePeriod, onApplyFilter: (newCategories, newTimePeriod) { if (isVoucherTab) { setState(() { _voucherSelectedCategories = newCategories; _voucherSelectedTimePeriod = newTimePeriod; }); _applyVoucherFilters(); } else { setState(() { _transactionSelectedCategories = newCategories; _transactionSelectedTimePeriod = newTimePeriod; }); _applyTransactionFilters(); } }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.sort, color: Colors.black), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AccountSettingsScreen()))),
        title: const Text('History', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [IconButton(icon: const Icon(Icons.download_outlined, color: Colors.black), onPressed: () {})],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(children: [
          TabBar(controller: _tabController, labelColor: Colors.green, unselectedLabelColor: Colors.grey.shade600, indicatorColor: Colors.green, labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), tabs: const [Tab(text: 'Vouchers'), Tab(text: 'Transactions')]),
          const SizedBox(height: 16),
          Expanded(child: TabBarView(controller: _tabController, children: [_buildVouchersTab(), _buildTransactionsTab()])),
        ]),
      ),
    );
  }

  Widget _buildEmptyState({required String message, bool showButton = false}) {
    return Center(child: SingleChildScrollView(child: Padding(padding: const EdgeInsets.all(20.0), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Image.asset('assets/no_vouchers.webp', width: 200, height: 200, errorBuilder: (context, error, stackTrace) => Icon(Icons.inbox_outlined, size: 100, color: Colors.grey.shade400)), const SizedBox(height: 24), Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87)), if (showButton) ...[const SizedBox(height: 24), ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade600, foregroundColor: Colors.white, minimumSize: const Size(200, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Issue Vouchers', style: TextStyle(fontSize: 16)))]]))));
  }

  Widget _buildVouchersTab() {
    return Column(children: [
      Row(children: [
        Expanded(child: TextField(controller: _vouchersSearchController, decoration: InputDecoration(hintText: 'Search Vouchers', prefixIcon: const Icon(Icons.search, color: Colors.green), contentPadding: EdgeInsets.zero, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300))))),
        const SizedBox(width: 8),
        Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)), child: IconButton(onPressed: _showFilterSheet, icon: const Icon(Icons.tune, color: Colors.black54)))
      ]),
      const SizedBox(height: 16),
      if (_isVouchersLoading) const Expanded(child: Center(child: CircularProgressIndicator()))
      else if (_vouchersError != null) Expanded(child: Center(child: Text('Error: $_vouchersError')))
      else Expanded(
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('${_filteredVouchers.length} AVAILABLE', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
              IconButton(icon: const Icon(Icons.refresh, color: Colors.grey), onPressed: _loadVoucherData),
            ]),
            const SizedBox(height: 8),
            if (_filteredVouchers.isEmpty)
              Expanded(child: _originalVouchers.isEmpty ? _buildEmptyState(message: "No Voucher issued yet!", showButton: true) : _buildEmptyState(message: "No vouchers match your filters."))
            else
              Expanded(child: ListView.builder(padding: EdgeInsets.zero, itemCount: _filteredVouchers.length, itemBuilder: (context, index) => _buildVoucherCard(voucherData: _filteredVouchers[index]))),
          ]),
        )
    ]);
  }

  Widget _buildTransactionsTab() {
    final Map<String, List<dynamic>> groupedTransactions = {};
    for (var tx in _filteredTransactions) {
      final date = _parseDate(tx['creationDate']);
      if (date != null) {
        final monthKey = DateFormat('MMMM yyyy').format(date);
        if (groupedTransactions[monthKey] == null) {
          groupedTransactions[monthKey] = [];
        }
        groupedTransactions[monthKey]!.add(tx);
      }
    }
    final sortedKeys = groupedTransactions.keys.toList()..sort((a,b) => DateFormat('MMMM yyyy').parse(b).compareTo(DateFormat('MMMM yyyy').parse(a)));
    return Column( children: [
      Row(children: [Expanded(child: TextField( controller: _transactionsSearchController, decoration: InputDecoration( hintText: 'Search your transactions', prefixIcon: const Icon(Icons.search), contentPadding: EdgeInsets.zero, border: OutlineInputBorder( borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300) ), enabledBorder: OutlineInputBorder( borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300) ) ) ), ), const SizedBox(width: 8), Container( decoration: BoxDecoration( borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300), ), child: IconButton( onPressed: _showFilterSheet, icon: const Icon(Icons.tune, color: Colors.black54), ), ), ]),
      const SizedBox(height: 16),
      if (_isTransactionsLoading) const Expanded(child: Center(child: CircularProgressIndicator()))
    //  else if (_transactionsError != null) Expanded(child: Center(child: Text('Error: $_transactionsError')))
      else if (groupedTransactions.isEmpty) Expanded(child: _originalTransactions.isEmpty ? _buildEmptyState(message: 'You have no transactions yet.') : _buildEmptyState(message: 'No transactions match your filters.'))
        else Expanded(child: ListView.builder(itemCount: sortedKeys.length, itemBuilder: (context, index) { final monthKey = sortedKeys[index]; final transactionsInMonth = groupedTransactions[monthKey]!; final double totalAmount = transactionsInMonth.fold(0.0, (sum, item) => sum + (item['amount'] as num? ?? 0.0)); return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), margin: const EdgeInsets.only(top: 8, bottom: 8), decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(12)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(monthKey.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.8)), Text('₹${NumberFormat.decimalPattern('en_IN').format(totalAmount)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))])), ListView.separated(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: transactionsInMonth.length, separatorBuilder: (context, index) => Divider(height: 1, indent: 70, color: Colors.grey.shade200), itemBuilder: (context, itemIndex) => _transactionTile(transactionData: transactionsInMonth[itemIndex]))]); }))]);
  }

  Widget _buildVoucherCard({required Map<String, dynamic> voucherData}) {
    String title = voucherData['purposeDesc'] ?? 'N/A';
    String subtitle = voucherData['name'] ?? 'Self';
    String redemptionType = (voucherData['redemtionType'] as String?)?.capitalize() ?? 'N/A';
    double amount = (voucherData['amount'] as num?)?.toDouble() ?? 0.0;
    String validity = _getValidityString(voucherData['expDate']);

    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => VoucherDetailScreen(voucherData: voucherData))),
      child: Container(
        height: 125,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200, width: 1),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [

                 // child: Icon(_getIconForPurpose(title), color: Colors.black87, size: 26),
                   Image.memory(base64ToBytes(voucherData['mccMainIcon']),
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,),

                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 14), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
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
                        Text(redemptionType, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(validity, style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                Text(NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(amount), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
              ],
            )
          ],
        ),
      ),
    );
  }

  IconData _getIconForPurpose(String purpose) {
    String p = purpose.toLowerCase();
    if (p.contains('fuel')) return Icons.local_gas_station_outlined;
    if (p.contains('meal') || p.contains('food')) return Icons.restaurant_menu_outlined;
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

  Widget _transactionTile({required Map<String, dynamic> transactionData}) {
    final DateTime? date = _parseDate(transactionData['creationDate']);
    final String displayDate = date != null ? DateFormat('d MMM').format(date) : '';
    final amount = (transactionData['amount'] as num?)?.toDouble() ?? 0.0;
    final displayAmount = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(amount);
    final bool isBillAttached = transactionData['billAttached'] == true;
    final Widget iconWidget = (transactionData['bankIcon'] != null && transactionData['bankIcon'].isNotEmpty) ? _buildBase64Icon(transactionData['bankIcon']) : CircleAvatar(backgroundColor: Colors.green.shade50, radius: 24, child: Icon(Icons.receipt_long, color: Colors.green.shade800));

    return InkWell(
      onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context) => TransactionDetailScreen(transactionData: transactionData))); },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            iconWidget,
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(transactionData['purposeDesc'] ?? 'N/A', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                const SizedBox(height: 4),
                Text(transactionData['bankcode'] ?? 'Unknown', style: TextStyle(color: Colors.green.shade600, fontWeight: FontWeight.w500, fontSize: 13)),
                const SizedBox(height: 4),
                Row(children: [
                  Text(displayDate, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(width: 8),
                  if (isBillAttached) Chip(label: const Text('Bill Attached'), avatar: Icon(Icons.link, size: 14, color: Colors.grey.shade700), padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0), backgroundColor: Colors.grey.shade200, labelStyle: TextStyle(fontSize: 10, color: Colors.grey.shade700), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, visualDensity: const VisualDensity(horizontal: 0, vertical: -4)),
                ]),
              ]),
            ),
            const SizedBox(width: 12),
            Text(displayAmount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87))
          ],
        ),
      ),
    );
  }

  Widget _buildBase64Icon(String base64String) {
    try {
      final imageBytes = base64.decode(base64String);
      return CircleAvatar(backgroundColor: Colors.white, radius: 24, child: ClipOval(child: Image.memory(imageBytes, width: 32, height: 32, fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) => const Icon(Icons.business, color: Colors.grey))));
    } catch (e) {
      debugPrint("Failed to decode base64 icon: $e");
      return CircleAvatar(backgroundColor: Colors.grey.shade100, radius: 24, child: Icon(Icons.business, color: Colors.grey.shade700));
    }
  }

  Uint8List base64ToBytes(String base64String) {
    // Remove data URI if present
    final cleaned = base64String.contains(',')
        ? base64String.split(',').last
        : base64String;

    return base64Decode(cleaned);
  }
}