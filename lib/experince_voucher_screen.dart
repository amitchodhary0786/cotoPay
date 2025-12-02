import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ExperienceUpiVoucherScreen extends StatefulWidget {
  const ExperienceUpiVoucherScreen({Key? key}) : super(key: key);

  @override
  State<ExperienceUpiVoucherScreen> createState() => _ExperienceUpiVoucherScreenState();
}

class _ExperienceUpiVoucherScreenState extends State<ExperienceUpiVoucherScreen> {
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();

  // Default selected amount = 5
  int? _selectedAmount = 5; // 5,10,25,50

  // Default selected category = Meal
  String _selectedCategory = "Meal";

  bool get _isFormValid =>
      _nameController.text.trim().isNotEmpty &&
          _mobileController.text.trim().isNotEmpty &&
          _selectedAmount != null;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() => setState(() {}));
    _mobileController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  Widget _amountChip(int value) {
    final bool selected = _selectedAmount == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedAmount = value),
      child: Container(
        width: 75.5,
        height: 44,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2F945A) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? Colors.transparent : const Color(0xFFE6E6EA)),
          boxShadow: selected
              ? [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2)),
          ]
              : null,
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '₹$value',
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF4A4E69),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (selected) const SizedBox(width: 6),
            if (selected)
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Center(
                  child: Icon(Icons.check, size: 10, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _tabItem(String label) {
    final bool isSelected = _selectedCategory == label;

    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2F945A) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFFA4A4B5),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _tabItem("General"),
          _tabItem("Fuel"),
          _tabItem("Meal"),
        ],
      ),
    );
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Top logo
              Center(
                child: Image.asset(
                  'assets/coto_logo_top.png',
                  height: 48,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 12),

              // Description text
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6.0),
                child: Text(
                  'Our Trial Version gives you access to our UPI Expense Voucher for 30 days. If you like what you see, we assist you to get onboarded post trial!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    height: 1.4,
                    color: Color(0xFF86889B),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Section title
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Enter your details to receive UPI Voucher',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    height: 1.4,
                    color: Color(0xFF4A4E69),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Name field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  floatingLabelBehavior: FloatingLabelBehavior.auto,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),

              // Mobile field
              TextFormField(
                controller: _mobileController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Mobile Number',
                  floatingLabelBehavior: FloatingLabelBehavior.auto,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 18),

              // Category tabs (General / Fuel / Meal) - default Meal
              _buildCategoryTabs(),
              const SizedBox(height: 16),

              // Image card (back frame)
              Container(
                width: double.infinity,
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: const DecorationImage(
                    image: AssetImage('assets/img_back_fram.png'),
                    fit: BoxFit.cover,
                  ),
                ),
                margin: const EdgeInsets.only(bottom: 18),
              ),

              // Select Amount title
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Select Amount for Product Trial',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    height: 1.4,
                    color: Color(0xFF4A4E69),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Amount chips row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _amountChip(5),
                  _amountChip(10),
                  _amountChip(25),
                  _amountChip(50),
                ],
              ),

              const SizedBox(height: 28),

              // Issue Voucher button
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                    onPressed: _isFormValid
                        ? () {
                      // open OTP dialog and wait for result (true = authenticated)
                      showDialog<bool>(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => OTPDialog(phoneLast: _mobileController.text.trim().replaceAll(RegExp(r'.(?=.{4})'), 'x')),
                      ).then((authenticated) {
                        if (authenticated == true) {
                          // proceed with voucher issuance
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Voucher issued for ₹$_selectedAmount')),
                          );
                        }
                      });
                    }
                        : null,


                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFormValid ? const Color(0xFF367AFF) : const Color(0xFFEBF2FF),
                    disabledBackgroundColor: const Color(0xFFEBF2FF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  child: Text(
                    'ISSUE VOUCHER',
                    style: TextStyle(
                      color: _isFormValid ? Colors.white : const Color(0xFFA3C2FF),
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class OTPDialog extends StatefulWidget {
  final String phoneLast; // e.g. xx405

  const OTPDialog({Key? key, required this.phoneLast}) : super(key: key);

  @override
  State<OTPDialog> createState() => _OTPDialogState();
}

class _OTPDialogState extends State<OTPDialog> {
  final int _digits = 6;
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  int _secondsLeft = 30;
  Timer? _timer;
  bool _resendAllowed = false;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_digits, (_) => TextEditingController());
    _focusNodes = List.generate(_digits, (_) => FocusNode());
    _startTimer();
    // autofocus first
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _secondsLeft = 30;
      _resendAllowed = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() => _resendAllowed = true);
      } else {
        setState(() => _secondsLeft -= 1);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  bool get _allFilled => _controllers.every((c) => c.text.trim().isNotEmpty);

  String get _otp => _controllers.map((c) => c.text).join();

  void _onChanged(int i, String value) {
    if (value.isEmpty) {
      // if user deleted, move focus back
      if (i > 0) _focusNodes[i - 1].requestFocus();
    } else {
      // move to next
      if (i + 1 < _digits) {
        _focusNodes[i + 1].requestFocus();
      } else {
        _focusNodes[i].unfocus();
      }
    }
    setState(() {});
  }

  void _resend() {
    // call resend api here
    _startTimer();
    // optionally clear fields
    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes[0].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // close button top-right
            Align(
              alignment: Alignment.topRight,
              child: InkWell(
                onTap: () => Navigator.of(context).pop(false),
                child: const Icon(Icons.close, size: 22),
              ),
            ),

            const SizedBox(height: 4),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Authentication for Issuance',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: RichText(
                text: TextSpan(
                  text: 'OTP code has been sent to your phone ',
                  style: const TextStyle(color: Color(0xFF9EA0AB)),
                  children: [
                    TextSpan(
                      text: widget.phoneLast,
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            // OTP inputs row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(_digits, (i) {
                return SizedBox(
                  width: 48,
                  height: 48,
                  child: TextField(
                    controller: _controllers[i],
                    focusNode: _focusNodes[i],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      counterText: '',
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE1E3E8)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFBFC6D6)),
                      ),
                      contentPadding: const EdgeInsets.all(8),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (v) => _onChanged(i, v),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                );
              }),
            ),

            const SizedBox(height: 18),

            // timer & resend
            Row(
              children: [
                const Text("Didn't receive the code?"),
                const SizedBox(width: 8),
                _resendAllowed
                    ? InkWell(
                  onTap: _resend,
                  child: const Text('Resend', style: TextStyle(color: Color(0xFF367AFF))),
                )
                    : Text(
                  '00:${_secondsLeft.toString().padLeft(2, '0')}',
                  style: const TextStyle(color: Color(0xFF367AFF)),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Authenticate button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _allFilled
                    ? () {
                  // Validate OTP here (call backend)
                  // For demo, assume success and return true
                  Navigator.of(context).pop(true);
                }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _allFilled ? const Color(0xFF367AFF) : const Color(0xFFEBF2FF),
                  disabledBackgroundColor: const Color(0xFFEBF2FF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  'Authenticate',
                  style: TextStyle(
                    color: _allFilled ? Colors.white : const Color(0xFF4A4E69),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


}
