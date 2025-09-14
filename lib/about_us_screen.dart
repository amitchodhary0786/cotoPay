import 'package:flutter/material.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'About Us',
          style: TextStyle(
              color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: BoxDecoration(
                color: const Color(0xff212121), // Dark grey
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  RichText(
                    text: const TextSpan(
                      style:
                      TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                      children: [
                        TextSpan(
                            text: 'coto', style: TextStyle(color: Colors.white)),
                        TextSpan(
                          text: 'pay',
                          style:
                          TextStyle(color: Color(0xff34A853)), // Green
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Simplifying Business Expenses with UPI',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Main Heading with mixed styles
            RichText(
              text: const TextSpan(
                style: TextStyle(
                    fontSize: 17, color: Colors.black87, height: 1.4),
                children: [
                  TextSpan(text: 'We are here to making '),
                  TextSpan(
                    text: 'your Business payments',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xff34A853)),
                  ),
                  TextSpan(text: ' seamless as '),
                  TextSpan(
                    text: 'your personal UPI spends!',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xff34A853)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // "Who we are" Section
            _buildInfoSection(
              title: 'Who we are',
              content:
              'CotoPay is committed to delivering a reinvigorated approach to how business spends are done. UPI has become the de-facto form of payment for all of us so why not have the same for all of our business payments as well? No matter the industry or size of your organisation, we want to help you provide a seamless experience when it comes to your business payments.',
            ),
            const SizedBox(height: 24),

            // "What we do" Section
            _buildInfoSection(
              title: 'What we do',
              content:
              'We are here to ease everyone\'s professional lives and we do this by using the existing UPI ecosystem for issuing digital prepaid vouchers that can be redeemed across any of the existing UPI apps. The objective is to streamline the payments process by providing complete transparency and traceability to the issuer and bringing convenience to the end-user.',
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for content sections
  Widget _buildInfoSection({required String title, required String content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
            height: 1.5,
          ),
          // ================================
        ),
      ],
    );
  }
}