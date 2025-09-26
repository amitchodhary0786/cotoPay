import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'session_manager.dart';
import 'edit_profile_screen.dart';
import 'app_permissions_screen.dart';
import 'business_benefits_screen.dart';
import 'help_and_support_screen.dart';
import 'about_us_screen.dart';
import 'terms_and_conditions_screen.dart';
import 'package:cotopay/CotoBalanceCard.dart';
import 'api_service.dart'; // make sure this exists and has deleteAccount method

class DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    const double dotRadius = 0.7;
    const double spacing = 10.0;
    for (double i = 0; i < size.width; i += spacing) {
      for (double j = 0; j < size.height; j += spacing) {
        canvas.drawCircle(Offset(i, j), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  String _name = 'Loading...';
  String _mobile = '...';
  String? _email;

  final ApiService _apiService = ApiService();
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userData = await SessionManager.getUserData();
    if (mounted && userData != null) {
      setState(() {
        _name = userData.username ?? 'N/A';
        _mobile = userData.mobile ?? 'N/A';
        _email = userData.email;
      });
    }
  }

  Future<void> _confirmAndDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete your account? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes, Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteAccount();
    }
  }

  Future<void> _deleteAccount() async {
    final userData = await SessionManager.getUserData();

    final user = await SessionManager.getUserData();

    final params = {
      "id": "860",
      "userDetailsId": "2490",
      "employerId": null, // will be null if not present
      "status": "Deactive",
    };

    setState(() => _deleting = true);

    try {
      final response = await _apiService.deleteAccount(params);
      // Save full response JSON in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('delete_account_response', json.encode(response));

      if (response['status'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Account deleted successfully')),
          );
          // Clear stored session/user data

          // Navigate to app root (or login) - adjust as per your routing
       //   if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
            if (mounted) { await SessionManager.logout(context);}}

      } else {
        final msg = response['message']?.toString() ?? 'Failed to delete account';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ $msg')),
          );
        }
      }
    } catch (e, st) {
      debugPrint('Error deleting account: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting account: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Account & Settings', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Profile Card
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Container(height: 94, color: const Color(0xff34A853)),
                  Positioned.fill(child: CustomPaint(painter: DotPatternPainter())),
                  SizedBox(
                    height: 94,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 16.0),
                          child: CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.white,
                            child: Padding(
                              padding: EdgeInsets.all(4.0),
                              child: ClipOval(child: Image(image: AssetImage('assets/avatar.png'))),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _name,
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Phone: $_mobile',
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          padding: const EdgeInsets.only(right: 16.0),
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.edit_outlined, color: Colors.white),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                            );
                            _loadUserData();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_email == null || _email!.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xffE8F0FE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xff1967D2)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text('Please link your email address!', style: TextStyle(color: Color(0xff1967D2), fontWeight: FontWeight.w500)),
                    ),
                    Icon(Icons.arrow_forward, color: Color(0xff1967D2)),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 10),

          // Menu Items
          ListTile(
            leading: const Icon(Icons.work_outline, color: Colors.black87),
            title: const Text('Linked Workplace', style: TextStyle(fontSize: 16)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const BusinessBenefitsScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.vpn_key_outlined, color: Colors.black87),
            title: const Text('App Permissions', style: TextStyle(fontSize: 16)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AppPermissionsScreen()));
            },
          ),

          ListTile(
            leading: const Icon(Icons.vpn_key_outlined, color: Colors.black87),
            title: const Text('Coto Balance', style: TextStyle(fontSize: 16)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const CotoBalanceCard()));
            },
          ),
          const Divider(height: 24, thickness: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.headset_mic_outlined, color: Colors.black87),
            title: const Text('Help and Support', style: TextStyle(fontSize: 16)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpAndSupportScreen()));
            },
          ),
          ListTile(
            leading: const CircleAvatar(
              radius: 14,
              backgroundColor: Colors.black,
              child: Text('C', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            title: const Text('About Us'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutUsScreen()));
            },
          ),
          ListTile(
            leading: const Icon(IconData(0xe1de, fontFamily: 'MaterialIcons'), color: Colors.black87),
            title: const Text('Terms & Conditions', style: TextStyle(fontSize: 16)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const TermsAndConditionsScreen()));
            },
          ),
          const Spacer(),

          // Delete Account text
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: _deleting ? null : _confirmAndDelete,
              child: Text(
                _deleting ? 'Deleting...' : 'Delete Account',
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.only(bottom: 24),
            child: Text('CotoPay v1.1.2  •  Copyright 2025', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
