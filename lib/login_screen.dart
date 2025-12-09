import 'package:flutter/material.dart';
import 'otp_screen.dart';
import 'api_service.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // for HapticFeedback

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
      //    _phoneController.text = extractedMobile;
        });

        await getCheckReg(extractedMobile);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('QR code does not contain a valid mobile number.'),
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
  Future<void> getCheckReg(String extractedMobile) async {
    if (_isLoading) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
    });

    try {
      final userData = {
        // pass mobile from controller (this was the requested change)
        'mobile': extractedMobile,
      };

      final response = await _apiService.getCheckRegistration(userData);

      if (mounted) {
        if (response['status'] == true) {
          await showInteractiveDialog(
            context,
            title: 'Alert',
            message: response['message'] ?? 'An unknown error occurred',
            isError: true,
            primaryLabel: 'Okay',
            onPrimary: () {
              // optional extra behavior when OK tapped

            },
            barrierDismissible: true,
          );
        } else {
          // If you were calling showErrorDialog before, you can replace it with interactive dialog:
          await showInteractiveDialog(
            context,
            title: 'Alert',
            message: response['message'] ?? 'An unknown error occurred',
            isError: false,
            primaryLabel: 'Okay',
           // secondaryLabel: 'Okay',
          /*  onPrimary: () {
              // retry logic
            },
            onSecondary: () {
              // secondary action
            },*/
            barrierDismissible: true,
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




  /// Shows an animated, interactive dialog.
  /// Returns true when primary button pressed, false when secondary pressed, null if dismissed.
  Future<bool?> showInteractiveDialog(
      BuildContext context, {
        required String title,
        required String message,
        bool isError = true,
        String primaryLabel = 'OK',
        VoidCallback? onPrimary,
        String? secondaryLabel,
        VoidCallback? onSecondary,
        bool barrierDismissible = false,
        double width = 320,
      }) {
    // small haptic on open
    HapticFeedback.selectionClick();

    return showGeneralDialog<bool?>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: 'Dialog',
      transitionDuration: const Duration(milliseconds: 360),
      pageBuilder: (ctx, anim1, anim2) {
        // pageBuilder must return widget, but the actual animation is in transitionBuilder
        return const SizedBox.shrink();
      },
      transitionBuilder: (ctx, animation, secondaryAnimation, child) {
        // scale + fade with a slight overshoot
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: curved,
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: width,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  decoration: BoxDecoration(
                    color: Theme.of(context).dialogBackgroundColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // top icon
                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: isError ? Colors.red.shade50 : Colors.green.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isError ? Icons.error_outline : Icons.check_circle_outline,
                              color: isError ? Colors.red : Colors.green,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: isError ? Colors.red.shade700 : Colors.green.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // message
                      Text(
                        message,
                        style: const TextStyle(fontSize: 14.5, height: 1.4, color: Colors.black87),
                      ),

                      const SizedBox(height: 18),

                      // actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (secondaryLabel != null)
                            TextButton(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                Navigator.of(context).pop(false);
                                if (onSecondary != null) onSecondary();
                              },
                              child: Text(
                                secondaryLabel,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          const SizedBox(width: 6),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                              backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
                            ),
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              Navigator.of(context).pop(true);
                              if (onPrimary != null) onPrimary();
                            },
                            child: Text(
                              primaryLabel,
                              style: const TextStyle(fontWeight: FontWeight.w700,color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }


  Future<void> showErrorDialog(BuildContext context, String message) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 8),
              Text('Error', style: TextStyle(color: Colors.red)),
            ],
          ),
          content: Text(message, style: const TextStyle(color: Colors.black87)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
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
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                      if (states.contains(MaterialState.disabled)) {
                        return const Color(0xFFEBF2FF); // Inactive background
                      }
                      return const Color(0xFF367AFF);   // Active background
                    }),
                    foregroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                      if (states.contains(MaterialState.disabled)) {
                        return const Color(0xFFA3C2FF); // Inactive text
                      }
                      return Colors.white;              // Active text
                    }),
                    shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    padding: MaterialStateProperty.all(
                      const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 24,
                      ),
                    ),
                    elevation: MaterialStateProperty.all(0),
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
