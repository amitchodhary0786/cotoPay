
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'api_service.dart';
import 'session_manager.dart';
import 'your_tickets_screen.dart';

class TicketTransaction {
  final String issueDesc;
  final String responseDate;
  final String createdBy;
  final String name;

  TicketTransaction({
    required this.issueDesc,
    required this.responseDate,
    required this.createdBy,
    required this.name,
  });

  factory TicketTransaction.fromJson(Map<String, dynamic> json) {
    return TicketTransaction(
      issueDesc: json['issueDesc'] ?? 'No message',
      responseDate: json['creationdate'] ?? '',
      createdBy: json['createdby'] ?? '',
      name: json['name'] ?? 'User',
    );
  }
}

class TicketDetails {
  final String ticketNumber;
  final String subject;
  final List<TicketTransaction> transactions;

  TicketDetails({
    required this.ticketNumber,
    required this.subject,
    required this.transactions,
  });

  factory TicketDetails.fromJson(Map<String, dynamic> json) {
    var transList = (json['data'] as List<dynamic>?) ?? [];
    List<TicketTransaction> transactions = transList
        .map((i) => TicketTransaction.fromJson(i))
        .toList();

    return TicketDetails(
      ticketNumber: json['ticketnumber'] ?? 'N/A',
      subject: json['subject'] ?? 'No Subject',
      transactions: transactions,
    );
  }
}

class TicketDetailsScreen extends StatefulWidget {
  final Ticket ticket;

  const TicketDetailsScreen({super.key, required this.ticket});

  @override
  State<TicketDetailsScreen> createState() => _TicketDetailsScreenState();
}

class _TicketDetailsScreenState extends State<TicketDetailsScreen> {
  final ApiService _apiService = ApiService();
  late Future<TicketDetails> _detailsFuture;
  UserData? _currentUser;

  final TextEditingController _messageController = TextEditingController();
  bool _isSendButtonEnabled = false;
  bool _isSending = false;


  @override
  void initState() {
    super.initState();
    _detailsFuture = _loadTicketDetails();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<TicketDetails> _loadTicketDetails() async {
    _currentUser = await SessionManager.getUserData();
    if (_currentUser == null || _currentUser!.employerid == null) {
      throw Exception("User data not found. Please log in again.");
    }

    final response = await _apiService.getAllTicketsDetails(
      orgId: _currentUser!.employerid!,
      id: widget.ticket.id,
    );

    if (response['status'] == true) {
      return TicketDetails.fromJson(response);
    } else {
      throw Exception(response['message'] ?? "Failed to load ticket details");
    }
  }

  Future<void> _submitReply() async {
    if (_messageController.text.trim().isEmpty) return;

    setState(() { _isSending = true; });

    try {
      if (_currentUser?.mobile == null) {
        throw Exception("User data is incomplete.");
      }

      String base64Image = "";
      if (_imageFile != null) {
        final bytes = await _imageFile!.readAsBytes();
        base64Image = base64Encode(bytes);
      }

      // API call to post the comment
      final response = await _apiService.addTicketComment(
        id: widget.ticket.id, // Ticket ki ID
        orgId: _currentUser!.employerid!,
        issueDesc: _messageController.text,
        ticketImg: base64Image, // Attached image (optional)
        createdBy: _currentUser!.mobile!,
         respTicketStatus:  widget.ticket.status,
         respTicketStatusDesc: widget.ticket.statusDesc ,


      );

      final isSuccess = response['status'] ?? false;
      final message = response['message'] ?? 'An error occurred.';

      Fluttertoast.showToast(
        msg: message,
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        textColor: Colors.white,
      );

      if (isSuccess) {
        _messageController.clear();
        setState(() {
          _imageFile = null; // Clear selected image
          _isSendButtonEnabled = false;
          _detailsFuture = _loadTicketDetails(); // Refresh the chat list
        });
      }

    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error: ${e.toString()}",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      if(mounted) {
        setState(() { _isSending = false; });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF0F4F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.ticket.subject, // Dynamic subject
              style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              'Ticket ID:${widget.ticket.ticketNumber+", ${widget.ticket.creationDate}"}', // Dynamic ID
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildChatInputField(),
      body: FutureBuilder<TicketDetails>(
        future: _detailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.hasData) {
            final details = snapshot.data!;
            if (details.transactions.isEmpty) {
              return const Center(child: Text("No conversation yet."));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: details.transactions.length,
              itemBuilder: (context, index) {
                final transaction = details.transactions[index];
                bool isSender = _currentUser?.mobile == transaction.createdBy;
                return _buildChatMessage(
                  text: transaction.issueDesc,
                  time: transaction.responseDate,
                  isSender: isSender,
                );
              },
            );
          }
          return const Center(child: Text("Something went wrong."));
        },
      ),
    );
  }

  Widget _buildChatInputField() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        color: Colors.white,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.attach_file, color: Colors.grey),
              onPressed: _isSending ? null : _showPictureUpdateSheet,
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                onChanged: (text) {
                  final isNotEmpty = text.trim().isNotEmpty;
                  if (_isSendButtonEnabled != isNotEmpty) {
                    setState(() {
                      _isSendButtonEnabled = isNotEmpty;
                    });
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Ask Anything',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            // MODIFIED: Added loading indicator
            _isSending
                ? const Padding(
              padding: EdgeInsets.all(8.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
                : IconButton(
              icon: const Icon(Icons.send),
              // MODIFIED: Call _submitReply on press and handle disabled state
              onPressed: _isSendButtonEnabled ? _submitReply : null,
              color: _isSendButtonEnabled
                  ? Theme.of(context).primaryColor
                  : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  String _formatChatTimestamp(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      DateTime dateTime = DateTime.parse(dateStr);
      return DateFormat('E, dd/MM H:mm').format(dateTime);
    } catch (e) {
      return dateStr;
    }
  }


  Widget _buildChatMessage({required String text, required String time, required bool isSender}) {
    final alignment = isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final color = isSender ? const Color(0xffE6F4EA) : Colors.white;
    final margin = isSender
        ? const EdgeInsets.only(left: 60, bottom: 4)
        : const EdgeInsets.only(right: 60, bottom: 4);

    return Column(
      crossAxisAlignment: alignment,
      children: [
        Container(
          margin: margin,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(text, style: const TextStyle(fontSize: 14)),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(isSender ? 0 : 8, 4, isSender ? 8 : 0, 16),
          child: Text(
              _formatChatTimestamp(time),
              style: const TextStyle(color: Colors.grey, fontSize: 10)
          ),
        ),
      ],
    );
  }

  // File picking logic, ismein koi badlav nahi
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  void _showPictureUpdateSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'ATTACHMENT',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                  letterSpacing: 0.8,
                ),
              ),
              const Divider(height: 24),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from library'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take photo'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Image selected: ${pickedFile.name}'),
              duration: const Duration(seconds: 1),
            ),
          );
        });
      }
    } catch (e) {
      debugPrint("Image picking error: $e");
    }
  }
}