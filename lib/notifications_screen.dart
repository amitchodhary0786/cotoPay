import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int _selectedChipIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'All Notifications',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold,fontSize: 16),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          Expanded(child: _buildNotificationsList()),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          _buildChip('All', 0),
          const SizedBox(width: 8),
          _buildChip('Unread (1)', 1),
          const Spacer(),
          TextButton(
            onPressed: () {
              // Mark all as read logic
            },
            child: const Text(
              'Mark all as read',
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildChip(String label, int index) {
    final bool isSelected = _selectedChipIndex == index;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) {
          setState(() {
            _selectedChipIndex = index;
          });
        }
      },
      backgroundColor: Colors.grey.shade100,
      selectedColor: Colors.blue.withOpacity(0.1),
      labelStyle: TextStyle(
        color: isSelected ? Colors.blue.shade700 : Colors.black54,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? Colors.blue.shade700 : Colors.grey.shade300,
        ),
      ),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
    );
  }

  Widget _buildNotificationsList() {
    // Dummy data based on the image
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      children: [
        _buildDateHeader('Yesterday'),
        _buildNotificationItem(
          isUnread: true,
          title: 'Notification 1',
          subtitle: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
          date: 'July 7',
          gradient: const LinearGradient(
            colors: [Color(0xFF4285F4), Color(0xFFF4B400)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        _buildDateHeader('Older'),
        _buildNotificationItem(
          title: 'Notification 2',
          subtitle: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
          date: 'Jun 30',
          gradient: const LinearGradient(
            colors: [Color(0xFFA98AFF), Color(0xFF8AFFFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        _buildNotificationItem(
          title: 'Notification 3',
          subtitle: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
          date: 'Jun 27',
          gradient: const LinearGradient(
            colors: [Color(0xFFFF8A8A), Color(0xFFF4B400)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ],
    );
  }

  Widget _buildDateHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.grey,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildNotificationItem({
    required String title,
    required String subtitle,
    required String date,
    required Gradient gradient,
    bool isUnread = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: gradient,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            children: [
              Text(
                date,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              if (isUnread) ...[
                const SizedBox(width: 4),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}