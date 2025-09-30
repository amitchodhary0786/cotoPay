import 'package:flutter/material.dart';
import 'package:cotopay/session_manager.dart';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfwebcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';
import 'package:flutter/scheduler.dart';

import 'api_service.dart';

/// Small navigator holder used by callbacks to show UI safely.
class AppNavigator {
  static final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();
}

class TrialPaymentFlow {
  // keep CF service reference so it doesn't get GC'd unexpectedly
  static CFPaymentGatewayService? _cfService;

  /// Show amount selection dialog — unchanged interface
  static Future<bool?> showAmountSelection(BuildContext context) {
    String selectedOption = "1000";
    TextEditingController amountController = TextEditingController(text: "1000");

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (outerCtx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: StatefulBuilder(
            builder: (context, setState) {
              void updateSelection(String value) {
                setState(() {
                  selectedOption = value;
                  amountController.text = (value == "other") ? "" : value;
                });
              }

              Future<void> onContinuePressed() async {
                final double amount = double.tryParse(amountController.text.replaceAll(',', '')) ?? 0;
                if (amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter valid amount")));
                  return;
                }
                // Open breakup dialog and wait result
                final bool? paid = await _showBreakupDialog(context, amount);
                if (paid == true) {
                  Navigator.of(outerCtx).pop(true); // close the amount dialog and signal success
                }
              }

              return Padding(
                padding: const EdgeInsets.all(16),
                child: LayoutBuilder(builder: (context, constraints) {
                  final double maxW = constraints.maxWidth;
                  final double tileSpacing = 12;
                  final double twoColWidth = (maxW - tileSpacing) / 2;
                  final double tileWidth = twoColWidth.clamp(120, 240);

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(child: Text("Product Trial Payment", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(outerCtx).pop(false)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text("Select Amount for Product Trial", style: TextStyle(fontSize: 14)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: tileSpacing,
                        runSpacing: 12,
                        children: [
                          _radioOptionResponsive("₹1,000", "1000", selectedOption, updateSelection, tileWidth),
                          _radioOptionResponsive("₹2,500", "2500", selectedOption, updateSelection, tileWidth),
                          _radioOptionResponsive("₹5,000", "5000", selectedOption, updateSelection, tileWidth),
                          _radioOptionResponsive("Other", "other", selectedOption, updateSelection, tileWidth),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: amountController,
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          hintText: "Enter Other Amount",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        onChanged: (val) {
                          setState(() {
                            if (selectedOption != "other") selectedOption = "other";
                          });
                        },
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6), // primary blue
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: onContinuePressed,
                          child: const Text("CONTINUE", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                    ],
                  );
                }),
              );
            },
          ),
        );
      },
    );
  }

  // responsive option tile
  static Widget _radioOptionResponsive(String label, String value, String selectedValue, Function(String) onSelected, double width) {
    final isSelected = value == selectedValue;
    return GestureDetector(
      onTap: () => onSelected(value),
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2F945A) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_off, color: isSelected ? Colors.white : Colors.black54),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // --------- BREAKUP DIALOG WITH EXPAND/ COLLAPSE ----------
  // returns true if payment was started (user pressed PAY NOW and _payNow invoked)
  static Future<bool?> _showBreakupDialog(BuildContext context, double amount) {
    bool isExpanded = false;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (outerCtx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: StatefulBuilder(
            builder: (ctx, setState) {
              final double serviceFee = 0; // 1% fee example
              final double total = amount + serviceFee;

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Product Trial Payment", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(outerCtx).pop(false)),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Animated card area
                    GestureDetector(
                      onTap: () => setState(() => isExpanded = !isExpanded),
                      child: AnimatedSize(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeInOut,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // top row: label left, total amount right
                              Row(
                                children: [
                                  const Expanded(child: Text("Total Payable Amount", style: TextStyle(fontWeight: FontWeight.w600))),
                                  Text("₹${_formatDouble(total)}", style: const TextStyle(fontWeight: FontWeight.w600)),
                                ],
                              ),

                              const SizedBox(height: 8),

                              // thin divider line
                              Container(height: 1, color: Colors.grey.shade200),

                              const SizedBox(height: 8),

                              // Show Break up row + trailing icon (info or undo depending on expanded)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  GestureDetector(
                                    onTap: () => setState(() => isExpanded = !isExpanded),
                                    child: Text("Show Break up", style: TextStyle(color: Colors.blue.shade700)),
                                  ),
                                  GestureDetector(
                                    onTap: () => setState(() => isExpanded = !isExpanded),
                                    child: Container(
                                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300)),
                                      padding: const EdgeInsets.all(6),
                                      child: Icon(
                                        isExpanded ? Icons.undo : Icons.info_outline,
                                        size: 16,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // expanded area (details)
                              const SizedBox(height: 6),
                              if (isExpanded) ...[
                                const SizedBox(height: 6),
                                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                  const Text("Product Trial Amount"),
                                  Text("₹${_formatDouble(amount)}"),
                                ]),
                                const SizedBox(height: 8),
                                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                  const Text("Service Fee"),
                                  Text("₹${_formatDouble(serviceFee)}"),
                                ]),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Buttons: Back | PAY NOW
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(outerCtx).pop(false),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              side: const BorderSide(color: Color(0xFF3B82F6)), // blue border
                            ),
                            child: const Text("Back", style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              // Close breakup dialog and start payment flow
                              Navigator.of(outerCtx).pop(true);
                              await _payNow(context, amount);
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: const Color(0xFF3B82F6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text("PAY NOW", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  static String _formatDouble(double v) {
    // show no decimals when whole, else 2 decimals
    if ((v % 1) == 0) return v.toStringAsFixed(0);
    return v.toStringAsFixed(2);
  }

  // --- existing payment helpers (same as your original) ---
  static String _generateOrderId() {
    final id = "ORDER_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(99999)}";
    debugPrint("🔖 Generated Order ID: $id");
    return id;
  }

  static Future<void> _payNow(BuildContext context, double amount) async {
    final userData = await SessionManager.getUserData();
    debugPrint("👤 userData: $userData");

    final orderId = _generateOrderId();

    final params = {
      "orderAmount": amount.toString(),
      "amountServiceCharge": "0",
      "orderCurrency": "INR",
      "customerId": userData?.id ?? "",
      "customerName": userData?.username ?? "",
      "customerEmail": userData?.email ?? "",
      "customerPhone": userData?.mobile ?? "",
      "orgId": userData?.employerid ?? "",
      "payment_session_id": "",
      "bankCode": "",
      "bankName": "",
      "acNumber": "",
      "createdBy": userData?.username ?? "",
      "orderId": orderId,
      "applicationType": "mobile",
    };

    debugPrint("▶ API Request Params: ${jsonEncode(params)}");

    try {
      final response = await http.post(
        Uri.parse("http://52.66.10.111:8085/cashFree/Api/get/cashFreeOrder"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(params),
      );
      debugPrint("◀ API Response: status=${response.statusCode}, body=${response.body}");

      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes);
        final data = jsonDecode(body);
        debugPrint("✓ Parsed response: $data");

        final bool status = data["status"] == true;
        final sessionId = data["data"]?["payment_session_id"]?.toString();
        debugPrint("status: $status, sessionId: $sessionId");

        if (status && sessionId?.isNotEmpty == true) {
          _openCashfreeGateway(context, sessionId!, orderId);
        } else {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            final ctx = AppNavigator.key.currentState?.context ?? context;
            if (ctx.mounted) {
              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text("Payment init failed: ${data["message"] ?? "Unknown error"}")));
            }
          });
        }
      } else {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          final ctx = AppNavigator.key.currentState?.context ?? context;
          if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text("Payment API Error: ${response.statusCode}")));
        });
      }
    } catch (e) {
      debugPrint("❌ Exception in _payNow: $e");
      SchedulerBinding.instance.addPostFrameCallback((_) {
        final ctx = AppNavigator.key.currentState?.context ?? context;
        if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text("Payment Exception: $e")));
      });
    }
  }

  static void _openCashfreeGateway(BuildContext context, String sessionId, String orderId) {
    debugPrint("🚀 Cashfree Payment started: orderId=$orderId, sessionId=$sessionId");

    // store CF service reference to avoid GC & allow later use if needed
    _cfService = CFPaymentGatewayService();

    // set callbacks
    _cfService!.setCallback(
      // success callback
          (returnedOrderId) {
        debugPrint("Payment Success callback → orderId: $returnedOrderId");

        // call API to update status and then show dialog (use safe context)
        SchedulerBinding.instance.addPostFrameCallback((_) async {
          // prefer AppNavigator context if available
          final navigatorCtx = AppNavigator.key.currentState?.context ?? context;
          // call status update (this method is static and safe to call here)
          await _loadInitialData(returnedOrderId);

          // show success dialog
          if (navigatorCtx != null && navigatorCtx.mounted) {
            _showPaymentSuccessDialog(navigatorCtx);
          } else if (context.mounted) {
            _showPaymentSuccessDialog(context);
          } else {
            debugPrint("No valid context to show success dialog.");
          }
        });
      },
      // error callback
          (CFErrorResponse error, String returnedOrderId) {
        debugPrint("Payment Error callback → orderId: $returnedOrderId, error: ${error.getMessage()}");

        // Always attempt to update status on backend even on failure, then show snackbar if possible
        SchedulerBinding.instance.addPostFrameCallback((_) async {
          final navigatorCtx = AppNavigator.key.currentState?.context;
          final useCtx = (navigatorCtx != null && navigatorCtx.mounted) ? navigatorCtx : (context.mounted ? context : null);

          // call status update (fire-and-forget)
          try {
            await _loadInitialData(returnedOrderId);
          } catch (e) {
            debugPrint("Error while updating status after failure: $e");
          }

          if (useCtx != null) {
            ScaffoldMessenger.of(useCtx).showSnackBar(SnackBar(content: Text("Payment failed: ${error.getMessage()}")));
          } else {
            debugPrint("No valid context to show failure snack.");
          }
        });
      },
    );

    final session = CFSessionBuilder()
        .setEnvironment(CFEnvironment.SANDBOX) // or PRODUCTION
        .setOrderId(orderId)
        .setPaymentSessionId(sessionId)
        .build();
    debugPrint("→ CFSESSION built: $session");

    final payment = CFWebCheckoutPaymentBuilder().setSession(session).build();
    debugPrint("→ CFWebCheckoutPayment built");

    _cfService!.doPayment(payment);

    debugPrint("→ doPayment invoked");
  }

  /// Static helper to call your backend to update/check CashFree status.
  /// This does not attempt UI `setState` — it logs results and shows a SnackBar when a navigator context is available.
  static Future<void> _loadInitialData(String orderId) async {
    try {
      final apiService = ApiService(); // create local instance

      // build params — include known values where possible
      final params = {
        "orderId": orderId,
        "orderAmount": "",
        "amountServiceCharge": "",
        "orderCurrency": "",
        "customerId": "",
        "customerName":  "",
        "customerEmail": "",
        "customerPhone": "",
        "orgId": "",
        "payment_session_id": "",
        "bankCode": "",
        "bankName": "",
        "acNumber": "",
        "createdBy": "",
      //  "applicationType": "mobile"
        "applicationType": ""
      };

      debugPrint("▶ getCashFreeStatusUpdate params: ${jsonEncode(params)}");
      final response = await apiService.getCashFreeStatusUpdate(params);
      debugPrint("◀ getCashFreeStatusUpdate response: $response");

      // if you have a navigator context, show message on failure (not mandatory)
      final navigatorCtx = AppNavigator.key.currentState?.context;
      if (response is Map && response['status'] == true) {

        debugPrint("CashFree status updated successfully for orderId=$orderId");
        if (navigatorCtx != null && navigatorCtx.mounted) {
          // optionally show a tiny success snack (comment out if not desired)
          // ScaffoldMessenger.of(navigatorCtx).showSnackBar(SnackBar(content: Text("Payment status updated")));
          _showPaymentSuccessDialog(navigatorCtx);
        }
      } else {
        debugPrint("CashFree status update reported failure or unexpected response.");
        if (navigatorCtx != null && navigatorCtx.mounted) {
          ScaffoldMessenger.of(navigatorCtx).showSnackBar(SnackBar(content: Text("Failed to update payment status")));
        }
      }
    } catch (e) {
      debugPrint("❌ Error in _loadInitialData: $e");
      final navigatorCtx = AppNavigator.key.currentState?.context;
      if (navigatorCtx != null && navigatorCtx.mounted) {
        ScaffoldMessenger.of(navigatorCtx).showSnackBar(SnackBar(content: Text("Error updating payment status: $e")));
      }
    }
  }

  // show the "Payment completed" dialog (styled)
  static Future<void> _showPaymentSuccessDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // green check circle
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(color: Color(0xFF2E8B57), shape: BoxShape.circle),
                  child: const Center(child: Icon(Icons.check, color: Colors.white, size: 30)),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Payment completed",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Text(
                  "Your Product Trial payment was successful! Now experience the magic of UPI vouchers.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.of(ctx).pop(); // close success dialog
                      // optionally: refresh wallet or pop pages - user choice
                    },
                    child: const Text("OK", style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
