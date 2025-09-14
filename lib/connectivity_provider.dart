
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

class ConnectivityProvider with ChangeNotifier {
  bool _hasInternet = true;
  bool get hasInternet => _hasInternet;

  late StreamSubscription<InternetConnectionStatus> _internetSubscription;

  ConnectivityProvider() {
    _internetSubscription =
        InternetConnectionChecker().onStatusChange.listen((status) {
          final hasInternet = status == InternetConnectionStatus.connected;
          if (_hasInternet != hasInternet) {
            _hasInternet = hasInternet;
            notifyListeners();
          }
        });
  }

  @override
  void dispose() {
    _internetSubscription.cancel();
    super.dispose();
  }
}