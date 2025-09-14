import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LinkWorkplaceScreen extends StatelessWidget {
  const LinkWorkplaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xff212121), // Dark background
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              SizedBox(height: topPadding),
              _buildTopSection(context),
              _buildBottomSection(),
            ],
          ),
          // Overlapping Chip
          Positioned(
            top: topPadding +
                180, // Adjust this value to position the chip correctly
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.center,
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xff34A853), // Green color
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Simplifying Business Expenses with UPI',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Top dark part of the screen
  Widget _buildTopSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 200, // Fixed height for the top section
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios,
                color: Colors.white, size: 16),
            label: const Text('Back',
                style: TextStyle(color: Colors.white, fontSize: 16)),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(height: 20),
          // Logo Text
          Center(
            child: RichText(
              textAlign: TextAlign.center,
              text: const TextSpan(
                style: TextStyle(fontSize: 24, color: Colors.white),
                children: [
                  TextSpan(text: 'coto'),
                  TextSpan(
                    text: 'pay',
                    style: TextStyle(color: Color(0xff34A853)), // Green
                  ),
                  TextSpan(text: ' for\n'),
                  TextSpan(
                    text: 'Business',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff34A853), // Green
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Bottom white curved part of the screen
  Widget _buildBottomSection() {
    return Expanded(
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 64, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'LINKED WORKPLACE',
                  style: TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 16),
                // Company Info Container
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xff333333), // Dark grey
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade600,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        // Aap yahan company ka logo laga sakte hain
                        // child: Icon(Icons.business, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'XYZ Company',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.check_circle,
                        color: Color(0xffFBCB0A), // Yellow verified icon
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Pre-filled TextFields
                _buildInfoTextField(label: 'Name', value: 'Ramesh Gupta'),
                const SizedBox(height: 16),
                _buildInfoTextField(
                    label: 'Work email address',
                    value: 'ramesh@business.com'),
                const SizedBox(height: 16),
                _buildInfoTextField(label: 'Employee ID', value: 'BUS01'),
                const SizedBox(height: 40),
                // Explore Offers Button
                ElevatedButton(
                  onPressed: () {
                    // Yahan offers explore karne ka logic aayega
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff3B82F6), // Blue color
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'EXPLORE OFFERS',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper widget for read-only text fields
  Widget _buildInfoTextField({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: TextEditingController(text: value),
          readOnly: true,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[100],
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}