import 'package:flutter/material.dart';
import 'upi_voucher_scren.dart';

void main() {
  runApp(const MyApp());
}

const bgColor = Colors.white;
const primaryBlue = Color(0xFF3B82F6); // button color

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UPI Vouchers',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: bgColor,
      ),
      home: const HowUpiVouchersWorks(),
    );
  }
}

class HowUpiVouchersWorks extends StatelessWidget {
  const HowUpiVouchersWorks({super.key});

  @override
  Widget build(BuildContext context)
  {
    final horizontalPadding = 20.0;
    return Scaffold(

      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () {
            Navigator.pop(context); // go back
          },
        ),
        title: const Text(
          'How UPI Vouchers Works',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
      ),


      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stepper-like area
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left steps column
                          SizedBox(
                            width: 48,
                            child: Column(
                              children: const [
                                StepDot(number: 1),
                                StepConnector(),
                                StepDot(number: 2),
                                StepConnector(),
                                StepDot(number: 3),
                                StepConnector(),
                                StepDot(number: 4),
                              ],
                            ),
                          ),

                          // Spacing
                          const SizedBox(width: 12),

                          // Right descriptions
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                StepContent(
                                  title: 'Activate UPI Voucher',
                                  subtitle:
                                  'Activate UPI Voucher with a 6-digit OTP from the Bank used to issue.',
                                ),
                                SizedBox(height: 18),
                                StepContent(
                                  title: 'Set your personal PIN',
                                  subtitle:
                                  'Set a 4-digit PIN that you will use for redeeming the Voucher and checking the Balance',
                                ),
                                SizedBox(height: 18),
                                StepContent(
                                  title: 'Scan & Pay',
                                  subtitle:
                                  'Scan a Merchant QR Code, select Voucher as payment source, enter PIN and you are good to go',
                                ),
                                SizedBox(height: 18),
                                StepContent(
                                  title: 'Check Balance and Histories',
                                  subtitle:
                                  'Use your PIN to check balance of Voucher and see transaction history along with other UPI transactions',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // Illustration card
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          children: [
                            // Illustration image (add to assets)
                            SizedBox(
                              height: constraints.maxHeight * 0.25,
                              child: Image.asset(
                                'assets/voucher_illustration.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'No Voucher issued yet!',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ),

              // Bottom button fixed with padding + safe area
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: ()

                      => Navigator.push(context,
                          MaterialPageRoute(builder: (context) => const UpiVouchersScreen())),
                      // action

                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Issue Vouchers',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class StepContent extends StatelessWidget {
  final String title;
  final String subtitle;
  const StepContent({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(color: Colors.grey.shade700, height: 1.35),
        ),
      ],
    );
  }
}

class StepDot extends StatelessWidget {
  final int number;
  const StepDot({super.key, required this.number});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.green.shade700, width: 2),
        color: Colors.white,
      ),
      alignment: Alignment.center,
      child: Text(
        '$number',
        style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold),
      ),
    );
  }
}

/// Dashed-like connector. We simulate dashed using short containers.
class StepConnector extends StatelessWidget {
  const StepConnector({super.key});

  @override
  Widget build(BuildContext context) {
    // create a vertical dashed line comprised of small boxes
    return Column(
      children: List.generate(6, (i) {
        return Container(
          width: 2,
          height: 10,
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }
}
