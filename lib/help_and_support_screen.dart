import 'package:flutter/material.dart';
import 'session_manager.dart';
import 'your_tickets_screen.dart';
import 'submit_ticket_sheet.dart';

class HelpAndSupportScreen extends StatefulWidget {
  const HelpAndSupportScreen({super.key});

  @override
  State<HelpAndSupportScreen> createState() => _HelpAndSupportScreenState();
}

class _HelpAndSupportScreenState extends State<HelpAndSupportScreen> {
  String _name = '...';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userData = await SessionManager.getUserData();
    if (mounted && userData != null) {
      setState(() {
        _name = userData.username ?? 'User';
      });
    }
  }

  void _onTicketCreatedSuccessfully() {
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const YourTicketsScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Help & Support',
          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        titleSpacing: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.blue, size: 28),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (context) => SubmitTicketSheet(
                  onSuccess: _onTicketCreatedSuccessfully,
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: Text(
                        'Hey $_name! Welcome to CotoPay Care.',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
                      ),
                    ),
                    Container(
                      color: const Color(0xffF1F6FF),
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const YourTicketsScreen()));
                        },
                        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                        child: const Text('View Tickets', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF367AFF))),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Recent Payments section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      // Section Title
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
                        child: Text(
                          'Select a recent payment that you have an issue with or create a new query.',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFF0F0F0)),

                      // Recent Transactions List
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: 4,
                          itemBuilder: (context, index) {
                            final secondaryText = index == 0 ? 'Routmatic' : 'Zenfleet';
                            return _buildTransactionItem(secondaryText);
                          },
                          separatorBuilder: (context, index) {
                            return const Divider(indent: 60, height: 32, thickness: 1);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(String secondaryText) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 24,
          backgroundColor: Color(0xffE8F5E9),
          child: Icon(Icons.receipt_long, color: Color(0xff34A853)),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nagar Fuel & Petroleum', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              SizedBox(height: 2),
              Text('Routmatic', style: TextStyle(color: Color(0xff34A853), fontWeight: FontWeight.w500)),
              SizedBox(height: 2),
              Text('3 July', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
        const Text('₹1,000', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}