import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:pointycastle/asymmetric/api.dart' show RSAPublicKey, RSAPrivateKey;
import 'package:flutter/services.dart';

class DecryptDemoScreen extends StatefulWidget {
  const DecryptDemoScreen({super.key});

  @override
  State<DecryptDemoScreen> createState() => _DecryptDemoScreenState();
}

class _DecryptDemoScreenState extends State<DecryptDemoScreen> {
  // --- Replace this with your actual PEM private key string ---
  final String _privateKeyPem = [
    '-----BEGIN RSA PRIVATE KEY-----',
    'MIICWgIBAAKBgHXCjyOCwM2uqpxXlbecLn+uvzQXc24uzBs5vzY0GEPKmQVfWJ5w',
    '0hzNE8doFPOcVYLDHCg1LG2EDoANwT39Pm4y6JTP1rI/Qf/dVDmfrGB7LXzEp6gL',
    '6nu/hdQjWEF8h/qmq54SDLz3RC33Y8CC9oG8IekQfiCXotl9FPPyGk2XAgMBAAEC',
    'gYB1OI+txJlR5R219UV2eUScGwH/w5xGwNSyAUDCnwbMbJ74Bxo61YmB2+5lX8kD',
    'WsqQGNItgAjSl1Kry4VhxHXgdw3gU/15QDzjz4NSSpD3xvv8cZMCXmUtlmRYRc5a',
    '21V/ouhLetlIWDpwpAG/rvORQDSXd/2QRBGoURS+9DUxSQJBAL8km2tSBL3Qa5Vm',
    '0HwuiJlYnfzudX08jRyTbiHVLTr0tR0wa3h+CjuVUGuOLUC/tCxUIQI8frOp7xq2',
    '63quDcUCQQCdt6GYGyD8nEsfE5DmCtAv5EdZS8TOFnG4ep1wGp6WdA0aKT9/ennr',
    '0UzlcNfqtFf8tSKYa/kWLqK98/CEf1+rAkBY4GOn9j4gKG4tzN26METx0KO9fP+C',
    'WQpgNCkscBwU4r3oMaB3KVwGsnnvWO+vwLO9PO0QRiK/1Y9JQ66gn5flAkAB454y',
    '5ThK7lBUCfb1WnHN8Q0Nu8OauFgaXpWeLyNxJ+i0RIQ3Ma9eLL6gDO75J7naFA1b',
    'CAgOxPY8EjzySVhLAkBYUq6QMyDh2lpS2BFHA8TspVi5f7TtTndTRTnoy9MWNqQ+',
    'UuvRWwTEtYdwCwFbW5dG/tG8sZHLKGPm0cVcu1tD',
    '-----END RSA PRIVATE KEY-----',
  ].join('\n');

  Map<String, dynamic>? decryptedResponse;
  bool isLoading = false;
  String? errorText;

  @override
  void initState() {
    super.initState();

    // Example: call after widget built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _demoDecryptCall();
    });
  }

  Future<void> _demoDecryptCall() async {
    setState(() {
      isLoading = true;
      errorText = null;
      decryptedResponse = null;
    });

    try {
      final response = {
        // <-- Replace the string below with the actual base64 encriptData you received from server.
        "encriptData": "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",
        // Example encriptKey from your sample (keep as-is or replace with server value)
        "encriptKey":
        "SE3OFhcUFMxStSnZ2jwjwc3/kG/Hse6M8gA9N3pY7AtpCTCKRhVHAcANonGIQWiUIU5iR32DViRrd8A345MuVTuoHFqTXGDV9i1Bz/SEnB1y/p4HpgejcZgMJqGGEajKyH1Q38qEVZrWyrCvpbB0nVltkNWoGqsVeMZUpVlLkMs="
      };

      final result = await decryptApiResponse(response);
      setState(() {
        decryptedResponse = result;
      });

      debugPrint("👉 Final Plain Response: $result");
    } catch (e, st) {
      debugPrint("❌ Decrypt failed: $e\n$st");
      setState(() {
        errorText = e.toString();
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _copyDecryptedToClipboard() async {
    if (decryptedResponse == null) return;

    try {
      final jsonStr = const JsonEncoder.withIndent('  ').convert(decryptedResponse);
      await Clipboard.setData(ClipboardData(text: jsonStr));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Response copied to clipboard')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Copy failed: $e')),
      );
    }
  }

  Future<Map<String, dynamic>> decryptApiResponse(Map<String, dynamic> responseBody) async {
    try {
      // sanity checks
      if (responseBody['encriptData'] == null || responseBody['encriptKey'] == null) {
        throw Exception('Response missing encriptData/encriptKey');
      }

      final parser = encrypt.RSAKeyParser();
      final privateKey = parser.parse(_privateKeyPem) as RSAPrivateKey;

      // RSA decrypt session key
      final rsaEncrypter = encrypt.Encrypter(encrypt.RSA(privateKey: privateKey));
      final encryptedSessionKeyB64 = responseBody['encriptKey'] as String;
      final decryptedSessionKeyBytes = rsaEncrypter.decryptBytes(
        encrypt.Encrypted.fromBase64(encryptedSessionKeyB64),
      );

      // AES encrypter (CBC/PKCS7) with decrypted session key
      final aesKey = encrypt.Key(Uint8List.fromList(decryptedSessionKeyBytes));
      final responseAesEncrypter = encrypt.Encrypter(
        encrypt.AES(aesKey, mode: encrypt.AESMode.cbc, padding: 'PKCS7'),
      );

      // separate IV (first 16 bytes) and ciphertext (rest)
      final encryptedResponsePayload = base64.decode(responseBody['encriptData'] as String);
      if (encryptedResponsePayload.length <= 16) {
        throw Exception('Encrypted payload too short to contain IV + data.');
      }
      final responseIv = encryptedResponsePayload.sublist(0, 16);
      final responseCiphertext = encryptedResponsePayload.sublist(16);

      // decrypt bytes
      final decryptedBytes = responseAesEncrypter.decryptBytes(
        encrypt.Encrypted(responseCiphertext),
        iv: encrypt.IV(responseIv),
      );

      final decryptedJson = utf8.decode(decryptedBytes);
      final finalResponse = json.decode(decryptedJson) as Map<String, dynamic>;

      debugPrint("✅ Decrypted Response Data: ${jsonEncode(finalResponse)}");
      return finalResponse;
    } catch (e) {
      debugPrint("❌ Response decryption failed: $e");
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Decrypt Demo')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ElevatedButton(
                  onPressed: _demoDecryptCall,
                  child: const Text('Decrypt sample response'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: (decryptedResponse != null && !isLoading)
                      ? _copyDecryptedToClipboard
                      : null,
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (errorText != null)
              Text('Error: $errorText', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            Text('Decrypted Response:', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: SelectableText(
                  decryptedResponse != null
                      ? const JsonEncoder.withIndent('  ').convert({}) /* placeholder */
                      .replaceFirst('{}',
                      const JsonEncoder.withIndent('  ').convert(decryptedResponse))
                      : 'No data yet',
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
