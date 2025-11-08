import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'api_service.dart';
import 'session_manager.dart';
import 'home.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  final String orderId;
  final String txnId;

  const OtpScreen({
    super.key,
    required this.phoneNumber,
    required this.orderId,
    required this.txnId,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _otpControllers =
  List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  bool isOtpValid = true;
  bool isButtonEnabled = false;

  Timer? _timer;
  int _start = 60;
  bool _isResendEnabled = false;

  @override
  void initState() {
    super.initState();
    startTimer();
    for (var node in _focusNodes) {
      // make first field focused initially
      if (_focusNodes.indexOf(node) == 0) {
        node.requestFocus();
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var n in _focusNodes) {
      n.dispose();
    }
    super.dispose();
  }

  void startTimer() {
    setState(() {
      _isResendEnabled = false;
      _start = 60; // existing behavior kept
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_start == 0) {
        setState(() {
          _isResendEnabled = true;
        });
        timer.cancel();
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  Future<void> _handleResendOtp() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final resendData = {'mobile': widget.phoneNumber, 'orderId': widget.orderId};
      final response = await _api_service_resend(resendData);
      // Using existing API wrapper — replace with your ApiService.resendOtp if needed
      if (mounted) {
        if (response['status'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(response['message'] ?? 'A new OTP has been sent successfully.'),
              backgroundColor: Colors.green));
          startTimer();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(response['message'] ?? 'Failed to resend OTP.'),
              backgroundColor: Colors.red));
          setState(() {
            _isResendEnabled = true;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // helper: replace with your ApiService.resendOtp call
  Future<Map<String, dynamic>> _api_service_resend(Map<String, dynamic> data) {
    return _apiService.resendOtp(data);
  }

  Future<void> _handleVerifyOtp() async {
    if (_isLoading) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
    });

    final enteredOtp = _otpControllers.map((e) => e.text).join();

    try {
      final otpData = {
        'userName': '91${widget.phoneNumber}',
        'otp': enteredOtp,
        'mobile': widget.phoneNumber,
        'orderId': widget.orderId,
        'template': ""
      };

      final response = await _apiService.verifyOtp(otpData);

      debugPrint("✅ Received Decrypted API Response: $response");

      if (!mounted) return;

      if (response['status'] == true && response['data'] != null) {
        final data = response['data'];

        await SessionManager.saveLoginData(data);

        if (data['role_id'] != null) {
          await SessionManager.saveRoleId(data['role_id']);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP Verified Successfully!'), backgroundColor: Colors.green),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false,
        );
      } else {
        setState(() {
          isOtpValid = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Invalid OTP.'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isOtpValid = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleInput(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    _checkButtonEnable();
  }

  void _handleKey(RawKeyEvent event, int index) {
    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _otpControllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  void _checkButtonEnable() {
    final otp = _otpControllers.map((c) => c.text).join();
    setState(() {
      isButtonEnabled = otp.length == 6;
      if (isButtonEnabled) {
        isOtpValid = true;
      }
    });
  }

  OutlineInputBorder _getBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: isOtpValid ? Colors.grey : Colors.red, width: 1.5),
    );
  }

  OutlineInputBorder _getFocusedBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: isOtpValid ? Colors.blue : Colors.red, width: 1.5),
    );
  }

  String _formattedTimer() {
    final minutes = (_start ~/ 60).toString().padLeft(2, '0');
    final seconds = (_start % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    // central width matching design (350). On narrow screens it will shrink.
    final buttonWidth = 350.0;

    return Scaffold(
      backgroundColor: Colors.white, // as requested
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios),
                  ),
                  const SizedBox(width: 4),
                  Image.asset('assets/images/otp_logo.png', width: 99, height: 24),
                ],
              ),

              const SizedBox(height: 10),

              // Title: Enter OTP (Inter, semi-bold, 18)
              const Text(
                'Enter OTP',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 18, // 18px as requested
                  height: 1.4,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 8),

              // Subtitle: OTP code has been sent...
              Text(
                'OTP code has been sent to your phone +91-xxxxxx${widget.phoneNumber.substring(widget.phoneNumber.length - 4)}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                  height: 1.4,
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 32),

              // OTP inputs
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 48,
                    height: 48,
                    child: RawKeyboardListener(
                      focusNode: FocusNode(),
                      onKey: (event) => _handleKey(event, index),
                      child: TextField(
                        controller: _otpControllers[index],
                        focusNode: _focusNodes[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                          color: Colors.black,
                        ),
                        onChanged: (value) => _handleInput(value, index),
                        decoration: InputDecoration(
                          counterText: '',
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          border: _getBorder(),
                          enabledBorder: _getBorder(),
                          focusedBorder: _getFocusedBorder(),
                        ),
                      ),
                    ),
                  );
                }),
              ),

              if (!isOtpValid)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    'Invalid OTP. Please try again',
                    style: TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),

              const SizedBox(height: 24),

              // Resend row
              Row(
                children: [
                  const Text(
                    "Didn't receive the code?",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                      height: 1.4,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _isResendEnabled
                      ? GestureDetector(
                    onTap: _isLoading ? null : _handleResendOtp,
                    child: Text(
                      'Resend OTP',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        height: 1.4,
                        color: _isLoading ? Colors.grey : Colors.blue,
                      ),
                    ),
                  )
                      : Text(
                    'Resend in ${_formattedTimer()}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                      height: 1.4,
                      color: Color(0xFF367AFF),
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Confirm Button centered with fixed width 350 as requested
              Center(
                child: SizedBox(
                  width: buttonWidth,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: isButtonEnabled && !_isLoading ? _handleVerifyOtp : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      isButtonEnabled ? const Color(0xFF367AFF) : const Color(0xFFEBF2FF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                        : const Text(
                      'CONFIRM',
                      style: TextStyle(
                        fontFamily: 'Open Sans', // Confirm uses Open Sans per your spec
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        height: 1.4,
                        color: Colors.white,
                      ),
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
