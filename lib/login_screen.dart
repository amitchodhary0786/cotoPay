import 'package:flutter/material.dart';
import 'otp_screen.dart';
import 'api_service.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  bool isValid = false;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(() {
      final phone = _phoneController.text.replaceAll(' ', '');
      setState(() {
        isValid = phone.length == 10;
      });
    });
  }

  // ----------------------
  // QR Scan method
  // ----------------------

  Future<void> _scanQRCode() async {
    // Show scanner dialog and wait for returned scanned string
    final String? rawValue = await showDialog<String?>(
      context: context,
      builder: (context) {
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(null),
            ),
            title: const Text('Scan QR'),
            centerTitle: true,
          ),
          body: MobileScanner(
            // onDetect expects a single BarcodeCapture parameter
            onDetect: (BarcodeCapture capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final String? code = barcodes.first.rawValue;
                if (code != null && code.isNotEmpty) {
                  // Return the scanned code and close the dialog
                  Navigator.of(context).pop(code);
                }
              }
            },
          ),
        );
      },
    );

    if (rawValue != null && rawValue.isNotEmpty) {
      final RegExp mobileRegex = RegExp(r'Mobile[:\s]*([0-9]{6,15})', caseSensitive: false);
      final match = mobileRegex.firstMatch(rawValue);

      if (match != null && match.groupCount >= 1) {
        final extractedMobile = match.group(1)!.trim();
        setState(() {
          _phoneController.text = extractedMobile;
        });

        await getCheckReg();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('QR se mobile number parse nahi hua.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleLogin() async {
    if (_isLoading) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
    });

    try {
      final userData = {
        'userName': "",
        'password1': "",
        'password2': "",
        'password3': "",
        'password4': "",
        'password5': "",
        'password6': "",
        'password': "",
        'sresult': "",
        'otp': "",
        'mobile': _phoneController.text,
        'orderId': "",
        'countdown': "",
        'template': ""
      };

      final response = await _apiService.getOtp(userData);

      if (mounted) {
        if (response['status'] == true) {
          final orderId = response['orderId'].toString();
          final txnId = response['txnId'];

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtpScreen(
                phoneNumber: _phoneController.text,
                orderId: orderId,
                txnId: txnId,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
              Text(response['message'] ?? 'An unknown error occurred'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Error: ${e.toString().replaceAll("Exception: ", "")}'),
            backgroundColor: Colors.red,
          ),
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

  // ----------------------
  // getCheckReg updated to use _phoneController.text
  // ----------------------
  Future<void> getCheckReg() async {
    if (_isLoading) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
    });

    try {
      final userData = {
        // pass mobile from controller (this was the requested change)
        'mobile': _phoneController.text,
      };

      final response = await _apiService.getCheckRegistration(userData);

      if (mounted) {
        if (response['status'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                Text(response['message'] ?? 'An unknown error occurred'),
                backgroundColor: Colors.red,
              )
          );
        }
        else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
              Text(response['message'] ?? 'An unknown error occurred'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Error: ${e.toString().replaceAll("Exception: ", "")}'),
            backgroundColor: Colors.red,
          ),
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

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white, // ✅ White background
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                // ---------- Modified top row: logo (left) + QR icon (right) ----------
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/otp_logo.png',
                      width: 99,
                      height: 24,
                      fit: BoxFit.contain,
                    ),
                    const Spacer(),
                    // QR IconButton (no design changes to main layout)
                    IconButton(
                      tooltip: 'Scan QR',
                      onPressed: _scanQRCode,
                      icon: const Icon(Icons.qr_code_scanner),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // ✅ Title
                const Text(
                  "Let's get started",
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    height: 1.4,
                    letterSpacing: 0.0,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(height: 8),

                // ✅ Subtitle
                const Text(
                  "Enter your mobile number to login or signup",
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    height: 1.4,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 24),

                // ✅ Phone field
                SizedBox(
                  width: 363,
                  height: 44,
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.number,
                    maxLength: 10,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      height: 1.4,
                      color: Colors.black,
                    ),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      counterText: '',
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 16, right: 10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/India.png', // ✅ Correct path
                              width: 24,
                              height: 24,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              '+91',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w400,
                                fontSize: 18,
                                height: 1.4,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 0,
                        minHeight: 0,
                      ),
                      hintText: '00000 00000',
                      hintStyle: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        height: 1.4,
                        color: Color(0xFFBDBDBD),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xFFCCCCCC), // light gray border
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xFF367AFF), // blue border when active
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // ✅ Continue Button
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: isValid && !_isLoading ? _handleLogin : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isValid
                          ? const Color(0xFF367AFF) // active color
                          : const Color(0xFFEBF2FF), // inactive color
                      foregroundColor:
                      isValid ? Colors.white : Colors.blue.shade200,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 24,
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                        : const Text(
                      'CONTINUE',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        height: 1.4,
                        letterSpacing: 0.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
