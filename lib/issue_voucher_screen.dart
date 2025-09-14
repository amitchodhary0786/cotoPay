import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';

import 'package:cotopay/voucher_verify_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Your existing project services (these must exist in your project)
import 'api_service.dart';
import 'package:cotopay/session_manager.dart';
import 'package:flutter/services.dart';

class IssueVoucherScreen extends StatefulWidget {
  const IssueVoucherScreen({super.key});

  @override
  State<IssueVoucherScreen> createState() => _IssueVoucherScreenState();
}

class _IssueVoucherScreenState extends State<IssueVoucherScreen> {
  final ApiService _apiService = ApiService();

  // form font size requested (13px)
  static const double _formFontSize = 13.0;

  // Banks loaded from API
  List<dynamic> _banks = [];
  bool _loadingBanks = true;
  String _selectedBankName = 'Select account';
  String _selectedBankMasked = 'xxxx1234';
  String _selectedBankId = '';
  double _availableBalance = 0.0;
  bool _loadingBalance = true;

  // Dynamic voucher entries
  final List<_VoucherEntry> _entries = [];

  // Scroll controller to scroll to newly added card
  final ScrollController _scrollController = ScrollController();

  // --- Voucher categories (dynamic)
  List<Map<String, dynamic>> _voucherCategories = [];
  bool _loadingCategories = true;
  int? _expandedTopIndex;

  // search debounce timers per entry id
  final Map<int, Timer?> _searchTimers = {};

  @override
  void initState() {
    super.initState();
    _loadBanks();
    _loadVoucherCategories();
    // Add initial entry BUT do not auto-focus/scroll when screen opens
    _addNewEntry(focus: false);
  }

  @override
  void dispose() {
    for (final e in _entries) e.dispose();
    // cancel timers
    for (final t in _searchTimers.values) {
      t?.cancel();
    }
    _scroll_controller_dispose_safe();
    super.dispose();
  }

  void _scroll_controller_dispose_safe() {
    try {
      _scrollController.dispose();
    } catch (_) {}
  }

  // ---------------- API loading ----------------
  Future<void> _loadBanks() async {
    setState(() {
      _loadingBanks = true;
      _loadingBalance = true; // will be cleared when we fetch for selected bank
    });

    debugPrint('[IssueVoucher] _loadBanks: start');

    try {
      final user = await SessionManager.getUserData();
      debugPrint('[IssueVoucher] _loadBanks: user => $user');
      if (user == null || user.employerid == null) throw Exception('User not available');

      final bankParams = {'orgId': user.employerid};
      debugPrint('[IssueVoucher] _loadBanks: calling getBankList with params: $bankParams');
      final bankResp = await _api_serviceSafeGet(() => _apiService.getBankList(bankParams));
      debugPrint('[IssueVoucher] _loadBanks: getBankList response: $bankResp');

      if (bankResp != null && bankResp['status'] == true && bankResp['data'] is List) {
        _banks = List<dynamic>.from(bankResp['data']);
        debugPrint('[IssueVoucher] _loadBanks: loaded ${_banks.length} banks');
        if (_banks.isNotEmpty) {
          // select first bank and fetch its balance
          _selectBankAtIndex(0);
        } else {
          // no banks - stop loading balance
          setState(() => _loadingBalance = false);
        }
      } else {
        _banks = [];
        setState(() => _loadingBalance = false);
      }
    } catch (e, st) {
      debugPrint('[IssueVoucher] _loadBanks: Error loading banks: $e\n$st');
      setState(() {
        _banks = [];
        _loadingBalance = false;
      });
    } finally {
      setState(() => _loadingBanks = false);
      debugPrint('[IssueVoucher] _loadBanks: finished (loadingBanks=$_loadingBanks, loadingBalance=$_loadingBalance)');
    }
  }

  // safe wrapper for API calls
  Future<Map<String, dynamic>?> _api_serviceSafeGet(Future<Map<String, dynamic>?> Function() fn) async {
    try {
      debugPrint('[IssueVoucher] _api_serviceSafeGet: calling API...');
      final resp = await fn();
      debugPrint('[IssueVoucher] _api_serviceSafeGet: response => $resp');
      return resp;
    } catch (e, st) {
      debugPrint('[IssueVoucher] _api_serviceSafeGet: API error => $e\n$st');
      return null;
    }
  }

  // ---------------- voucher categories ----------------

  Future<void> _loadVoucherCategories() async {
    setState(() {
      _loadingCategories = true;
      _voucherCategories = [];
    });

    debugPrint('[IssueVoucher] _loadVoucherCategories: fetching top categories');
    try {
      final resp = await _api_serviceSafeGet(() => _apiService.getVoucherCategoryList());
      debugPrint('[IssueVoucher] _loadVoucherCategories: raw resp => $resp');

      if (resp != null && (resp['status'] == true || resp['success'] == true)) {
        final data = resp['data'];
        List items = [];
        if (data is List) items = data;
        else if (data is Map && data['data'] is List) items = data['data'];

        debugPrint('[IssueVoucher] _loadVoucherCategories: parsed ${items.length} categories');

        _voucherCategories = items.map<Map<String, dynamic>>((raw) {
          final topId = raw['id'];
          final voucherName = raw['voucherName'] ?? raw['name'] ?? 'Category';
          final purposeCode = raw['purposeCode'] ?? raw['code'] ?? raw['id'];
          final icon = raw['voucherIcon'] ?? raw['icon'];

          return {
            'topId': topId,
            'purposeCode': purposeCode,
            'title': voucherName.toString(),
            'icon': icon,
            'children': <Map<String, dynamic>>[],
            'loadingChildren': false,
            'raw': raw,
          };
        }).toList();
      } else {
        debugPrint('[IssueVoucher] _loadVoucherCategories: got failure or empty resp');
      }
    } catch (e, st) {
      debugPrint('[IssueVoucher] _loadVoucherCategories: error => $e\n$st');
    } finally {
      setState(() {
        _loadingCategories = false;
      });
      debugPrint('[IssueVoucher] _loadVoucherCategories: finished (count=${_voucherCategories.length})');
    }
  }

  Future<void> _loadSubCategoriesForIndex(int topIndex) async {
    if (topIndex < 0 || topIndex >= _voucherCategories.length) return;
    final top = _voucherCategories[topIndex];
    final purposeCode = top['purposeCode'];
    final topId = top['topId'];
    if (purposeCode == null && topId == null) {
      debugPrint('[IssueVoucher] _loadSubCategoriesForIndex: both purposeCode and topId null for index=$topIndex');
      return;
    }

    if ((top['children'] as List).isNotEmpty) {
      debugPrint('[IssueVoucher] _loadSubCategoriesForIndex: children already loaded for purposeCode=$purposeCode / topId=$topId');
      return;
    }

    setState(() {
      _voucherCategories[topIndex]['loadingChildren'] = true;
    });

    debugPrint('[IssueVoucher] _loadSubCategoriesForIndex: fetching subcategories for purposeCode=$purposeCode topId=$topId (index=$topIndex)');

    try {
      final params = <String, dynamic>{};
      if (purposeCode != null) params['purposeCode'] = purposeCode;
      else params['id'] = topId;

      final resp = await _api_serviceSafeGet(() => _apiService.getVoucherSubCategoryList(params));
      debugPrint('[IssueVoucher] _loadSubCategoriesForIndex: raw resp => $resp');

      if (resp != null && (resp['status'] == true || resp['success'] == true)) {
        final data = resp['data'] ?? resp['subCategories'] ?? resp['result'] ?? resp;
        List items = [];
        if (data is List) items = data;
        else if (data is Map && data['data'] is List) items = data['data'];
        debugPrint('[IssueVoucher] _loadSubCategoriesForIndex: parsed ${items.length} children');

        final children = items.map<Map<String, dynamic>>((raw) {
          final cid = raw['id'] ?? raw['subId'] ?? raw['code'] ?? raw['purposeCode'] ?? raw['value'];
          final title = raw['title'] ?? raw['name'] ?? raw['label'] ?? raw['subName'] ?? raw['purposeName'] ?? raw['description'] ?? raw['voucherName'] ?? 'Sub';
          return {
            'id': cid,
            'title': title.toString(),
            'raw': raw,
          };
        }).toList();

        setState(() {
          _voucherCategories[topIndex]['children'] = children;
        });
      } else {
        debugPrint('[IssueVoucher] _loadSubCategoriesForIndex: response indicates failure or no children');
      }
    } catch (e, st) {
      debugPrint('[IssueVoucher] _loadSubCategoriesForIndex: error => $e\n$st');
    } finally {
      setState(() {
        _voucherCategories[topIndex]['loadingChildren'] = false;
      });
    }
  }

  // ---------------- employee search integration (use getVoucherNameSearchMobile) ----------------

  void _scheduleEmployeeSearch(_VoucherEntry entry, String q) {
    // cancel existing timer for this entry
    _searchTimers[entry._id]?.cancel();

    // if less than 3 chars, don't search; also hide suggestions
    if (q.trim().length < 3) {
      debugPrint('[IssueVoucher] _scheduleEmployeeSearch: query too short (len=${q.length}) for entry=${entry._id}');
      setState(() {
        entry.searchResults = null;
        entry.searching = false;
      });
      _searchTimers.remove(entry._id);
      return;
    }

    // debounce 500ms
    entry.searching = true;
    _searchTimers[entry._id] = Timer(const Duration(milliseconds: 500), () {
      _performEmployeeSearch(entry, q.trim());
    });
  }

  Future<void> _performEmployeeSearch(_VoucherEntry entry, String q) async {
    try {
      debugPrint('[IssueVoucher] _performEmployeeSearch: entry=${entry._id} q="$q"');

      final user = await SessionManager.getUserData();
      final employerId = user?.employerid;
      if (employerId == null) {
        debugPrint('[IssueVoucher] _performEmployeeSearch: employerId not available in session');
        setState(() => entry.searching = false);
        return;
      }

      final params = {'orgId': employerId, 'userName': q};
      debugPrint('[IssueVoucher] _performEmployeeSearch: calling getVoucherNameSearchMobile with params=$params');

      final resp = await _api_serviceSafeGet(() => _apiService.getVoucherNameSearchMobile(params));

      debugPrint('[IssueVoucher] _performEmployeeSearch: raw resp => $resp');

      if (resp != null) {
        setState(() {
          entry.searchResults = resp;
          entry.searching = false;
        });
      } else {
        setState(() {
          entry.searchResults = null;
          entry.searching = false;
        });
      }
    } catch (e, st) {
      debugPrint('[IssueVoucher] _performEmployeeSearch: error => $e\n$st');
      setState(() {
        entry.searchResults = null;
        entry.searching = false;
      });
    } finally {
      _searchTimers[entry._id]?.cancel();
      _searchTimers.remove(entry._id);
    }
  }

  // Extracts suggestion list from entry.searchResults
  List<Map<String, dynamic>> _extractSearchList(_VoucherEntry entry) {
    final sr = entry.searchResults;
    if (sr == null) return [];
    try {
      if (sr is Map && sr['data'] is List) {
        return List<Map<String, dynamic>>.from(
          (sr['data'] as List).map((e) => Map<String, dynamic>.from(e as Map)),
        );
      }
      if (sr is List) {
        return List<Map<String, dynamic>>.from(
          sr.map((e) => Map<String, dynamic>.from(e as Map)),
        );
      }
    } catch (_) {}
    return [];
  }

  // Select bank and fetch balance for that account using getBankBalance
  void _selectBankAtIndex(int idx) async {
    if (idx < 0 || idx >= _banks.length) {
      debugPrint('[IssueVoucher] _selectBankAtIndex: invalid index $idx');
      return;
    }
    final bank = _banks[idx];
    final bankName = (bank['bankName'] ?? bank['name'] ?? 'Account').toString();
    final account = (bank['acNumber'] ?? bank['account'] ?? '').toString();
    final masked = _maskAccount(account);

    debugPrint('[IssueVoucher] _selectBankAtIndex: selected bank index=$idx name=$bankName account=$account id=${bank['id'] ?? bank['bankId']}');

    setState(() {
      _selectedBankName = bankName;
      _selectedBankMasked = masked;
      _selectedBankId = (bank['id']?.toString() ?? bank['bankId']?.toString() ?? '');
      _loadingBalance = true; // show loader while fetching balance
      _availableBalance = 0.0; // reset prior balance while loading
    });

    try {
      final user = await SessionManager.getUserData();
      debugPrint('[IssueVoucher] _selectBankAtIndex: session user => $user');
      if (user == null || user.employerid == null) {
        debugPrint('[IssueVoucher] _selectBankAtIndex: no user/employerid, aborting balance fetch');
        setState(() => _loadingBalance = false);
        return;
      }

      final params = {
        "acNumber": account,
        "orgId": user.employerid,
      };

      debugPrint('[IssueVoucher] _selectBankAtIndex: calling getBankBalance with params: $params');
      final balResp = await _api_serviceSafeGet(() => _apiService.getBankBalance(params));
      debugPrint('[IssueVoucher] _selectBankAtIndex: getBankBalance raw response => $balResp');

      if (balResp != null && (balResp['status'] == true || balResp['success'] == true)) {
        final raw = balResp['balance'] ?? balResp['availableBalance'] ?? balResp['data'] ?? 0;
        debugPrint('[IssueVoucher] _selectBankAtIndex: raw balance field => $raw');
        final balanceValue = double.tryParse(raw?.toString() ?? '0') ?? 0.0;
        debugPrint('[IssueVoucher] _selectBankAtIndex: parsed balance => $balanceValue');
        setState(() {
          _availableBalance = balanceValue;
          _loadingBalance = false;
        });
      } else {
        debugPrint('[IssueVoucher] _selectBankAtIndex: balance response indicates failure or null');
        setState(() => _loadingBalance = false);
      }
    } catch (e, st) {
      debugPrint('[IssueVoucher] _selectBankAtIndex: Error fetching bank balance: $e\n$st');
      setState(() => _loadingBalance = false);
    }
  }

  String _maskAccount(String account) {
    final cleaned = account.replaceAll(RegExp(r'\s+'), '');
    if (cleaned.length <= 4) return cleaned.isEmpty ? 'xxxx1234' : cleaned;
    final last = cleaned.substring(cleaned.length - 4);
    return 'xxxx$last';
  }

  // ---------------- dynamic entries ----------------
  // focus: whether to request focus/scroll for the new entry (default true)
  void _addNewEntry({bool focus = true}) {
    final newEntry = _VoucherEntry();

    // attach listener for name changes to trigger search
    newEntry.nameController.addListener(() {
      // if we are suppressing (programmatic set), just reset suppress and skip
      if (newEntry.suppressListener) {
        newEntry.suppressListener = false;
        return;
      }

      final text = newEntry.nameController.text;
      if (text.isEmpty) {
        // If name is cleared manually, clear mobile and selected employee
        newEntry.mobileController.clear();
        newEntry.selectedEmployee = null;
        newEntry.suggestionSelected = false;
        // hide suggestions
        setState(() {
          newEntry.searchResults = null;
        });
      } else {
        _scheduleEmployeeSearch(newEntry, text);
      }
      setState(() {});
    });

    setState(() {
      _entries.add(newEntry);
    });

    // Scroll to bottom and focus new entry's name only if focus == true
    if (focus) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!_scrollController.hasClients) return;
        await _scrollController.animateTo(
          _scroll_controller_position_max_plus(),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
        newEntry.nameFocus.requestFocus();
      });
    }
  }

  // helper to avoid long line in widget code
  double _scroll_controller_position_max_plus() {
    try {
      return _scrollController.position.maxScrollExtent + 200;
    } catch (_) {
      return 0.0;
    }
  }

  void _removeEntry(int index) {
    if (index < 0 || index >= _entries.length) return;
    final entry = _entries.removeAt(index);

    // cancel timer for this entry if any
    _searchTimers[entry._id]?.cancel();
    _searchTimers.remove(entry._id);

    entry.dispose();
    setState(() {});
  }

  bool get _allEntriesValid {
    if (_entries.isEmpty) return false;
    for (final e in _entries) {
      if (!e.isValid) return false;
    }
    return true;
  }

  // ---------------- pickers ----------------
  void _openVoucherPicker(int forIndex) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        // Use StatefulBuilder so sheet UI updates (expand + loading children) reflect immediately
        return StatefulBuilder(builder: (sheetCtx, sheetSetState) {
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.66,
            minChildSize: 0.38,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              final mq = MediaQuery.of(context);
              final horizontalPadding = mq.size.width > 420 ? 28.0 : 16.0;
              return Container(
                decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
                child: Column(
                  children: [
                    Container(margin: const EdgeInsets.only(top: 12, bottom: 6), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4))),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
                      child: Row(
                        children: [
                          const Expanded(child: Text('UPI VOUCHER CATEGORIES', style: TextStyle(fontWeight: FontWeight.w700))),
                          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(ctx).pop()),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 6),

                            if (_loadingCategories)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                child: Center(child: CircularProgressIndicator()),
                              )
                            else if (_voucherCategories.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Center(child: Text('No categories available')),
                              )
                            else
                              ...List.generate(_voucherCategories.length, (index) {
                                final cat = _voucherCategories[index];
                                final isExpanded = _expandedTopIndex == index;
                                final children = (cat['children'] as List).cast<Map<String, dynamic>>();
                                final loadingChildren = cat['loadingChildren'] == true;
                                final String title = cat['title']?.toString() ?? 'Category';
                                final IconData displayIcon = _iconForCategory(cat, index);

                                return Column(
                                  children: [
                                    InkWell(
                                      onTap: () async {
                                        setState(() => _expandedTopIndex = isExpanded ? null : index);
                                        sheetSetState(() {});
                                        if (!isExpanded && (children.isEmpty)) {
                                          setState(() => _voucherCategories[index]['loadingChildren'] = true);
                                          sheetSetState(() {});
                                          await _loadSubCategoriesForIndex(index);
                                          sheetSetState(() {});
                                        }
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(vertical: 8),
                                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
                                        child: Row(
                                          children: [
                                            Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(44)), child: Icon(displayIcon, color: Colors.green, size: 22)),
                                            const SizedBox(width: 12),
                                            Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                                            Transform.rotate(angle: isExpanded ? pi / 2 : 0, child: const Icon(Icons.keyboard_arrow_down, color: Colors.black54)),
                                          ],
                                        ),
                                      ),
                                    ),
                                    AnimatedCrossFade(
                                      firstChild: const SizedBox.shrink(),
                                      secondChild: Column(
                                        children: [
                                          if (loadingChildren)
                                            const Padding(
                                              padding: EdgeInsets.symmetric(vertical: 12),
                                              child: Center(child: CircularProgressIndicator()),
                                            )
                                          else if (children.isEmpty)
                                            Column(children: [
                                              ListTile(
                                                contentPadding: const EdgeInsets.only(left: 68.0, right: 12.0),
                                                leading: Container(width: 34, height: 34, decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(8)), child: Icon(displayIcon, color: Colors.black54, size: 20)),
                                                title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: _formFontSize)),
                                                onTap: () {
                                                  debugPrint('[IssueVoucher] _openVoucherPicker: selected top (no children)="$title" for index=$forIndex');
                                                  setState(() {
                                                    _entries[forIndex].selectedVoucher = title;
                                                    _entries[forIndex].selectedPurposeCode = cat['purposeCode']?.toString();
                                                    _entries[forIndex].selectedTopId = cat['topId']?.toString();
                                                  });
                                                  Navigator.of(ctx).pop();
                                                },
                                              ),
                                              Divider(color: Colors.grey.shade200, height: 1),
                                            ])
                                          else
                                            ...children.map((child) {
                                              final childTitle = child['title'] ?? 'Sub';
                                              final childId = child['id'];
                                              final IconData childIcon = _iconForChild(childTitle.toString());
                                              return Column(children: [
                                                ListTile(
                                                  contentPadding: const EdgeInsets.only(left: 68.0, right: 12.0),
                                                  leading: Container(width: 34, height: 34, decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(8)), child: Icon(childIcon, color: Colors.black54, size: 20)),
                                                  title: Text(childTitle.toString(), style: const TextStyle(fontWeight: FontWeight.w500, fontSize: _formFontSize)),
                                                  onTap: () {
                                                    debugPrint('[IssueVoucher] _openVoucherPicker: selected sub="$childTitle" (id=$childId) for index=$forIndex');
                                                    setState(() {
                                                      _entries[forIndex].selectedVoucher = childTitle.toString();
                                                      _entries[forIndex].selectedChildId = childId?.toString();
                                                      _entries[forIndex].selectedPurposeCode = cat['purposeCode']?.toString();
                                                      _entries[forIndex].selectedTopId = cat['topId']?.toString();
                                                    });
                                                    Navigator.of(ctx).pop();
                                                  },
                                                ),
                                                Divider(color: Colors.grey.shade200, height: 1),
                                              ]);
                                            }).toList(),
                                        ],
                                      ),
                                      crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                                      duration: const Duration(milliseconds: 160),
                                    ),
                                  ],
                                );
                              }),

                            const SizedBox(height: 12),
                            const Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text('OTHER CATEGORIES', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54))),
                            const SizedBox(height: 8),

                            LayoutBuilder(builder: (context, constraints) {
                              int crossCount = 3;
                              if (constraints.maxWidth > 600) crossCount = 4;
                              final listForGrid = _voucherCategories;
                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: listForGrid.length,
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: crossCount, childAspectRatio: 0.95, mainAxisSpacing: 12, crossAxisSpacing: 12),
                                itemBuilder: (context, index) {
                                  final cat = listForGrid[index];
                                  final title = cat['title'] ?? 'Cat';
                                  final icon = _iconForCategory(cat, index);
                                  return GestureDetector(
                                    onTap: () {
                                      debugPrint('[IssueVoucher] _openVoucherPicker: selected grid cat="${title}" for index=$forIndex');
                                      setState(() {
                                        _entries[forIndex].selectedVoucher = title.toString();
                                        _entries[forIndex].selectedPurposeCode = cat['purposeCode']?.toString();
                                        _entries[forIndex].selectedTopId = cat['topId']?.toString();
                                      });
                                      Navigator.of(ctx).pop();
                                    },
                                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                                      Container(width: 56, height: 56, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300), color: Colors.white), child: Center(child: Icon(icon, color: Colors.green, size: 22))),
                                      const SizedBox(height: 8),
                                      Text(title.toString(), style: const TextStyle(fontSize: 13), textAlign: TextAlign.center),
                                    ]),
                                  );
                                },
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        });
      },
    );
  }

  IconData _iconForCategory(Map<String, dynamic> cat, int index) {
    final provided = cat['icon'];
    if (provided is String) {}
    final titlestring = (cat['title'] ?? '').toString().toLowerCase();
    if (titlestring.contains('fuel') || titlestring.contains('gas')) return Icons.local_gas_station;
    if (titlestring.contains('meal') || titlestring.contains('food')) return Icons.restaurant;
    if (titlestring.contains('travel')) return Icons.flight;
    if (titlestring.contains('uniform')) return Icons.checkroom;
    if (titlestring.contains('gadg')) return Icons.phone_android;
    final iconsFallback = [Icons.receipt_long, Icons.work_outline, Icons.local_offer, Icons.shopping_bag];
    return iconsFallback[index % iconsFallback.length];
  }

  IconData _iconForChild(String title) {
    final titlestring = title.toLowerCase();
    if (titlestring.contains('gas')) return Icons.local_gas_station;
    if (titlestring.contains('fuel')) return Icons.local_gas_station;
    if (titlestring.contains('indraprastha')) return Icons.wb_sunny;
    if (titlestring.contains('breakfast') || titlestring.contains('lunch') || titlestring.contains('dinner') || titlestring.contains('meal')) return Icons.restaurant;
    return Icons.receipt_long;
  }

  void _openRedemptionPicker(int forIndex) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Container(
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
            padding: const EdgeInsets.only(top: 8, left: 16, right: 16, bottom: 20),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4))),
              Row(children: [const Expanded(child: Text('REDEMPTION TYPE', style: TextStyle(fontWeight: FontWeight.w700))), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(ctx).pop())]),
              const SizedBox(height: 6),
              ListTile(title: const Text('Single', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)), onTap: () { debugPrint('[IssueVoucher] _openRedemptionPicker: selected Single for index=$forIndex'); setState(() => _entries[forIndex].redemptionType = 'Single'); Navigator.of(ctx).pop(); }),
              const Divider(height: 1),
              ListTile(title: const Text('Multiple', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)), onTap: () { debugPrint('[IssueVoucher] _openRedemptionPicker: selected Multiple for index=$forIndex'); setState(() => _entries[forIndex].redemptionType = 'Multiple'); Navigator.of(ctx).pop(); }),
            ]),
          ),
        );
      },
    );
  }

  // ---------------- UI helpers ----------------
  double _clamp(double v, double a, double b) => v.clamp(a, b);

  Widget _bankSelectorBox(double iconSize, double innerPadding) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
          builder: (ctx) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 12.0),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 10), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4))),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8), child: Align(alignment: Alignment.centerLeft, child: Text('SELECT ACCOUNT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)))),
                  if (_loadingBanks)
                    const Padding(padding: EdgeInsets.symmetric(vertical: 32.0), child: Center(child: CircularProgressIndicator()))
                  else if (_banks.isEmpty)
                    const Padding(padding: EdgeInsets.symmetric(vertical: 24.0), child: Text('No accounts available'))
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _banks.length,
                        separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
                        itemBuilder: (context, index) {
                          final bank = _banks[index];
                          final bankName = (bank['bankName'] ?? bank['name'] ?? 'Bank').toString();
                          final account = (bank['acNumber'] ?? bank['account'] ?? '').toString();
                          final masked = _maskAccount(account);
                          final bankIconBase64 = bank['bankIcon']?.toString();
                          return ListTile(
                            onTap: () {
                              debugPrint('[IssueVoucher] bank list tapped index=$index, account=$account');
                              _selectBankAtIndex(index);
                              Navigator.of(ctx).pop();
                            },
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            leading: _bankIconWidget(bankIconBase64, size: 44),
                            title: Text(bankName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: _formFontSize)),
                            subtitle: Text(masked, style: const TextStyle(fontSize: _formFontSize)),
                            trailing: const Icon(Icons.chevron_right),
                          );
                        },
                      ),
                    ),
                ]),
              ),
            );
          },
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: innerPadding, vertical: innerPadding * 0.6),
        decoration: BoxDecoration(
          color: const Color(0xFF26282C),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(children: [
          RichText(text: TextSpan(children: [
            TextSpan(text: 'coto', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: _clamp(MediaQuery.of(context).size.width * 0.045, 14, 20))),
            const WidgetSpan(child: SizedBox(width: 6)),
            TextSpan(text: 'Balance', style: TextStyle(color: Colors.white.withOpacity(0.95), fontWeight: FontWeight.w500, fontSize: _clamp(MediaQuery.of(context).size.width * 0.04, 12, 16))),
          ])),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF26282C),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Text(_SelectedBankMaskedOrDefault(), style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
        ]),
      ),
    );
  }

  String _SelectedBankMaskedOrDefault() {
    return _selectedBankMasked.isNotEmpty ? _selectedBankMasked : 'xxxx1234';
  }

  Widget _bankIconWidget(String? rawBase64, {double size = 44}) {
    if (rawBase64 == null || rawBase64.trim().isEmpty) {
      return Container(width: size, height: size, decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.account_balance, color: Colors.green));
    }
    try {
      String cleaned = rawBase64;
      if (cleaned.contains(',')) cleaned = cleaned.split(',').last;
      final Uint8List bytes = base64Decode(cleaned);
      return CircleAvatar(radius: size / 2, backgroundColor: Colors.transparent, backgroundImage: MemoryImage(bytes));
    } catch (e) {
      debugPrint('[IssueVoucher] _bankIconWidget: failed to decode base64 icon: $e');
      return Container(width: size, height: size, decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.account_balance, color: Colors.green));
    }
  }

  // ---------------- build ----------------
  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final horizontalPadding = _clamp(sw * 0.04, 12, 20);
    final cardRadius = _clamp(sw * 0.04, 14, 22);
    final innerPadding = _clamp(sw * 0.035, 10, 16);

    final rightAmountFont = _clamp(sw * 0.07, 18, 28);
    final labelFont = _clamp(sw * 0.035, 12, 16);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: horizontalPadding,
        title: const Text('Vouchers', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.black), onPressed: () => Navigator.pop(context)),
      ),
      body: Container(
        color: Colors.white,
        child: SingleChildScrollView(
          controller: _scroll_controller_safe(),
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: horizontalPadding),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(color: const Color(0xFF26282C), borderRadius: BorderRadius.circular(cardRadius)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(cardRadius),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: innerPadding, vertical: innerPadding),
                  color: const Color(0xFF26282C),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _bankSelectorBox(_clamp(sw * 0.05, 18, 24), innerPadding)),
                        ],
                      ),
                      SizedBox(height: innerPadding),
                      Row(
                        children: [
                          const Spacer(),
                          if (_loadingBalance)
                            SizedBox(width: 28, height: 28, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2).format(_availableBalance),
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: rightAmountFont),
                                ),
                                SizedBox(height: 6),
                                Text('Available Balance', style: TextStyle(color: Colors.white70, fontSize: labelFont)),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: horizontalPadding * 1.1),

            Text('Enter Details', style: TextStyle(fontSize: _clamp(sw * 0.045, 16, 20), fontWeight: FontWeight.bold)),
            SizedBox(height: horizontalPadding * 0.4),
            Text('Please input details for issuance of vouchers', style: TextStyle(color: Colors.black54, fontSize: _clamp(sw * 0.034, 12, 14))),
            SizedBox(height: horizontalPadding * 0.8),

            Column(
              children: List.generate(_entries.length, (index) {
                final entry = _entries[index];
                return KeyedSubtree(
                  key: ValueKey(entry._id),
                  child: Column(
                    children: [
                      _buildVoucherCard(index, sw, innerPadding),
                      SizedBox(height: horizontalPadding * 0.8),
                    ],
                  ),
                );
              }),
            ),

            GestureDetector(
              onTap: () => _addNewEntry(focus: true),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 14),
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                child: Center(child: Text('Add new Voucher +', style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold, fontSize: _clamp(sw * 0.04, 13, 16)))),
              ),
            ),
            SizedBox(height: horizontalPadding * 1.0),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _allEntriesValid ? _onSubmit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _allEntriesValid ? const Color(0xFF3366FF) : const Color(0xFFDFEAFE),
                  foregroundColor: _allEntriesValid ? Colors.white : Colors.blue.shade200,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: Text('Continue', style: TextStyle(fontSize: _clamp(sw * 0.042, 14, 16), fontWeight: FontWeight.w600)),
              ),
            ),
            SizedBox(height: horizontalPadding),
          ]),
        ),
      ),
    );
  }

  // safe getter for scroll controller to avoid issues when not attached
  ScrollController _scroll_controller_safe() {
    return _scrollController;
  }

  Widget _buildVoucherCard(int index, double sw, double innerPad) {
    final entry = _entries[index];
    final fieldHeight = _clamp(sw * 0.12, 46, 60);

    // suggestions from latest search
    final suggestions = _extractSearchList(entry);

    // If suggestionSelected is true, don't show suggestions at all
    final showSuggestions = suggestions.isNotEmpty && !entry.suggestionSelected;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Voucher ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
          InkWell(onTap: () => _removeEntry(index), child: const Icon(Icons.delete, color: Colors.red)),
        ]),
        const SizedBox(height: 12),

        // Name (with search spinner)
        SizedBox(
          height: fieldHeight,
          child: TextField(
            controller: entry.nameController,
            focusNode: entry.nameFocus,
            textInputAction: TextInputAction.next,
            style: const TextStyle(fontSize: _formFontSize),
            decoration: InputDecoration(
              hintText: 'Name',
              hintStyle: const TextStyle(fontSize: _formFontSize, color: Colors.grey),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
              suffixIcon: entry.searching
                  ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              )
                  : null,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),

        // Suggestions dropdown (like place search)
        if (showSuggestions)
          Container(
            margin: const EdgeInsets.only(top: 8),
            constraints: const BoxConstraints(maxHeight: 220),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: suggestions.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
              itemBuilder: (context, sIndex) {
                final item = suggestions[sIndex];
                final userName = item['username'] ?? item['userName'] ?? item['name'] ?? '';
                final mobile = item['mobile'] ?? item['mobileNumber'] ?? '';
                final email = item['email'] ?? '';
                return ListTile(
                  onTap: () {
                    debugPrint('[IssueVoucher] suggestion tapped => $item');

                    // prevent listener triggering search while we programmatically set text
                    entry.suppressListener = true;

                    // Fill controllers (set full name and mobile)
                    entry.nameController.text = (userName ?? '').toString();
                    // move cursor to end
                    entry.nameController.selection = TextSelection.fromPosition(TextPosition(offset: entry.nameController.text.length));
                    entry.mobileController.text = (mobile ?? '').toString();

                    // store selected employee for downstream APIs
                    entry.selectedEmployee = Map<String, dynamic>.from(item);

                    // mark suggestion as selected so dropdown doesn't reappear
                    entry.suggestionSelected = true;

                    // hide suggestions
                    setState(() {
                      entry.searchResults = null;
                    });

                    // unfocus keyboard
                    FocusScope.of(context).unfocus();
                  },
                  title: Text(userName.toString(), style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    '${mobile ?? ''}${(email != null && email.toString().isNotEmpty) ? ' • $email' : ''}',
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              },
            ),
          ),

        const SizedBox(height: 12),

        // Mobile
        SizedBox(
          height: fieldHeight,
          child: TextField(
            controller: entry.mobileController,
            keyboardType: TextInputType.phone,
            style: const TextStyle(fontSize: _formFontSize),
            decoration: InputDecoration(
              hintText: 'Mobile Number',
              hintStyle: const TextStyle(fontSize: _formFontSize, color: Colors.grey),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: 12),

        // Voucher selector
        InkWell(
          onTap: () => _openVoucherPicker(index),
          child: Container(
            height: fieldHeight,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
            child: Row(children: [
              Expanded(
                child: Text(
                  entry.selectedVoucher ?? 'Select Voucher',
                  style: TextStyle(
                    color: entry.selectedVoucher == null ? Colors.grey.shade600 : Colors.black87,
                    fontSize: _formFontSize,
                  ),
                ),
              ),
              const Icon(Icons.keyboard_arrow_down, color: Colors.black54)
            ]),
          ),
        ),
        const SizedBox(height: 12),

        // amount + redemption
        Row(children: [
          Expanded(
            child: SizedBox(
              height: fieldHeight,
              child: TextField(
                controller: entry.amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: _formFontSize),
                decoration: InputDecoration(
                  hintText: 'Enter Amount',
                  hintStyle: const TextStyle(fontSize: _formFontSize, color: Colors.grey),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: () => _openRedemptionPicker(index),
              child: Container(
                height: fieldHeight,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                child: Row(children: [
                  Expanded(
                    child: Text(entry.redemptionType ?? 'Redemption Type', style: TextStyle(color: entry.redemptionType == null ? Colors.grey.shade600 : Colors.black87, fontSize: _formFontSize)),
                  ),
                  const Icon(Icons.keyboard_arrow_down, color: Colors.black54)
                ]),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 12),

        // date + validity
        Row(children: [
          Expanded(
            child: InkWell(
              onTap: () async {
                final picked = await showDatePicker(context: context, initialDate: entry.selectedDate, firstDate: DateTime.now(), lastDate: DateTime(2100));
                if (picked != null) setState(() => entry.selectedDate = picked);
              },
              child: Container(
                height: fieldHeight,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8), color: Colors.white),
                child: Row(children: [
                  Text(DateFormat('dd/MM/yyyy').format(entry.selectedDate), style: const TextStyle(fontSize: _formFontSize)),
                  const Spacer(),
                  const Icon(Icons.calendar_month, color: Colors.black54)
                ]),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: () => _openValidityPicker(index),
              child: Container(
                height: fieldHeight,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                child: Row(children: [
                  Expanded(
                    child: Text(
                      entry.validity != null ? '${entry.validity} days' : 'Validity',
                      style: TextStyle(color: entry.validity == null ? Colors.grey.shade600 : Colors.black87, fontSize: _formFontSize),
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down, color: Colors.black54)
                ]),
              ),
            ),
          ),

        ]),
        const SizedBox(height: 12),
      ]),
    );
  }

  void _openValidityPicker(int forIndex) {
    final _entry = _entries[forIndex];
    final TextEditingController customController = TextEditingController(text: _entry.validity ?? '');

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.45,
          minChildSize: 0.2,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: StatefulBuilder(
                builder: (sheetCtx, sheetSetState) {
                  String? errorText;

                  bool isValidNumber(String txt) {
                    if (txt.trim().isEmpty) return false;
                    final n = int.tryParse(txt.trim());
                    if (n == null) return false;
                    return n >= 2 && n <= 365;
                  }

                  void onCustomChanged(String v) {
                    if (v.trim().isEmpty) {
                      sheetSetState(() => errorText = null);
                      return;
                    }
                    final n = int.tryParse(v.trim());
                    if (n == null) {
                      sheetSetState(() => errorText = 'Please enter a valid number');
                      return;
                    }
                    if (n < 2) {
                      sheetSetState(() => errorText = 'Minimum validity is 2 days');
                      return;
                    }
                    if (n > 365) {
                      sheetSetState(() => errorText = 'Maximum allowed is 365 days');
                      return;
                    }
                    sheetSetState(() => errorText = null);
                  }

                  // presets list helper to render nicely spaced tiles
                  Widget presetTile(String label, String value) {
                    return InkWell(
                      onTap: () {
                        setState(() => _entries[forIndex].validity = value);
                        Navigator.of(ctx).pop();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 4),
                        child: Text(label, style: const TextStyle(fontSize: 16)),
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
                          ),
                        ),

                        const SizedBox(height: 4),
                        const Text('VOUCHER VALIDITY', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        const SizedBox(height: 12),

                        // presets with thin dividers and roomy padding
                        presetTile('2 days', '2'),
                        Divider(height: 1, color: Colors.grey.shade300),
                        presetTile('7 days', '7'),
                        Divider(height: 1, color: Colors.grey.shade300),
                        presetTile('30 days', '30'),
                        Divider(height: 1, color: Colors.grey.shade300),
                        presetTile('90 days', '90'),
                        Divider(height: 1, color: Colors.grey.shade300),
                        presetTile('360 days', '360'),
                        Divider(height: 1, color: Colors.grey.shade300),

                        const SizedBox(height: 12),

                        // custom input field (rounded with purple border like your screenshot)
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.deepPurple.shade100, width: 2),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: TextField(
                            controller: customController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            onChanged: (v) => onCustomChanged(v),
                            style: const TextStyle(fontSize: 16),
                            decoration: InputDecoration(
                              hintText: 'Enter days: 2 - 365',
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                              errorText: errorText,
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // full-width rounded button (light purple bg, purple text)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isValidNumber(customController.text)
                                ? () {
                              final val = customController.text.trim();
                              // final safety check
                              final n = int.tryParse(val);
                              if (n == null || n < 2 || n > 365) {
                                sheetSetState(() => errorText = 'Enter value between 2 and 365');
                                return;
                              }
                              setState(() => _entries[forIndex].validity = n.toString());
                              Navigator.of(ctx).pop();
                            }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isValidNumber(customController.text) ? Colors.purple.shade50 : Colors.grey.shade200,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text(
                              'Set custom validity',
                              style: TextStyle(
                                color: isValidNumber(customController.text) ? Colors.purple.shade800 : Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }


  void _onSubmit() {
    // Build entries list for display + API
    final voucherDetails = _entries.map((e) {
      return {
        'name': e.nameController.text.trim(),
        'mobile': e.mobileController.text.trim(),
        'amount': e.amountController.text.trim(),
        'startDate': DateFormat('yyyy-MM-dd').format(e.selectedDate),
        'expDate': null,
        'purposeCode': e.selectedPurposeCode,
        'mcc': null,
        'mccDescription': null,
        'purposeDescription': e.selectedVoucher,
        'type': null,
        'bankcode': null,
        'voucherCode': e.selectedPurposeCode,
        'voucherType': null,
        'voucherDesc': e.selectedVoucher,
        'redemptionType': (e.redemptionType ?? '').toUpperCase(),
        'validity': _validityToDays(e.validity),
      };
    }).toList();

    // Build a concise payload for verification screen (you can add more fields as needed)
    final verifyPayload = {
      'bank': {
        'name': _selectedBankName,
        'masked': _selectedBankMasked,
        'id': _selectedBankId,
      },
      'entries': voucherDetails,
      'orgId': null, // we'll get from SessionManager in verify screen
      'accountNumber': null, // can fill if available from selected bank object
    };

    // navigate to verification screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VoucherVerifyScreen(
          apiService: _apiService,
          bankInfo: _selectedBankId.isNotEmpty ? {
            'name': _selectedBankName,
            'masked': _selectedBankMasked,
            'id': _selectedBankId,
          } : null,
          entries: voucherDetails,
        ),
      ),
    );
  }

// helper to convert dropdown validity text to numeric days used in your example
  String? _validityToDays(String? validity) {
    if (validity == null) return null;
    // if it already numeric string, return as-is
    final parsed = int.tryParse(validity);
    if (parsed != null) return parsed.toString();
    // if it was in "7 days" style, try to parse number prefix
    final onlyDigits = RegExp(r'\d+').firstMatch(validity)?.group(0);
    if (onlyDigits != null) return onlyDigits;
    return null;
  }

}

// ---------------- helper classes ----------------

class _VoucherEntry {
  static int _uid = 0;
  final int _id = _uid++;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final FocusNode nameFocus = FocusNode();

  DateTime selectedDate = DateTime.now();
  String? selectedVoucher;
  String? redemptionType;
  String? validity;
  String? remarks;

  String? selectedPurposeCode;
  String? selectedTopId;
  String? selectedChildId;

  // place to store search results (for suggestions)
  dynamic searchResults;

  // selected suggestion full object (for next API)
  Map<String, dynamic>? selectedEmployee;

  // searching status for spinner
  bool searching = false;

  // if true, suggestions won't be shown (e.g. after selecting one)
  bool suggestionSelected = false;

  // internal: suppress listener once when programmatically setting text
  bool suppressListener = false;

  bool get isValid =>
      nameController.text.trim().isNotEmpty &&
          mobileController.text.trim().isNotEmpty &&
          amountController.text.trim().isNotEmpty &&
          selectedVoucher != null &&
          redemptionType != null &&
          validity != null;

  void dispose() {
    try {
      nameController.dispose();
    } catch (_) {}
    try {
      mobileController.dispose();
    } catch (_) {}
    try {
      amountController.dispose();
    } catch (_) {}
    try {
      nameFocus.dispose();
    } catch (_) {}
  }
}
