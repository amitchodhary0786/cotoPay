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
        "encriptData": "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",

        "encriptKey": "BPSKnVpRu66y28vJr9i5zMMSh38vY7YwSF2j8pfMLPasnvQHrul1+mx5JeMRaN1r0p6QWdLSr38VNE7ZIBMveiF2umUfPoV1pb6IEhNSxfWlSuXP9Kybldv+W6/7SC4/ZIntuOzulTP1E7Oqv8Uu0x5fmjp+lGeo7u//1cOEvQk="
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
