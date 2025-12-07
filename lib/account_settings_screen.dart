import 'dart:convert';

import 'package:cotopay/add_user_vechle_screen.dart';
import 'package:cotopay/experince_voucher_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
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
        content: const Text(
            'Are you sure you want to delete your account? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child:
                const Text('Yes, Delete', style: TextStyle(color: Colors.red)),
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
          if (mounted) {
            await SessionManager.logout(context);
          }
        }
      } else {
        final msg =
            response['message']?.toString() ?? 'Failed to delete account';
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
        title: const Text('Account & Settings',
            style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),



// put this inside your Scaffold: body: <paste this widget>
      body: SingleChildScrollView(
        child: Column(
          children: [


            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // ------------------ PROFILE CARD -------------------
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: SizedBox(
                      height: 162,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // background
                          SvgPicture.asset(
                            'assets/profile_card.svg',
                            fit: BoxFit.cover,
                          ),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // LEFT: avatar above name & phone
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // avatar (top)
                                    CircleAvatar(
                                      radius: 32,
                                      backgroundColor: Colors.white,
                                      child: Padding(
                                        padding: const EdgeInsets.all(4.0),
                                        child: ClipOval(
                                          child: Image.asset('assets/avatar.png', fit: BoxFit.cover),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 12),

                                    // name (below avatar)
                                    SizedBox(
                                   //   width: 200, // limit width so long names wrap/ellipsis sensibly
                                      child: Text(
                                        _name,
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w600, // Semi Bold (600)
                                          fontSize: 16.0,
                                          height: 1.4, // 140%
                                          letterSpacing: 0.0,
                                          color: Colors.white,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),

                                    ),

                                    const SizedBox(height: 6),

                                    // phone (below name)
                                    Text(
                                      'Phone: $_mobile',
                                      style: const TextStyle(
                                        fontFamily: 'Open Sans',
                                        fontWeight: FontWeight.w400, // Regular
                                        fontSize: 13.0,
                                        height: 1.4,                 // 140%
                                        letterSpacing: 0.0,
                                        color: Color(0xFFBFDECC),    // #BFDECC
                                      ),
                                    ),

                                  ],
                                ),

                                // push edit icon to right
                                const Spacer(),

                                // EDIT ICON TOP RIGHT
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0, right: 4.0),
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: SvgPicture.asset(
                                      'assets/edit.svg',
                                      width: 24,
                                      height: 24,

                                    ),                                    onPressed: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                                      );
                                      _loadUserData();
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ------------------ EMAIL PROMPT -------------------
                  if (_email == null || _email!.isEmpty)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: -45,
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xffE8F0FE),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              child: const Center(
                                  child: Icon(Icons.info_outline, color: Color(0xff1967D2), size: 20)),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Please link your email address!',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                  color: Color(0xff1967D2),
                                ),
                              ),
                            ),
                            SvgPicture.asset(
                              'assets/arro_side.svg',
                              width: 20,
                              height: 20,
                              colorFilter: const ColorFilter.mode(Color(0xff1967D2), BlendMode.srcIn),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),


            const SizedBox(height: 30), // space below overlapping prompt



            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: Column(
                children: [
                  ListTile(
                    tileColor: Colors.white,
                    leading: SvgPicture.asset('assets/link_side.svg', width: 24, height: 24),
                    title: const Text(
                      'Linked Workplace',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        height: 1.4,
                        color: Color(0xFF0A0A0A),
                      ),
                    ),
                    trailing: SvgPicture.asset('assets/arro_side.svg', width: 24, height: 24),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const BusinessBenefitsScreen()));
                    },
                  ),

                  ListTile(
                    tileColor: Colors.white,
                    leading: SvgPicture.asset('assets/key.svg', width: 24, height: 24),
                    title: const Text(
                      'App Permissions',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        height: 1.4,
                        color: Color(0xFF0A0A0A),
                      ),
                    ),
                    trailing: SvgPicture.asset('assets/arro_side.svg', width: 24, height: 24),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const AppPermissionsScreen()));
                    },
                  ),

                  ListTile(
                    tileColor: Colors.white,
                    leading: SvgPicture.asset('assets/key.svg', width: 24, height: 24),
                    title: const Text(
                      'Coto Balance',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        height: 1.4,
                        color: Color(0xFF0A0A0A),
                      ),
                    ),
                    trailing: SvgPicture.asset('assets/arro_side.svg', width: 24, height: 24),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const CotoBalanceCard()));
                    },
                  ),

                  ListTile(
                    tileColor: Colors.white,
                    leading: Image.asset('assets/magic_icon.png', width: 24, height: 24),
                    title: const Text(
                      'Experience a UPI Voucher',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        height: 1.4,
                        color: Color(0xFF0A0A0A),
                      ),
                    ),
                    trailing: SvgPicture.asset('assets/arro_side.svg', width: 24, height: 24),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ExperienceUpiVoucherScreen()));
                    },
                  ),

                  const Divider(height: 24, thickness: 1, indent: 16, endIndent: 16, color: Color(0xFFF1F1F1)),

                  ListTile(
                    leading: const Icon(Icons.add, color: Color(0xFF0A0A0A)),
                    title: const Text(
                      'Add Users & Vehicles',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        height: 1.4,
                        color: Color(0xFF0A0A0A),
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 56,
                          height: 21,
                          padding: const EdgeInsets.fromLTRB(7, 2, 10, 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFC500),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Center(
                            child: Text(
                              'Admin',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w400,
                                fontSize: 12,
                                height: 1.4,
                                color: Color(0xFF1F212C),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 80),
                        SvgPicture.asset('assets/arro_side.svg', width: 20, height: 20, colorFilter: const ColorFilter.mode(Color(0xFF8A8A8A), BlendMode.srcIn)),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const AddUsersVehiclesScreen()));
                    },
                  ),

                  ListTile(
                    leading: const Icon(Icons.headset_mic_outlined, color: Color(0xFF0A0A0A)),
                    title: const Text(
                      'Help and Support',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        height: 1.4,
                        color: Color(0xFF0A0A0A),
                      ),
                    ),
                    trailing: SvgPicture.asset('assets/arro_side.svg', width: 24, height: 24),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpAndSupportScreen()));
                    },
                  ),

                  ListTile(
                    tileColor: Colors.white,
                    leading: SvgPicture.asset('assets/about.svg', width: 24, height: 24),
                    title: const Text(
                      'About Us',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        height: 1.4,
                        color: Color(0xFF0A0A0A),
                      ),
                    ),
                    trailing: SvgPicture.asset('assets/arro_side.svg', width: 24, height: 24),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutUsScreen()));
                    },
                  ),

                  ListTile(
                    tileColor: Colors.white,
                    leading: SvgPicture.asset('assets/terms.svg', width: 24, height: 24),
                    title: const Text(
                      'Terms & Conditions',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        height: 1.4,
                        color: Color(0xFF0A0A0A),
                      ),
                    ),
                    trailing: SvgPicture.asset('assets/arro_side.svg', width: 24, height: 24),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const TermsAndConditionsScreen()));
                    },
                  ),

                  const SizedBox(height: 24),

                  const Padding(
                    padding: EdgeInsets.only(bottom: 24),
                    child: Text('CotoPay v1.1.2  •  Copyright 2025', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),





    );
  }
}
