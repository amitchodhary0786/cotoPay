
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class UserData {
  final int id;
  final String? firstName, lastName, dateofbirth, gender, contactNumber, email, address, orgType, orgName, mobile, createdDate, emailVerifyDate, mobileVerifyDate, username, pwd, createdBy, companySize, role, hrmsId, hrmsName, employeeId, managerEmployeeId, companyType, organizationName;
  final int? emailVerifyStatus, mobileVerifyStatus, status, employerid, roleId, companyId;

  UserData({
    required this.id, this.firstName, this.lastName, this.dateofbirth, this.gender,
    this.contactNumber, this.email, this.address, this.orgType,
    this.orgName, this.mobile, this.createdDate, this.emailVerifyStatus,
    this.mobileVerifyStatus, this.emailVerifyDate, this.mobileVerifyDate,
    this.username, this.pwd, this.status, this.employerid, this.roleId,
    this.createdBy, this.companySize, this.role, this.companyId,
    this.hrmsId, this.hrmsName, this.employeeId, this.managerEmployeeId,
    this.companyType, this.organizationName,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic v) => v is int ? v : (v is String ? int.tryParse(v) : null);
    String? parseString(dynamic v) => v?.toString();
    return UserData(
      id: parseInt(json['id']) ?? 0,
      firstName: parseString(json['first_name']), lastName: parseString(json['last_name']), dateofbirth: parseString(json['dateofbirth']),
      gender: parseString(json['gender']), contactNumber: parseString(json['contact_number']), email: parseString(json['email']),
      address: parseString(json['address']), orgType: parseString(json['org_type']), orgName: parseString(json['org_name']),
      mobile: parseString(json['mobile']), createdDate: parseString(json['created_date']), emailVerifyStatus: parseInt(json['email_verify_status']),
      mobileVerifyStatus: parseInt(json['mobile_verify_status']), emailVerifyDate: parseString(json['email_verify_date']),
      mobileVerifyDate: parseString(json['mobile_verify_date']), username: parseString(json['username']), pwd: parseString(json['pwd']),
      status: parseInt(json['status']), employerid: parseInt(json['employerid']), roleId: parseInt(json['role_id']),
      createdBy: parseString(json['createdBy']), companySize: parseString(json['companySize']), role: parseString(json['role']),
      companyId: parseInt(json['companyId']), hrmsId: parseString(json['hrmsId']), hrmsName: parseString(json['hrmsName']),
      employeeId: parseString(json['employeeId']), managerEmployeeId: parseString(json['managerEmployeeId']),
      companyType: parseString(json['companyType']), organizationName: parseString(json['organizationName']),
    );
  }

  Map<String, dynamic> toJson() {
    return { 'id': id, 'first_name': firstName, 'last_name': lastName, 'dateofbirth': dateofbirth, 'gender': gender, 'contact_number': contactNumber, 'email': email, 'address': address, 'org_type': orgType, 'org_name': orgName, 'mobile': mobile, 'created_date': createdDate, 'email_verify_status': emailVerifyStatus, 'mobile_verify_status': mobileVerifyStatus, 'email_verify_date': emailVerifyDate, 'mobile_verify_date': mobileVerifyDate, 'username': username, 'pwd': pwd, 'status': status, 'employerid': employerid, 'role_id': roleId, 'createdBy': createdBy, 'companySize': companySize, 'role': role, 'companyId': companyId, 'hrmsId': hrmsId, 'hrmsName': hrmsName, 'employeeId': employeeId, 'managerEmployeeId': managerEmployeeId, 'companyType': companyType, 'organizationName': organizationName, };
  }
}

class SessionManager {
  static const String _userDataKey = 'userData';
  static const String _isLoggedInKey = 'isLoggedIn';
  static const String _roleIdKey = "role_id";

  static Future<bool> isLoggedIn() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  static Future<void> saveLoginData(Map<String, dynamic> data) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      await prefs.setBool(_isLoggedInKey, true);

      UserData userDataObject = UserData.fromJson(data);

      String userJsonString = jsonEncode(userDataObject.toJson());
      await prefs.setString(_userDataKey, userJsonString);




      debugPrint("✅ [SessionManager] Login status and User data saved.");
    } catch (e) {
      debugPrint("❌ [SessionManager] Error saving login data: $e");
      throw Exception('Failed to save user session.');
    }
  }

  static Future<UserData?> getUserData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userDataString = prefs.getString(_userDataKey);
    if (userDataString != null) {
      return UserData.fromJson(jsonDecode(userDataString));
    }
    return null;
  }

  // new method to save role_id
  static Future<void> saveRoleId(int roleId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_roleIdKey, roleId);
  }

  static Future<int?> getRoleId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_roleIdKey);
  }


  static Future<void> updateUserData(UserData updatedData) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String userDataString = jsonEncode(updatedData.toJson());
    await prefs.setString(_userDataKey, userDataString);
    debugPrint("✅ User data updated in SharedPreferences.");
  }

  static Future<void> logout(BuildContext context) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
    }
  }
}