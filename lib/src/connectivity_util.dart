import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:connectivity/connectivity.dart';
import 'package:rxdart/rxdart.dart';

import 'event.dart';

typedef VerifyResponseCallback = bool Function(String response);

/// Connectivity Utils
///
/// Helper class to determine phone connectivity
class ConnectivityUtils {

  String _serverToPing = "http://www.google.com";
  VerifyResponseCallback _callback = (_) => true;
  Dio _dio;

  void setServerToPing(String serverToPing) {
    _serverToPing = serverToPing;
  }

  void setCallback (VerifyResponseCallback callback) {
    _callback = callback;
  }

  static final ConnectivityUtils _instance = ConnectivityUtils._();

  static ConnectivityUtils get instance {
    return _instance;
  }


  ConnectivityUtils._() {
    _dio = Dio();
    
    Connectivity().onConnectivityChanged
        .listen((_) => _getConnectivityStatusSubject.add(Event()));

    _getConnectivityStatusSubject.stream
        .doOnData((_) => print ("Checking network status"))
        .asyncMap((_) => isPhoneConnected())
        .listen((value) async {
      _connectivitySubject.add(value);
      if (!value) {
        await Future.delayed(Duration(seconds: 3));
        _getConnectivityStatusSubject.add(Event());
      }
    });

    _getConnectivityStatusSubject.add(Event());
  }

  BehaviorSubject<bool> _connectivitySubject = BehaviorSubject<bool>();
  Stream<bool> get isPhoneConnectedStream => _connectivitySubject.stream;

  BehaviorSubject<Event> _getConnectivityStatusSubject = BehaviorSubject<Event>();
  Sink<Event> get getConnectivityStatusSink => _getConnectivityStatusSubject.sink;

  /// Checkf if phone is connected to the internet
  ///
  /// This method tries to access google.com to verify for
  /// internet connection
  ///
  /// returns [Future<bool>] with value [true] of connected to the
  /// internet
  Future<bool> isPhoneConnected() async {
    try {
      print("Pinging $_serverToPing");
      final result = await _dio.get(_serverToPing);
      if (result.statusCode == 200 && _callback(result.data.toString())) return true;
    } catch(e) {
      return false;
    }
    return false;
  }
}