
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart'; // debugPrint के लिए आवश्यक

import 'package:http/http.dart' as http;
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:pointycastle/asymmetric/api.dart' show RSAPublicKey, RSAPrivateKey;

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final String _baseTokenUrl = "http://52.66.10.111:8082/tokenService/Api";
  final String _baseServiceUrl = "http://52.66.10.111:8088/userServices/Api";
  final String _baseEmpServiceUrl = "http://52.66.10.111:8090/empService/Api";
  final String _baseCotoBalance = "http://52.66.10.111:8090/empService/Api/get/";

  String? _accessToken;

  final String _publicKeyPem = [ '-----BEGIN PUBLIC KEY-----', 'MIGeMA0GCSqGSIb3DQEBAQUAA4GMADCBiAKBgHXCjyOCwM2uqpxXlbecLn+uvzQX', 'c24uzBs5vzY0GEPKmQVfWJ5w0hzNE8doFPOcVYLDHCg1LG2EDoANwT39Pm4y6JTP', '1rI/Qf/dVDmfrGB7LXzEp6gL6nu/hdQjWEF8h/qmq54SDLz3RC33Y8CC9oG8IekQ', 'fiCXotl9FPPyGk2XAgMBAAE=', '-----END PUBLIC KEY-----', ].join('\n');
  final String _privateKeyPem = [ '-----BEGIN RSA PRIVATE KEY-----', 'MIICWgIBAAKBgHXCjyOCwM2uqpxXlbecLn+uvzQXc24uzBs5vzY0GEPKmQVfWJ5w', '0hzNE8doFPOcVYLDHCg1LG2EDoANwT39Pm4y6JTP1rI/Qf/dVDmfrGB7LXzEp6gL', '6nu/hdQjWEF8h/qmq54SDLz3RC33Y8CC9oG8IekQfiCXotl9FPPyGk2XAgMBAAEC', 'gYB1OI+txJlR5R219UV2eUScGwH/w5xGwNSyAUDCnwbMbJ74Bxo61YmB2+5lX8kD', 'WsqQGNItgAjSl1Kry4VhxHXgdw3gU/15QDzjz4NSSpD3xvv8cZMCXmUtlmRYRc5a', '21V/ouhLetlIWDpwpAG/rvORQDSXd/2QRBGoURS+9DUxSQJBAL8km2tSBL3Qa5Vm', '0HwuiJlYnfzudX08jRyTbiHVLTr0tR0wa3h+CjuVUGuOLUC/tCxUIQI8frOp7xq2', '63quDcUCQQCdt6GYGyD8nEsfE5DmCtAv5EdZS8TOFnG4ep1wGp6WdA0aKT9/ennr', '0UzlcNfqtFf8tSKYa/kWLqK98/CEf1+rAkBY4GOn9j4gKG4tzN26METx0KO9fP+C', 'WQpgNCkscBwU4r3oMaB3KVwGsnnvWO+vwLO9PO0QRiK/1Y9JQ66gn5flAkAB454y', '5ThK7lBUCfb1WnHN8Q0Nu8OauFgaXpWeLyNxJ+i0RIQ3Ma9eLL6gDO75J7naFA1b', 'CAgOxPY8EjzySVhLAkBYUq6QMyDh2lpS2BFHA8TspVi5f7TtTndTRTnoy9MWNqQ+', 'UuvRWwTEtYdwCwFbW5dG/tG8sZHLKGPm0cVcu1tD', '-----END RSA PRIVATE KEY-----', ].join('\n');







  void _logLong(String message, {String tag = ""})
  {
    const int chunkSize = 800;
    if (message.length <= chunkSize) {
      debugPrint('$tag$message');
    } else {
      for (int i = 0; i < message.length; i += chunkSize) {
        int end = (i + chunkSize < message.length) ? i + chunkSize : message.length;
        debugPrint('$tag${message.substring(i, end)}');
      }
    }
  }


  final String _clientKey = "client-secret-key";       // TODO: APNA CLIENT KEY YAHAN DAALEIN
  final String _clientSecretKey = "0123456789012345"; // TODO: APNA SECRET KEY YAHAN DAALEIN
  //final String _salt = "0123456789012345";



  String _generateSha256Hash(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString(); //
  }

  Future<void> _ensureToken() async {
    if (_accessToken != null && _accessToken!.isNotEmpty) return;
    debugPrint("Generating new access token...");
    try {
      final url = Uri.parse('$_baseTokenUrl/get/access-token');
      final headers = {'Content-Type': 'application/json', 'Company-Code': 'HRMS00001'};
      final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        _accessToken = responseData['access_token'];
        if (_accessToken == null) throw Exception('Access token is null in the response');
        debugPrint("Access Token generated successfully.");
      } else {
        throw Exception('Failed to generate token: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('No Internet connection or server is down.');
    } catch (e) {
      debugPrint("Error generating token: $e");
      rethrow;
    }
  }



  Future<Map<String, dynamic>> addTicket({
    required int orgId,
    required String subject,
    required String issueDesc,
    String ticketImg = "",
    required String createdBy,
  }) async
  {
    final dataString = '$orgId$subject$issueDesc$createdBy$ticketImg$_clientKey$_clientSecretKey';

    debugPrint("❌ Hash Data String: $dataString");


    final String generatedHash = _generateSha256Hash(dataString);
    debugPrint("❌ Generated Hash: $generatedHash");

    final Map<String, dynamic> ticketPayload = {
      "orgId": orgId,
      "subject": subject,
      "issueDesc": issueDesc,
      "ticketImg": ticketImg,
      "createdby": createdBy,
      "clientKey": _clientKey,
     "id":"",
    "ticketnumber":"",
    "issuetype":"",
    "status":"",
    "updatedby":"",
    "responseIssueDesc":"",
    "custTicketStatus":"",
    "custTicketStatusDesc":"",
    "respTicketStatus":"",
    "respTicketStatusDesc":"",
    "responseTktImg":"",
    "responedby":"",
    "ticketno":"",
    "response":"",
    "name":"",
    "remarks":"",


      "hash": generatedHash
    };

    final String url = '$_baseEmpServiceUrl/add/ticket';


    return _callApiEndpoint(url, ticketPayload, method: 'POST');
  }
  Future<Map<String, dynamic>> addTicketComment(
      {
    required int id,
    required int orgId,
    required String issueDesc,
    String ticketImg = "",
    required String createdBy,
    required int respTicketStatus ,
    required String respTicketStatusDesc ,


}) async
  {
    final dataString = '$id$orgId$issueDesc$createdBy$ticketImg$_clientKey$_clientSecretKey';

    debugPrint("❌ Hash Data String: $dataString");


    final String generatedHash = _generateSha256Hash(dataString);
    debugPrint("❌ Generated Hash: $generatedHash");

    final Map<String, dynamic> ticketPayload = {
      "id": id,
      "orgId": orgId,
      "issueDesc": issueDesc,
      "ticketImg": ticketImg,
      "createdby": createdBy,
      "clientKey": _clientKey,

     "ticketnumber":"",
    "issuetype":"",
    "status":"",
    "updatedby":"",
    "responseIssueDesc":"",
    "custTicketStatus":"",
    "custTicketStatusDesc":"",
    "respTicketStatus":respTicketStatus,
    "respTicketStatusDesc":respTicketStatusDesc,
    "responseTktImg":"",
    "responedby":"",
    "ticketno":"",
    "response":"",
    "name":"",
    "remarks":"",




      "hash": generatedHash
    };
    final String url = '$_baseEmpServiceUrl/add/ticketTransaction';


    return _callApiEndpoint(url, ticketPayload, method: 'POST');
  }




  Future<Map<String, dynamic>> getOtp(Map<String, dynamic> userData) async {
    //return _callApiEndpoint('$_baseServiceUrl/getOtpNew', userData);
    return _callApiEndpoint('$_baseServiceUrl/getOtp2Factor', userData);
  }

  Future<Map<String, dynamic>> getVoucherOtp(Map<String, dynamic> userData) async {
    //return _callApiEndpoint('$_baseServiceUrl/getOtpNew', userData);
    return _callApiEndpoint('http://52.66.10.111:8088/userServices/Api/get/sendOtp', userData);
  }


  Future<Map<String, dynamic>> verifyOtp(Map<String, dynamic> otpData) async {
    //return _callApiEndpoint('$_baseServiceUrl/verifyOtpNew', otpData);
    return _callApiEndpoint('$_baseServiceUrl/verifyOtp2Factor', otpData);
  }
  Future<Map<String, dynamic>> resendOtp(Map<String, dynamic> resendData) async {
    return _callApiEndpoint('$_baseServiceUrl/getOtpResend', resendData);
  }

  Future<Map<String, dynamic>> getVoucherList(Map<String, dynamic> params) async {
    return _callApiEndpoint('http://52.66.10.111:8090/empService/Api/get/erupiVoucherCreateListLimit', params);
   }


  Future<Map<String, dynamic>> getBankList(Map<String, dynamic> params) async {
    return _callApiEndpoint('http://52.66.10.111:8090/empService/Api/get/erupiLinkAccountListWithStatus', params);
   }

   Future<Map<String, dynamic>> deleteAccount(Map<String, dynamic> params) async {
    return _callApiEndpoint('http://52.66.10.111:8090/empService/Api/update/emplOnboardingStatus', params);
   }

   Future<Map<String, dynamic>> getBankListUpi(Map<String, dynamic> params) async {
    return _callApiEndpoint('http://52.66.10.111:8090/empService/Api/get/voucherCreateBankList', params);
   }
   Future<Map<String, dynamic>> getBankSummary(Map<String, dynamic> params) async {
    return _callApiEndpoint('http://52.66.10.111:8090/empService/Api/get/voucherCreateSummaryDetailByAccount', params);
   }

   Future<Map<String, dynamic>> getBankBalance(Map<String, dynamic> params) async {
    return _callApiEndpoint('http://52.66.10.111:8090/empService/Api/get/linkMultipleAccountAmount', params);
   }
   Future<Map<String, dynamic>> createSingleVoucher(Map<String, dynamic> params) async {
    return _callApiEndpoint('http://52.66.10.111:8090/empService/Api/add/erupiVoucherSingleCreation', params);
   }

  Future<Map<String, dynamic>> getCotoBalance(Map<String, dynamic> params) async {
    return _callApiEndpoint('http://52.66.10.111:8090/empService/Api/get/linkMultipleAccountAmount', params);
   }
  Future<Map<String, dynamic>> getVoucherCategoryList() async {
    return _callApiEndpoint('http://52.66.10.111:8083/masterService/Api/get/voucherCategoryList', {});
   }
 Future<Map<String, dynamic>> getVoucherSubCategoryList(Map<String, dynamic> params) async {
    return _callApiEndpoint('http://52.66.10.111:8083/masterService/Api/get/mccByCotoCatIdList', params);
   }

   Future<Map<String, dynamic>> getVoucherNameSearchMobile(Map<String, dynamic> params) async {
    return _callApiEndpoint('http://52.66.10.111:8090/empService/Api/get/employeeSearchWithMobile', params);
   }

  /*Future<Map<String, dynamic>> getCotoBalanceTransactionList(Map<String, dynamic> params) async {
    return _callApiEndpoint('http://52.66.10.111:8085/cashFree/Api/get/cashFreeOrderIdList', params);
   }
*/
   /*Future<Map<String, dynamic>> getTrialPayment(Map<String, dynamic> params) async {
    return _callApiEndpoint('http://52.66.10.111:8085/cashFree/Api/get/cashFreeOrder', params);
   }*/


  Future<Map<String, dynamic>> getAllTickets({required int orgId}) async
  {
    final params = {
      'orgId': orgId.toString(),
    };
    final endpoint = 'http://52.66.10.111:8090/empService/Api/get/allTicket';

    return _callApiEndpoint(endpoint, params);
  }

  Future<Map<String, dynamic>> getAllTicketsDetails({required int orgId, required int id}) async {
    final params = {
      'orgId': orgId.toString(),
      'id': id.toString(),
    };

    final endpoint = 'http://52.66.10.111:8090/empService/Api/get/ticketTransHistory';

    return _callApiEndpoint(endpoint, params);
  }


  Future<Map<String, dynamic>> getDashboard(Map<String, dynamic> params) async {
    return _callApiEndpoint('http://52.66.10.111:8090/empService/api/vouchers/summary', params);
  }
  Future<Map<String, dynamic>> getVoucherListRedeem(Map<String, dynamic> params) async {
    return _callApiEndpoint('http://52.66.10.111:8090/empService/Api/get/erupiVoucherCreateListRedeem', params);
  }

  Future<Map<String, dynamic>> getVoucherHistoryDetails(Map<String, dynamic> params) async {
    return _callApiEndpoint('http://52.66.10.111:8090/empService/Api/get/erupiVoucherStatusHistory', params);
  }

  Future<Map<String, dynamic>> updateUserProfile({required int userId, required Map<String, dynamic> profileData}) async {
    //final url = '$_baseServiceUrl/update/userprofile1/$userId';

    final url = 'http://52.66.10.111:8088/userServices/api/update/userprofile1/$userId';
    return _callApiEndpoint(url, profileData, method: 'POST');
  }

  Future<Map<String, dynamic>> _callApiEndpoint(String url, Map<String, dynamic> data, {String method = 'POST'}) async {
    await _ensureToken();
    if (_accessToken == null) throw Exception('Authorization token is missing.');

    debugPrint("------------Auth Token ------------   " +_accessToken.toString());
    debugPrint("------------ API Request Initiated ------------");
    debugPrint("📡 URL: $url");
    debugPrint("🔑 Plaintext Request Data: ${jsonEncode(data)}");

    try {
      final parser = encrypt.RSAKeyParser();
      final publicKey = parser.parse(_publicKeyPem) as RSAPublicKey;
      final sessionKey = _generateRandomBytes(16);
      final iv = _generateRandomBytes(16);
      final rsaEncrypter = encrypt.Encrypter(encrypt.RSA(publicKey: publicKey));
      final aesEncrypter = encrypt.Encrypter(encrypt.AES(encrypt.Key(sessionKey), mode: encrypt.AESMode.cbc, padding: 'PKCS7'));

      final encryptedSessionKey = rsaEncrypter.encryptBytes(sessionKey);
      final encryptedData = aesEncrypter.encryptBytes(utf8.encode(json.encode(data)), iv: encrypt.IV(iv));

      final payloadWithIv = iv + encryptedData.bytes;
      final requestBody = json.encode({'encriptData': base64.encode(payloadWithIv), 'encriptKey': encryptedSessionKey.base64});

      debugPrint("🔒 Encrypted Request Body: $requestBody");


      final headers = {'Content-Type': 'application/json', 'Authorization': 'Bearer $_accessToken'};
      final uri = Uri.parse(url);





      http.Response response;
      if (method.toUpperCase() == 'PUT') {
        response = await http.put(uri, headers: headers, body: requestBody);
      } else {
        response = await http.post(uri, headers: headers, body: requestBody);
      }

      debugPrint("📈 Response Status Code: ${response.statusCode}");
      debugPrint("📤 Encrypted Response Body: ${response.body}");



      if (response.statusCode == 200)
      {
        final responseBody = json.decode(response.body);
        final privateKey = parser.parse(_privateKeyPem) as RSAPrivateKey;
        final responseRsaEncrypter = encrypt.Encrypter(encrypt.RSA(privateKey: privateKey));
        final decryptedSessionKeyBytes = responseRsaEncrypter.decryptBytes(encrypt.Encrypted.fromBase64(responseBody['encriptKey']));
        final responseAesEncrypter = encrypt.Encrypter(encrypt.AES(encrypt.Key(Uint8List.fromList(decryptedSessionKeyBytes)), mode: encrypt.AESMode.cbc, padding: 'PKCS7'));

        final encryptedResponsePayload = base64.decode(responseBody['encriptData']);
        final responseIv = encryptedResponsePayload.sublist(0, 16);
        final responseCiphertext = encryptedResponsePayload.sublist(16);

        final decryptedBytes = responseAesEncrypter.decryptBytes(encrypt.Encrypted(responseCiphertext), iv: encrypt.IV(responseIv));
        final decryptedJson = utf8.decode(decryptedBytes);
        final finalResponse = json.decode(decryptedJson) as Map<String, dynamic>;







        debugPrint("✅ Decrypted Response Data: ${jsonEncode(finalResponse)}");

        debugPrint("---------------- API Request End -----------------");

        return finalResponse;
      } else {
        throw Exception('API request to $url failed: ${response.statusCode}\nBody: ${response.body}');
      }
    } catch (e) {
      debugPrint("❌ Error in API communication: $e");
      debugPrint("---------------- API Request End -----------------");
      rethrow;
    }
  }

  Uint8List _generateRandomBytes(int length) {
    return Uint8List.fromList(List<int>.generate(length, (_) => Random.secure().nextInt(256)));
  }

}