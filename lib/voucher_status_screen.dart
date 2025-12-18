import 'dart:convert';

import 'package:cotopay/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class VoucherData {
  final String name;
  final String mobile;
  final String voucherDesc;
  final String voucherCode;
  final String amount;
  final String redemtionType;
  final String startDate;
  final String validity;

  VoucherData({
    required this.name,
    required this.mobile,
    required this.voucherDesc,
    required this.voucherCode,
    required this.amount,
    required this.redemtionType,
    required this.startDate,
    required this.validity,
  });

  factory VoucherData.fromJson(Map<String, dynamic> j) {
    String safe(dynamic v) => v?.toString() ?? '';

    return VoucherData(
      name: safe(j['name']),
      mobile: safe(j['mobile']),
      voucherDesc: safe(j['voucherDesc']),
      voucherCode: safe(j['voucherCode']),
      amount: safe(j['amount']),
      redemtionType: safe(j['redemtionType']),
      startDate: safe(j['startDate']),
      validity: safe(j['validity']),
    );
  }
}

// -------------------------------------------------------------

class VoucherStatusScreen extends StatelessWidget {
  final VoucherData data;

  const VoucherStatusScreen({super.key, required this.data});

  /// Parse directly from API JSON
  factory VoucherStatusScreen.fromApiResponse(dynamic apiResponse) {
    try {
      if (apiResponse == null) {
        throw Exception("Invalid response");
      }

      if (apiResponse is Map) {
        final d = apiResponse["data"];
        if (d is List && d.isNotEmpty) {
          final first = d[0];
          return VoucherStatusScreen(
            data: VoucherData.fromJson(Map<String, dynamic>.from(first)),
          );
        }
      }

      throw Exception("Invalid response structure");
    } catch (e) {
      return VoucherStatusScreen(
        data: VoucherData(
          name: "",
          mobile: "",
          voucherDesc: "",
          voucherCode: "",
          amount: "",
          redemtionType: "",
          startDate: "",
          validity: "",
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: const Text(
                "Issuance Status",
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,  // Semi Bold
                  fontSize: 16,
                  height: 1.4,                  // 140%
                  letterSpacing: 0,
                  color: Color(0xFF4A4E69),     // #4A4E69
                ),
              ),

            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child:
                          // data.icon!=null?Image.memory(
                          //   base64Decode(data.icon??''),color: Colors.black54
                          // ):
                          Container(),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            data.voucherDesc.isNotEmpty ? data.voucherDesc : "Voucher",
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,     // Semi Bold
                              fontSize: 16,                    // 16px
                              height: 1.4,                     // 140% line-height
                              letterSpacing: 0,
                              color: Color(0xFF1F212C),        // #1F212C
                            ),
                          ),

                        ),
              SizedBox(
                width: 40,
                height: 40,
                child: SvgPicture.asset(
                  'assets/righ.svg',    // your svg file path
                  width: 28,
                  height: 28,
                  color: Colors.green,        // icon color
                  fit: BoxFit.scaleDown,      // keep it centered without stretching
                ),
              ),
              ],
                    ),

                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label("Name"),
                           //  Text(data.name, style: const TextStyle(fontWeight: FontWeight.w600)),


                              Text(
                                data.name,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w400,     // Regular
                                  fontSize: 14,
                                  height: 1.4,                     // 140%
                                  letterSpacing: 0,
                                  color: Color(0xFF4A4E69),        // #4A4E69
                                ),
                              ),

                              const SizedBox(height: 12),
                              _label("Amount"),
                          //    Text("₹${data.amount}", style: const TextStyle(fontWeight: FontWeight.w600)),


                              Text(
                                "₹${data.amount}",
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w400,     // Regular
                                  fontSize: 14,
                                  height: 1.4,                     // 140%
                                  letterSpacing: 0,
                                  color: Color(0xFF4A4E69),        // #4A4E69
                                ),
                              ),

                              const SizedBox(height: 12),
                              _label("Start Date"),

                              Text(
                                data.startDate,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w400,     // Regular
                                  fontSize: 14,
                                  height: 1.4,                     // 140%
                                  letterSpacing: 0,
                                  color: Color(0xFF4A4E69),        // #4A4E69
                                ),
                              ),

                            ],
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label("Number"),


                              Text(
                                data.mobile,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w400,     // Regular
                                  fontSize: 14,
                                  height: 1.4,                     // 140%
                                  letterSpacing: 0,
                                  color: Color(0xFF4A4E69),        // #4A4E69
                                ),
                              ),

                              const SizedBox(height: 12),
                              _label("Redemption Type"),
                              Row(
                                children: [
                                  const Icon(Icons.info_outline, size: 16, color: Colors.black54),
                                  const SizedBox(width: 6),

                                  Text(
                                    data.redemtionType.isNotEmpty ? data.redemtionType : "—",
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w400,     // Regular
                                      fontSize: 14,
                                      height: 1.4,                     // 140%
                                      letterSpacing: 0,
                                      color: Color(0xFF4A4E69),        // #4A4E69
                                    ),
                                  ),


                                ],
                              ),
                              const SizedBox(height: 12),
                              _label("Validity"),

                              Text(
                                "${data.validity} Days",
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w400,     // Regular
                                  fontSize: 14,
                                  height: 1.4,                     // 140%
                                  letterSpacing: 0,
                                  color: Color(0xFF4A4E69),        // #4A4E69
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: 400,
                height: 46,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                          (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF367AFF), // #367AFF
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8), // border-radius: 8
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 24,
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "GO TO DASHBOARD",
                    style: TextStyle(
                      fontFamily: 'Open Sans',
                      fontWeight: FontWeight.w600, // SemiBold
                      fontSize: 16,
                      height: 1.4,                  // 140%
                      letterSpacing: 0,
                      color: Colors.white,          // #FFFFFF
                    ),
                  ),
                ),
              ),

            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w400,     // Regular
        fontSize: 12,
        height: 1.4,                     // 140%
        letterSpacing: 0,
        color: Color(0xFF86889B),        // #86889B
      ),
    );
  }

}
