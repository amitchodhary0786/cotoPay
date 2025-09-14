import 'package:flutter/material.dart';
import 'otp_screen.dart';
import 'api_service.dart';

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

  Future<void> _handleLogin() async {
    if (_isLoading) return;
    FocusScope.of(context).unfocus();
    setState(() { _isLoading = true; });

    try {
      final userData = {
        'userName': "",
        'password1': "", 'password2': "", 'password3': "",
        'password4': "", 'password5': "", 'password6': "",
        'password': "", 'sresult': "", 'otp': "",
        'mobile': _phoneController.text,
        'orderId': "", 'countdown': "",'template':""
      };

      final response = await _apiService.getOtp(userData);


      if (mounted) {
        if (response['status'] == true) {
          final orderId = response['orderId'].toString(); // orderId को स्ट्रिंग में बदलें
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
              content: Text(response['message'] ?? 'An unknown error occurred'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
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
    return GestureDetector(onTap: () => FocusScope.of(context).unfocus(), child: Scaffold(body: SafeArea(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 24.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const SizedBox(height: 40), Image.asset('assets/images/otp_logo.png', width: 99, height: 24, fit: BoxFit.contain), const SizedBox(height: 10), const Text("Let's get started", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)), const SizedBox(height: 8), const Text("Enter your mobile number to login or signup", style: TextStyle(fontSize: 14, color: Colors.grey)), const SizedBox(height: 24), TextField(controller: _phoneController, keyboardType: TextInputType.number, maxLength: 10, decoration: InputDecoration(counterText: '', prefixIcon: Padding(padding: const EdgeInsets.only(left: 12, right: 8), child: Row(mainAxisSize: MainAxisSize.min, children: const [Text('🇮🇳', style: TextStyle(fontSize: 20)), SizedBox(width: 4), Text('+91')],),), hintText: '00000 00000', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),),), const Spacer(), SizedBox(width: double.infinity, height: 46, child: ElevatedButton(onPressed: isValid && !_isLoading ? _handleLogin : null, style: ElevatedButton.styleFrom(backgroundColor: isValid ? const Color(0xFF367AFF) : const Color(0xFFEAF1FF), foregroundColor: isValid ? Colors.white : Colors.blue.shade200, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),), child: _isLoading ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) : const Text('CONTINUE', style: TextStyle(letterSpacing: 0.5, fontSize: 16, fontWeight: FontWeight.w500)),),), const SizedBox(height: 24) ],),),),),);
  }
}