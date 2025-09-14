import 'package:flutter/material.dart';
import 'home.dart';

class EnterNameScreen extends StatefulWidget {
  const EnterNameScreen({super.key});

  @override
  State<EnterNameScreen> createState() => _EnterNameScreenState();
}

class _EnterNameScreenState extends State<EnterNameScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool isButtonEnabled = false;

  void _onNameChanged(String value) {
    setState(() {
      isButtonEnabled = value.trim().isNotEmpty;
    });
  }

  void _onConfirm() {
    final name = _nameController.text.trim();

    if (name.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset(
                    'assets/logo.png',
                    width: 124,
                    height: 30,
                  ),
                  const Icon(
                    Icons.signal_cellular_alt_rounded,
                    size: 20,
                    color: Colors.transparent, // placeholder for spacing
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Mobile Display Field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F3EC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'Mobile',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        color: Colors.black54,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '+91 98739 49123',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF00A56A),
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(
                          Icons.check_circle,
                          size: 18,
                          color: Color(0xFF00A56A),
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Name Input Field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: TextField(
                controller: _nameController,
                onChanged: _onNameChanged,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  labelText: 'Name',
                  hintText: 'Enter your name',
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const Spacer(),

            // Confirm Button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isButtonEnabled ? _onConfirm : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isButtonEnabled
                        ? const Color(0xFFFFC107) // yellow
                        : Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isButtonEnabled ? 'Let’s Go!' : 'CONFIRM',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isButtonEnabled ? Colors.black : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
