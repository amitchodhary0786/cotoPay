
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'session_manager.dart';
import 'api_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  final ApiService _apiService = ApiService();
  bool _isUpdating = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String _mobile = '...';
  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  @override
  void dispose() { _nameController.dispose(); _emailController.dispose(); super.dispose(); }

  Future<void> _loadUserData() async {
    final userData = await SessionManager.getUserData();
    if (mounted && userData != null) {
      setState(() {
        _nameController.text = userData.username ?? '';
        _emailController.text = userData.email ?? '';
        _mobile = userData.mobile ?? 'N/A';
        _userId = userData.id;
      });
    }
  }

  Future<void> _handleProfileUpdate() async
  {
    if (!mounted) return;
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User ID not found.'), backgroundColor: Colors.red));
      return;
    }

    setState(() { _isUpdating = true; });

    try {
      String? base64Image;
      if (_imageFile != null)
      {
        base64Image = base64Encode(await _imageFile!.readAsBytes());
      }
      String formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

      final Map<String, dynamic> profileData = {
        "name": _nameController.text.trim(), "email": _emailController.text.trim(),
        "username": _nameController.text.trim(), "creationdate": formattedDate, "empPhoto": base64Image ?? ""
      };

      final response = await _apiService.updateUserProfile(userId: _userId!, profileData: profileData);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'] ?? 'Status received.'), backgroundColor: (response['status'] == true) ? Colors.green : Colors.red));

      if (response['status'] == true)
      {
        final currentUserData = await SessionManager.getUserData();
        if (currentUserData != null) {
          final updatedJson = {
            ...currentUserData.toJson(),
            'username': _nameController.text.trim(),
            'email': _emailController.text.trim(),
          };
          UserData updatedData = UserData.fromJson(updatedJson);

          await SessionManager.updateUserData(updatedData);
          debugPrint("SharedPreferences updated successfully with new data.");
        }
      }
    } catch (e)
    {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red));
    } finally {
      if (mounted) { setState(() { _isUpdating = false; }); }
    }
  }

  void _showPictureUpdateSheet() { /* ... */ showModalBottomSheet( context: context, shape: const RoundedRectangleBorder( borderRadius: BorderRadius.vertical(top: Radius.circular(20)), ), builder: (context) { return Container( padding: const EdgeInsets.all(16.0), child: Column( mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [ Center( child: Container( width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)), ), ), const SizedBox(height: 16), const Text('PICTURE UPDATE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, letterSpacing: 0.8)), const Divider(height: 24), ListTile( leading: const Icon(Icons.photo_library_outlined), title: const Text('Choose from library'), onTap: () { _pickImage(ImageSource.gallery); Navigator.of(context).pop(); }, ), ListTile( leading: const Icon(Icons.camera_alt_outlined), title: const Text('Take photo'), onTap: () { _pickImage(ImageSource.camera); Navigator.of(context).pop(); }, ), const SizedBox(height: 16), ], ), ); }, ); }
  Future<void> _pickImage(ImageSource source) async { /* ... */ try { final pickedFile = await _picker.pickImage(source: source); if (pickedFile != null) { setState(() { _imageFile = File(pickedFile.path); }); } } catch (e) { debugPrint("Image picking error: $e"); } }
  @override
  Widget build(BuildContext context) { return Scaffold( backgroundColor: Colors.white, appBar: AppBar( backgroundColor: Colors.white, elevation: 0, leading: IconButton( icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20), onPressed: () => Navigator.of(context).pop(), ), title: const Text('Edit Profile', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)), centerTitle: false, titleSpacing: 0, actions: const [], ), body: Padding( padding: const EdgeInsets.symmetric(horizontal: 24.0), child: Column( children: [ Expanded( child: SingleChildScrollView( child: Column( children: [ const SizedBox(height: 20), CircleAvatar( radius: 42, backgroundColor: const Color(0xffE8F5E9), backgroundImage: _imageFile != null ? FileImage(_imageFile!) as ImageProvider : const AssetImage('assets/avatar.png'), ), const SizedBox(height: 8), TextButton( onPressed: _showPictureUpdateSheet, child: const Text('Edit picture', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600, fontSize: 15)), ), const SizedBox(height: 32), _buildEditableField(label: 'Name', controller: _nameController), const SizedBox(height: 16), _buildDisplayField(label: 'Mobile', value: _mobile, isLocked: true), const SizedBox(height: 16), _buildEditableField(label: 'Email', controller: _emailController, hint: 'Enter personal email'), ], ), ), ), Padding( padding: const EdgeInsets.only(bottom: 16.0), child: SizedBox( width: double.infinity, child: ElevatedButton( onPressed: _isUpdating ? null : _handleProfileUpdate, style: ElevatedButton.styleFrom( backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), ), child: _isUpdating ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('UPDATE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), ), ), ), Padding( padding: const EdgeInsets.only(bottom: 24.0), child: OutlinedButton.icon( onPressed: () async { if (mounted) { await SessionManager.logout(context); } }, icon: const Icon(Icons.logout, color: Colors.red, size: 20), label: const Text('Logout', style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold)), style: OutlinedButton.styleFrom( side: BorderSide(color: Colors.red.withOpacity(0.3), width: 1.2), padding: const EdgeInsets.symmetric(vertical: 14), minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), ), ), ), ], ), ), ); }
  Widget _buildEditableField({required String label, required TextEditingController controller, String hint = ''}) { return Column( crossAxisAlignment: CrossAxisAlignment.start, children: [ Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)), const SizedBox(height: 8), TextFormField( controller: controller, decoration: InputDecoration( hintText: hint, hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 16), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.blue)), ), ), ], ); }
  Widget _buildDisplayField({required String label, required String value, bool isLocked = false}) { return Column( crossAxisAlignment: CrossAxisAlignment.start, children: [ Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)), const SizedBox(height: 8), Container( width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), decoration: BoxDecoration( color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300), ), child: Row( mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [ Text(value, style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w500)), if (isLocked) const Icon(Icons.lock_outline, color: Colors.grey, size: 20), ], ), ), ], ); }
}