// voucher_verify_screen.dart
import 'dart:async';
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
  bool _loading = false; // main button loading / disabled
  String _statusMessage = '';

  // OTP dialog state
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  int _resendSeconds = 30;
  Timer? _resendTimer;
  String? _orderId; // filled after OTP send
  bool _isVerifyingOtp = false; // used by dialog for UI spinner
  bool _isSendingOtp = false;

  // guard to avoid reentry inside verify method
  bool _verifyInProgress = false;

  // These must match backend secret/clientKey
  static const String SECRET_KEY = '0123456789012345';
  static const String CLIENT_KEY = 'client-secret-key';
  static const String MANDATE_TYPE = '01';

  bool _isOtpFilled = false;
  final TextEditingController _otpController = TextEditingController();


  @override
  void dispose() {
    for (final c in _otpControllers) {
      c.dispose();
    }
    _resendTimer?.cancel();
    super.dispose();
  }

  // --------------------------
  // BUILD / UI
  // --------------------------




  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text('Vouchers', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.black), onPressed: () => Navigator.pop(context)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBankCard(),
              const SizedBox(height: 16),
              _buildHeaderCard(),
              const SizedBox(height: 8),
              ...widget.entries.asMap().entries.map((pair) {
                final idx = pair.key;
                final e = pair.value;
                return _buildEntryCard(idx + 1, e);
              }).toList(),
              const SizedBox(height: 16),
              Row(children: [
                Checkbox(value: _consentChecked, onChanged: (v) => setState(() => _consentChecked = v ?? false)),
                const SizedBox(width: 8),
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
                  onPressed: (!_consentChecked || _loading) ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (_consentChecked && !_loading) ? const Color(0xFF3366FF) : const Color(0xFFFFFFFF),
                    foregroundColor: (_consentChecked && !_loading) ? Colors.white : const Color(0xFF3366FF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
                    'ISSUE VOUCHER',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: (_consentChecked && !_loading) ? Colors.white : const Color(0xFF3366FF),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }



  // ---------------
  //
  // -----------
  // Helper UI pieces (unchanged)
  // --------------------------
  Widget _buildTopBankCard() {
    final bank = widget.bankInfo ?? <String, dynamic>{};
    final masked = _firstString(bank, ['masked', 'acNumber', 'accountNumber', 'acnumber', 'account', 'bankAccount']) ?? 'xxxx1234';
    final dynamic rawBalance = _firstValue(bank, ['availableBalance', 'balance', 'availableBal', 'balanceAmount', 'available_balance']);
    final double balance = _parseBalance(rawBalance);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFF26282C), borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: const Color(0xFF26282C), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white.withOpacity(0.06))),
              child: Text(masked, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2).format(balance),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
          const SizedBox(height: 6),
          Text('Available Balance', style: TextStyle(color: Colors.white70, fontSize: 12)),
        ]),
      ]),
    );
  }

  double _parseBalance(dynamic v) {
    if (v == null) return 0.0;
    try {
      if (v is num) return v.toDouble();
      final s = v.toString().trim();
      if (s.isEmpty) return 0.0;
      final cleaned = s.replaceAll(RegExp(r'[^\d\.\-]'), '');
      return double.tryParse(cleaned) ?? 0.0;
    } catch (_) {
      return 0.0;
    }
  }

  String? _firstString(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      if (m.containsKey(k) && m[k] != null) return m[k].toString();
    }
    return null;
  }

  dynamic _firstValue(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      if (m.containsKey(k) && m[k] != null) return m[k];
    }
    return null;
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
            Text(bank['name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(bank['masked']?.toString() ?? _firstString(bank, ['masked', 'acNumber', 'accountNumber']) ?? '', style: const TextStyle(color: Colors.black54)),
          ])
        ]
      ]),
    );
  }

  Widget _buildEntryCard(int index, Map<String, dynamic> e) {
    String formatAmount(String? a) {
      if (a == null || a.isEmpty) return '';
      final parsed = double.tryParse(a) ?? 0.0;
      return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(parsed);
    }

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300), color: Colors.white),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.local_offer_outlined, size: 20),
          const SizedBox(width: 8),
          Text(e['purposeDescription'] ?? e['voucherDesc'] ?? 'Voucher', style: const TextStyle(fontWeight: FontWeight.w700)),
          const Spacer(),
          InkWell(
            onTap: () {
              final total = widget.entries.length;

              if (total == 1) {
                // confirm before deleting last voucher — then go back if user confirms
                // call like:
 _showDeleteVoucherDialog(context, () {
   setState(() { widget.entries.remove(e); });
   Navigator.of(context).pop(); // close dialog
   Navigator.of(context).pop(); // go back
 });




              } else {
                // remove directly when more than one
                setState(() {
                  widget.entries.remove(e);
                });
              }
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

  // --------------------------
  // OTP / Login / Verify / Issue flows
  // --------------------------



  Future<void> _showDeleteVoucherDialog(BuildContext context, VoidCallback onDelete) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 350,
                maxHeight: 226,
                minWidth: 300,
              ),
              child: Container(
                width: 350,
                height: 226,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 6),

                    // Green check icon
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2F945A),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 30),
                    ),

                    const SizedBox(height: 12),

                    // Title — Delete Voucher
                    const Text(
                      'Delete Voucher',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'OpenSans',
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        height: 1.4, // line-height 140%
                        letterSpacing: 0,
                        color: Color(0xFF1F1F23),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Message
                    const Text(
                      'Are you sure you want to delete?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'OpenSans',
                        fontWeight: FontWeight.w400,
                        fontSize: 13,
                        height: 1.4,
                        letterSpacing: 0,
                        color: Color(0xFF50535F),
                      ),
                    ),

                    const Spacer(),

                    // Buttons row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // DELETE (outlined red)
                        SizedBox(
                          width: 149,
                          height: 46,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(width: 1, color: Color(0xFFEB5757)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            onPressed: () {
                              onDelete();
                            },
                            child: const Text(
                              "Delete",
                              style: TextStyle(
                                fontFamily: 'OpenSans',
                                fontWeight: FontWeight.w600,  // SemiBold
                                fontSize: 16,
                                height: 1.4,  // 140%
                                letterSpacing: 0,
                                color: Color(0xFFEB5757),
                              ),
                            ),
                          ),
                        ),

                        // CANCEL (filled blue)
                        SizedBox(
                          width: 149,
                          height: 46,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF3B82F6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              elevation: 0,
                            ),
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text(
                              "Cancel",
                              style: TextStyle(
                                fontFamily: 'OpenSans',
                                fontWeight: FontWeight.w600,   // SemiBold
                                fontSize: 16,
                                height: 1.4,   // 140%
                                letterSpacing: 0,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )   ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }


  /// Called when user taps ISSUE VOUCHER button. Sends OTP and opens OTP dialog.
  Future<void> _handleLogin() async {
    if (_loading) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _statusMessage = '';
      _isSendingOtp = true;
    });

    try {
      final user = await SessionManager.getUserData();
      final employerMobile = user?.mobile?.toString() ?? '';
      final rowcount = widget.entries.length.toString();

      // Build payload - adapt keys if your backend needs different names
      final payload = {
        "mobile": employerMobile,
        "template": "OTP Number Vouchers Issuance",
        "value": rowcount,
      };

      final response = await widget.apiService.getVoucherOtp(payload);
      debugPrint('[getVoucherOtp] => $response');

      if (response != null && response['status'] == true) {
        // store orderId if returned
        if (response['data'] != null && response['data']['orderId'] != null) {
          _orderId = response['data']['orderId'].toString();
        } else if (response['orderId'] != null) {
          _orderId = response['orderId'].toString();
        } else {
          _orderId = null;
        }

        // reset OTP controllers
        for (final c in _otpControllers) c.text = '';

        // start resend timer
        _startResendTimer();

        // open OTP dialog (responsive)
        _showOtpDialog(employerMobile);
      } else {
        final msg = response != null ? (response['message'] ?? 'Failed to send OTP') : 'Failed to send OTP';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
      }
    } catch (e, st) {
      debugPrint('Error sending OTP: $e\n$st');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error sending OTP: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _isSendingOtp = false;
        });
      }
    }
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _resendSeconds = 30);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_resendSeconds <= 0) {
        t.cancel();
      } else {
        setState(() => _resendSeconds -= 1);
      }
    });
  }

  /// Responsive OTP dialog
  void _showOtpDialog(String mobile) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final mq = MediaQuery.of(ctx);
        final w = mq.size.width;
        final dialogWidth = w < 500 ? w * 0.92 : 480.0;
        final otpBoxSize = (dialogWidth - 80) / 6; // approx spacing
        final otpFont = otpBoxSize * 0.45;

        return StatefulBuilder(builder: (context, setDialogState) {
          Future<void> resendOtp() async {
            setDialogState(() => _isSendingOtp = true);
            try {
              final user = await SessionManager.getUserData();
              final employerMobile = user?.mobile?.toString() ?? '';
              final payload = {
                "mobile": employerMobile,
                "template": "OTP Number Vouchers Issuance",
                "value": widget.entries.length.toString(),
              };
              final resp = await widget.apiService.getVoucherOtp(payload);
              debugPrint('[resendOtp] => $resp');
              if (resp != null && resp['status'] == true) {
                _startResendTimer();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP resent'), backgroundColor: Colors.green));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resp?['message'] ?? 'Could not resend OTP'), backgroundColor: Colors.red));
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Resend error: $e'), backgroundColor: Colors.red));
            } finally {
              if (mounted) setDialogState(() => _isSendingOtp = false);
            }
          }

          Future<void> verifyOtpFromDialog() async {
            setDialogState(() => _isVerifyingOtp = true);
            debugPrint('>>> Dialog: starting OTP verify');

            final success = await _handleVerifyOtp(); // returns bool
            setDialogState(() => _isVerifyingOtp = false);

            if (!mounted) return;

            if (success) {
              debugPrint('>>> Dialog: OTP verified successfully, closing dialog and calling _issueVoucher');
              // close OTP dialog
              try { Navigator.of(ctx).pop(); } catch (_) {}
              // quick green toast
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP Verified'), backgroundColor: Colors.green, duration: Duration(milliseconds: 900)));

              // small delay then call issue
              await Future.delayed(const Duration(milliseconds: 400));

              // call _issueVoucher
              await _issueVoucher();
            } else {
              debugPrint('>>> Dialog: OTP verification failed — not calling _issueVoucher');
            }
          }

          Widget otpBoxesRow()
          {
            return Wrap(
              spacing: otpBoxSize * 0.08,
              alignment: WrapAlignment.center,
              children: List.generate(6, (i) {
                return SizedBox(
                  width: otpBoxSize.clamp(40.0, 64.0),
                  height: otpBoxSize.clamp(40.0, 64.0),
                  child: TextField(
                    controller: _otpControllers[i],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    style: TextStyle(fontSize: otpFont.clamp(16.0, 22.0), fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      counterText: '',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blue.shade300, width: 2), borderRadius: BorderRadius.circular(8)),
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (v) {
                      // move focus
                      if (v.isNotEmpty) {
                        if (i + 1 < 6) FocusScope.of(context).nextFocus();
                        else FocusScope.of(context).unfocus();
                      } else {
                        if (i - 1 >= 0) FocusScope.of(context).previousFocus();
                      }

                      // compute joined OTP and update _isOtpFilled in the dialog's state
                      final entered = _otpControllers.map((c) => c.text.trim()).join();
                      final filled = entered.length == 6 && entered.runes.every((r) => r >= 48 && r <= 57); // digits only

                      // update dialog state so button becomes enabled/disabled immediately
                      setDialogState(() {
                        _isOtpFilled = filled;
                      });
                    },
                  ),
                );
              }),
            );
          }


          return Dialog(

            insetPadding: EdgeInsets.symmetric(horizontal: mq.size.width * 0.04, vertical: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: dialogWidth),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // header row with title and close
                    Row(
                      children: [
                        Expanded(child: Text('Authentication for Issuance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                        InkWell(onTap: () { _resendTimer?.cancel(); Navigator.of(ctx).pop(); }, child: const Icon(Icons.close)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    otpBoxesRow(),
                    const SizedBox(height: 12),

                    // resend line
                    if (_resendSeconds > 0)

                      Text("Didn't receive the code? 00:${_resendSeconds.toString().padLeft(2, '0')}", style: const TextStyle(color: Colors.black54))
                    else
                      GestureDetector(onTap: resendOtp, child: Text("Didn't receive the code? Resend", style: TextStyle(color: Colors.blue.shade700))),

                    const SizedBox(height: 12),
                    Column(
                      children: [

                        FutureBuilder(
                          future: SessionManager.getUserData(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            if (!snapshot.hasData) {
                              return const Text('Unable to load user data');
                            }

                            final user = snapshot.data;
                            final maskedNumber = (user?.mobile != null && user!.mobile!.length >= 4)
                                ? '+91-xxxxxx ${user.mobile!.substring(user.mobile!.length - 4)}'
                                : '+91-xxxxxxXXXX';

                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'OTP code has been sent to your phone $maskedNumber. Enter OTP to validate issuance.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 13),
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // button
                    SizedBox(
                      width: double.infinity,

                      child: ElevatedButton(
                        onPressed: (_isVerifyingOtp || _isSendingOtp || !_isOtpFilled)
                            ? null
                            : verifyOtpFromDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isOtpFilled
                              ? const Color(0xFF367AFF)   // OTP filled
                              : const Color(0xFFEBF2FF),  // OTP not filled
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isVerifyingOtp
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : Text(
                          'AUTHENTICATE',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _isOtpFilled
                                ? Colors.white              // OTP filled
                                : const Color(0xFFA3C2FF),  // OTP not filled
                          ),
                        ),
                      ),



                    ),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }

  /// Verify OTP handler — returns bool (true if verified)
  Future<bool> _handleVerifyOtp() async {
    if (_verifyInProgress) {
      debugPrint('>>> _handleVerifyOtp: already in progress, returning false');
      return false;
    }
    _verifyInProgress = true;

    final enteredOtp = _otpControllers.map((c) => c.text.trim()).join();
    debugPrint('>>> _handleVerifyOtp: enteredOtp="$enteredOtp", orderId=$_orderId');

    if (enteredOtp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter 6-digit OTP'), backgroundColor: Colors.red));
      _verifyInProgress = false;
      return false;
    }

    setState(() { _statusMessage = ''; });

    try {
      final user = await SessionManager.getUserData();
      final mobile = user?.mobile?.toString() ?? '';
      final otpPayload = {
        'mobile': mobile,
        'otp': enteredOtp,
        if (_orderId != null) 'orderId': _orderId,
      };

      debugPrint('>>> _handleVerifyOtp: calling api.verifyOtp with payload: $otpPayload');
      final resp = await widget.apiService.verifyOtp(otpPayload);
      debugPrint('<<< _handleVerifyOtp: verifyOtp response: $resp');

      if (resp != null && resp['status'] == true) {
        _verifyInProgress = false;
        return true;
      } else {
        final msg = resp != null ? (resp['message'] ?? 'Invalid OTP') : 'Invalid OTP';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
        _verifyInProgress = false;
        return false;
      }
    } catch (e, st) {
      debugPrint('*** _handleVerifyOtp ERROR: $e\n$st');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('OTP verify error: $e'), backgroundColor: Colors.red));
      _verifyInProgress = false;
      return false;
    }
  }


  /// ISSUE VOUCHER — responsive congrats dialog and full request body
  Future<void> _issueVoucher() async {
    debugPrint('>>> _issueVoucher: starting');
    setState(() { _loading = true; _statusMessage = ''; });

    try {
      final user = await SessionManager.getUserData();
      final orgId = user?.employerid?.toString() ?? '';
      final createdBy = (user?.username ?? '').toString();

      final merchantId = widget.bankInfo?['merchantId']?.toString() ?? widget.bankInfo?['merchentIid']?.toString() ?? '610954';
      final subMerchantId = widget.bankInfo?['subMerchantId']?.toString() ?? widget.bankInfo?['submurchentid']?.toString() ?? merchantId;
      final accountNumber = widget.bankInfo?['accountNumber']?.toString() ?? widget.bankInfo?['acNumber']?.toString() ?? '';
      final payerVA = widget.bankInfo?['payerVA']?.toString() ?? widget.bankInfo?['payeeVPA']?.toString() ?? widget.bankInfo?['payerva']?.toString() ?? 'merchant@icici';
      final bankcode = widget.bankInfo?['bankCode']?.toString() ?? widget.bankInfo?['bankcode']?.toString() ?? widget.bankInfo?['bankName']?.toString() ?? '';

      final List<Map<String, dynamic>> details = widget.entries.map((e) {
        return {
          "name": e['name'] ?? '',
          "mobile": e['mobile'] ?? '',
          "voucher": e['mccDescription'] ?? e['mccDescription'] ?? e['mccDescription'] ?? '',
          "mcc": e['mcc'] ?? '',
          "mccDescription": e['mccDescription'] ?? '',
          "purposeCode": e['purposeCode'] ?? e['voucherCode'] ?? '',
          "purposeDescription": e['purposeDescription'] ?? e['voucherDesc'] ?? '',
          "voucherCode": e['voucherCode'] ?? e['purposeCode'] ?? '',
          "voucherDesc": e['voucherDesc'] ?? e['purposeDescription'] ?? '',
          "redemptionType": e['redemptionType'] ?? '',
          "amount": e['amount']?.toString() ?? '',
          "startDate": e['startDate'] ?? DateFormat('yyyy-MM-dd').format(DateTime.now()),
          "validity": e['validity']?.toString() ?? '',
        };
      }).toList();

      final consent = _consentChecked ? 'yes' : 'no';
      final activeStatus = '';

      final hashInput = consent +
          createdBy +
          orgId +
          merchantId +
          subMerchantId +
          accountNumber +
          payerVA +
          MANDATE_TYPE +
          SECRET_KEY +
          CLIENT_KEY;

      debugPrint("Hash Input: $hashInput");

      final hash = _sha256Hex(hashInput);

      final requestBody = {
        "consent": consent,
        "createdby": createdBy,
        "orgId": orgId,
        "merchantId": merchantId,
        "subMerchantId": subMerchantId,
        "activeStatus": activeStatus,
        "bankcode": bankcode,
        "accountNumber": accountNumber,
        "payerVA": payerVA,
        "mandateType": MANDATE_TYPE,
        "clientKey": CLIENT_KEY,
        "hash": hash,
        "erupiVoucherCreateDetails": details,
      };







      debugPrint('[VoucherVerify] requestBody => ${jsonEncode(requestBody)}');

      final resp = await widget.apiService.createSingleVoucher(requestBody);

      debugPrint('<<< _issueVoucher: api response => $resp');

      if (resp != null && (resp['status'] == true || resp['success'] == true)) {
        // show congrats dialog responsive
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) {
            final mq = MediaQuery.of(ctx);
            final w = mq.size.width;
            final dialogWidth = w < 500 ? w * 0.92 : 420.0;
            return Dialog(
              insetPadding: EdgeInsets.symmetric(horizontal: mq.size.width * 0.04),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: dialogWidth),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 22),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.green.shade50),
                      child: const Icon(Icons.check, color: Colors.green, size: 36),
                    ),
                    const SizedBox(height: 14),
                    const Text('Congratulations!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 8),
                    const Text('Voucher Successfully Issued', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(ctx).pop(); // close dialog
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF367AFF), // #367AFF
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'Done',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.white, // white text
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            );
          },
        );

        // after done, navigate to root/home
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        final msg = resp != null ? (resp['message'] ?? 'Failed to issue voucher') : 'Failed to issue voucher';
        debugPrint('!!! _issueVoucher failed: $msg');
        setState(() {
          _statusMessage = msg;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
      }
    } catch (e, st) {
      debugPrint('*** _issueVoucher EXCEPTION: $e\n$st');
      setState(() {
        _statusMessage = 'An error occurred: ${e.toString()}';
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Issue error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() {
        _loading = false;
      });
      debugPrint('>>> _issueVoucher: finished (loading=false)');
    }
  }

  String _sha256Hex(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }


}
