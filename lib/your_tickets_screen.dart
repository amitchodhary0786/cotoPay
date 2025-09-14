import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'api_service.dart';
import 'session_manager.dart';
import 'submit_ticket_sheet.dart';
import 'ticket_details_screen.dart';

class Ticket {
  final int id;
  final String ticketNumber;
  final String subject;
  final String issueDesc;
  final int status;
  final String statusDesc;
  final String creationDate;

  Ticket({
    required this.id,
    required this.ticketNumber,
    required this.subject,
    required this.issueDesc,
    required this.status,
    required this.statusDesc,
    required this.creationDate,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    int statusValue = -1;
    if (json['status'] != null) {
      if (json['status'] is int) {
        statusValue = json['status'];
      } else if (json['status'] is String) {
        statusValue = int.tryParse(json['status'].toString()) ?? -1;
      }
    }

    return Ticket(
      id: json['id'] ?? 0,
      ticketNumber: json['ticketnumber'] ?? 'N/A',
      subject: json['subject'] ?? 'No Subject',
      issueDesc: json['issueDesc'] ?? 'No Description',
      status: statusValue, // Behtar parse ki hui value use karein
      statusDesc: json['statusDesc'] ?? 'Unknown',
      creationDate: json['creationdate'] ?? '',
    );
  }
}


class YourTicketsScreen extends StatefulWidget {
  const YourTicketsScreen({super.key});

  @override
  State<YourTicketsScreen> createState() => _YourTicketsScreenState();
}

class _YourTicketsScreenState extends State<YourTicketsScreen> {
  late Future<List<Ticket>> _ticketsFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _ticketsFuture = _loadTickets();
  }

  void _refreshTicketList() {
    setState(() {
      _ticketsFuture = _loadTickets();
    });
  }

  Future<List<Ticket>> _loadTickets() async {
    final userData = await SessionManager.getUserData();
    if (userData != null && userData.employerid != null) {
      return _fetchTicketsFromApi(userData.employerid!);
    } else {
      throw Exception('User not logged in or employer ID is missing.');
    }
  }

  Future<List<Ticket>> _fetchTicketsFromApi(int orgId) async {
    try {
      final response = await _apiService.getAllTickets(orgId: orgId);
      if (response['status'] == true &&
          response['data'] != null &&
          response['data'] is List) {
        final List<dynamic> ticketData = response['data'];
        return ticketData.map((json) => Ticket.fromJson(json)).toList();
      } else {
        throw Exception(
            response['message'] ?? 'Failed to load tickets');
      }
    } catch (e) {
      throw Exception('Failed to fetch tickets: ${e.toString()}');
    }
  }

  void _showCreateTicketSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) => SubmitTicketSheet(
        onSuccess: _refreshTicketList,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: -8,
        title: const Text(
          'Your Tickets',
          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.blue, size: 30),
            onPressed: _showCreateTicketSheet,
          ),
        ],
      ),
      body: FutureBuilder<List<Ticket>>(
        future: _ticketsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            final errorMessage =
            snapshot.error.toString().replaceFirst('Exception: ', '');
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error: $errorMessage', textAlign: TextAlign.center),
              ),
            );
          } else if (snapshot.hasData) {
            final tickets = snapshot.data!;
            return tickets.isEmpty
                ? _buildNullState()
                : _buildGroupedTicketsList(tickets);
          }
          return _buildNullState();
        },
      ),
    );
  }

  // --- WIDGETS ---

  // --- UPDATED GROUPING WIDGET ---
  Widget _buildGroupedTicketsList(List<Ticket> tickets) {
    final resolvedTickets =
    tickets.where((t) => t.status == 2 || t.status == 4).toList();

    final recentTickets =
    tickets.where((t) => t.status != 2 && t.status != 4).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      children: [
        if (recentTickets.isNotEmpty) _buildSectionHeader('RECENT TICKETS'),
        ...recentTickets.map((ticket) => _buildTicketCard(ticket: ticket)),

        if (resolvedTickets.isNotEmpty) const SizedBox(height: 16),
        if (resolvedTickets.isNotEmpty) _buildSectionHeader('RESOLVED'),
        ...resolvedTickets.map((ticket) => _buildTicketCard(ticket: ticket)),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, top: 8, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.bold,
            fontSize: 12),
      ),
    );
  }

  Widget _buildNullState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.forum_outlined, size: 60, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text('No Support Tickets exist!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showCreateTicketSheet,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Create Ticket'),
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: const Color(0xffE8F0FE),
              foregroundColor: Colors.blue.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return 'N/A';
    try {
      DateTime dateTime = DateTime.parse(dateStr);
      return DateFormat('d MMM').format(dateTime);
    } catch (e) {
      return dateStr.split('T').first;
    }
  }

  Widget _buildStatusChip(Ticket ticket) {
    Color backgroundColor;
    Color textColor;
    String statusText = ticket.statusDesc;





    switch (ticket.status) {
      case 0: // Submitted
      case 3: // In Progress
      case 4: // Pending
      case 1: // Hold
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        break;

      case 2: // Close
        statusText = 'Closed';
        backgroundColor = Colors.grey.shade200;
        textColor = Colors.grey.shade600;
        break;

      default:
        backgroundColor = Colors.grey.shade200;
        textColor = Colors.grey.shade600;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        statusText,
        style: TextStyle(
            color: textColor, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
  Widget _buildTicketCard({required Ticket ticket}) {
    final bool isTerminalState = ticket.status == 2 || ticket.status == 4;

    final Color bottomBackgroundColor =
    isTerminalState ? Colors.grey.shade100 : const Color(0xFFEFF4FF);

    final String bottomText = isTerminalState ? 'Resolved' : ticket.issueDesc;

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1.0),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isTerminalState
              ? null
              : () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TicketDetailsScreen(ticket: ticket),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ticket.subject,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isTerminalState ? Colors.grey.shade700 : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${_formatDate(ticket.creationDate)}, Ticket ID:${ticket.ticketNumber}',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusChip(ticket),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: bottomBackgroundColor, // Dynamic color
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Text(
                  bottomText, // Dynamic text
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade800,
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