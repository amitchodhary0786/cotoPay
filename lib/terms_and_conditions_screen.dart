import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  // Helper function to launch email
  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'business@CotoPay.com',
    );
    if (!await launchUrl(emailLaunchUri)) {
      throw Exception('Could not launch $emailLaunchUri');
    }
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
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Term & Conditions',
          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'LAST UPDATED ON 03-02-2025 15:25:28',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(
              'These Terms and Conditions, along with our Privacy Policy and other terms ("Terms"), constitute a binding agreement between COTODEL TECHNOLOGIES PRIVATE LIMITED ("Website Owner", "we", "us", "our") and you ("you", "your") regarding the use of our website, goods, or services (collectively, "Services").',
              style: TextStyle(color: Colors.grey.shade700, height: 1.5, fontSize: 15),
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('Acceptance of Terms'),
            _buildParagraph(
              'By using our website and Services, you acknowledge that you have read and accepted these Terms. We reserve the right to modify these Terms at any time. It is your responsibility to review these Terms periodically.',
            ),

            _buildSectionTitle('Usage Conditions'),
            _buildBulletPoint('You must provide accurate and complete information during registration and are responsible for all activities under your account.'),
            _buildBulletPoint('We do not guarantee the accuracy, timeliness, or suitability of information on the website.'),
            _buildBulletPoint('Your use of the Services is at your own risk; ensure they meet your requirements.'),
            _buildBulletPoint('The content of the Website and Services is proprietary; you do not gain any intellectual property rights.'),
            _buildBulletPoint('Unauthorized use of the Website or Services may lead to legal action.'),
            _buildBulletPoint('You agree to pay the charges associated with availing the Services.'),
            _buildBulletPoint('You shall not use the website or Services for unlawful activities.'),
            _buildBulletPoint('Third-party website links are subject to their respective terms and policies.'),
            _buildBulletPoint('By initiating a transaction, you enter a legally binding contract with us.'),
            _buildBulletPoint('Refunds are available if we cannot provide the Service within the specified timeline.'),
            _buildBulletPoint('Force majeure events may exempt parties from performance obligations.'),

            _buildSectionTitle('Governing Law & Jurisdiction'),
            _buildParagraph(
              'These Terms are governed by the laws of India, and any disputes shall be subject to the exclusive jurisdiction of the courts in Delhi.',
            ),

            _buildSectionTitle('Contact Information'),
            // Clickable Email Link
            Row(
              children: [
                Flexible(
                  child: Text(
                    'For any concerns, please reach us at ',
                    style: TextStyle(color: Colors.grey.shade700, height: 1.5, fontSize: 15),
                  ),
                ),
                InkWell(
                  onTap: _launchEmail,
                  child: const Text(
                    'business@CotoPay.com',
                    style: TextStyle(color: Colors.blue, height: 1.5, fontSize: 15),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for section titles
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Helper widget for paragraphs
  Widget _buildParagraph(String text) {
    return Text(
      text,
      style: TextStyle(color: Colors.grey.shade700, height: 1.5, fontSize: 15),
    );
  }

  // Helper widget for bullet points
  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: Colors.grey.shade700, fontSize: 15, height: 1.5)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.grey.shade700, height: 1.5, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}