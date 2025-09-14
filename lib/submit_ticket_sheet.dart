
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show Uint8List;
import 'package:fluttertoast/fluttertoast.dart';

import 'api_service.dart';
import 'session_manager.dart';

class SubmitTicketSheet extends StatefulWidget {
  final VoidCallback onSuccess;
  const SubmitTicketSheet({super.key, required this.onSuccess});

  @override
  State<SubmitTicketSheet> createState() => _SubmitTicketSheetState();
}

class _SubmitTicketSheetState extends State<SubmitTicketSheet> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  final ApiService _apiService = ApiService();

  Uint8List? _pickedFileBytes;
  String? _pickedFileName;
  bool _isLoading = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _pickedFileBytes = result.files.single.bytes;
        _pickedFileName = result.files.single.name;
      });
    }
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() { _isLoading = true; });

    try {
      final userData = await SessionManager.getUserData();
      if (userData?.employerid == null || userData?.mobile == null) {
        throw Exception("User data not found. Please log in again.");
      }

      String base64Image = "";
      if (_pickedFileBytes != null) {
        base64Image = base64Encode(_pickedFileBytes!);
      }

      final response = await _apiService.addTicket(
        orgId: userData!.employerid!,
        subject: _subjectController.text,
        issueDesc: _messageController.text,
        createdBy: userData.mobile!,
        ticketImg: base64Image,
      );

      debugPrint("Full API Response: $response");

      if (!mounted) return;

      final bool isSuccess = response['status'] ?? false;
      final String message = response['message'] ?? (isSuccess ? 'Ticket created successfully!' : 'An unknown error occurred.');

      // <<< 2. SNACKBAR KI JAGAH TOAST KA ISTEMAL KAREIN >>>
      Fluttertoast.showToast(
          msg: message, // API se mila message
          toastLength: isSuccess ? Toast.LENGTH_SHORT : Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: isSuccess ? Colors.green : Colors.red, // status ke hisaab se color
          textColor: Colors.white,
          fontSize: 16.0
      );

      if (isSuccess) {
        Navigator.pop(context); // Bottom sheet band karein
        widget.onSuccess();    // Parent screen ko signal dein
      }

    } catch (e) {
      if (mounted) {
        // Exception ke case mein bhi toast dikhayein
        Fluttertoast.showToast(
            msg: "An error occurred: ${e.toString()}",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Baaki ka UI code waisa hi rahega
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Submit Ticket', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _subjectController,
                decoration: InputDecoration(hintText: 'Subject', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                validator: (value) => value == null || value.trim().isEmpty ? 'Subject is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _messageController,
                decoration: InputDecoration(hintText: 'Message', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                maxLines: 4,
                validator: (value) => value == null || value.trim().isEmpty ? 'Message is required' : null,
              ),
              const SizedBox(height: 16),
              const Text('Attach File', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: Row(
                  children: [
                    ElevatedButton(
                      onPressed: _pickFile,
                      child: const Text('Choose file'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade200,
                        foregroundColor: Colors.black87,
                        elevation: 0,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _pickedFileName ?? 'No file chosen',
                        style: const TextStyle(color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitTicket,
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Submit Ticket', style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}