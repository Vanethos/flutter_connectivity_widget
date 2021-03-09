import 'dart:async';

import 'package:connectivity/connectivity.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

import 'package:http/http.dart' as http;

import 'event.dart';

/// Callback to verify the response of the pinged server
typedef VerifyResponseCallback = bool Function(String response);

/// Connectivity Utils
///
/// Helper class to determine phone connectivity
class ConnectivityUtils {
  /// Server to ping
  ///
  /// The server to ping and check the response, can be set with [setServerToPing]
  List<String> _serverToPing = ["www.gstatic.com", "generate_204"];

  /// Verify Response Callback
  ///
  /// Callback to verify the response of the [_serverToPing]
  VerifyResponseCallback _callback = (_) => true;

  /// Sets a new server to ping
  void setServerToPing(List<String> serverToPing) {
    _serverToPing = serverToPing;
    _getConnectivityStatusSubject.add(Event());
  }

  /// Sets a new VerifyResponseCallback
  void setCallback(VerifyResponseCallback callback) {
    _callback = callback;
  }

  static ConnectivityUtils _instance;

  /// Initializes the ConnectivityUtils instance by giving it a [serverToPing] and [callback]
  static ConnectivityUtils initialize(
      {List<String> serverToPing, VerifyResponseCallback callback}) {
    _instance =
        ConnectivityUtils._(serverToPing: serverToPing, callback: callback);
    return _instance;
  }

  static ConnectivityUtils get instance {
    if (_instance == null) {
      _instance = ConnectivityUtils._();
    }
    return _instance;
  }

  ConnectivityUtils._(
      {List<String> serverToPing, VerifyResponseCallback callback}) {
    this._serverToPing =
        serverToPing != null ? serverToPing : this._serverToPing;
    this._callback = callback != null ? callback : this._callback;

    // TODO: Fix for Web, onConnectivityChanged.listen throws error QAPP-50
    if (!kIsWeb) {
      Connectivity().onConnectivityChanged.listen(
          (_) => _getConnectivityStatusSubject.add(Event()),
          onError: (_) => _getConnectivityStatusSubject.add(Event()));
    }

    /// Stream that receives events and verifies the network status
    _getConnectivityStatusSubject.stream
        .asyncMap((_) => isPhoneConnected())
        .listen((value) async {
      // only add a new value if we are changing state
      if (value != _connectivitySubject.value) _connectivitySubject.add(value);
      // if we are offline, retry until we are online
      if (!value) {
        await Future.delayed(Duration(seconds: 3));
        _getConnectivityStatusSubject.add(Event());
      }
    }, onError: (error) async {
      if (!_connectivitySubject.value) _connectivitySubject.add(false);
      // if we are offline, retry until we are online
      await Future.delayed(Duration(seconds: 3));
      _getConnectivityStatusSubject.add(Event());
    });

    _getConnectivityStatusSubject.add(Event());
  }

  /// Connectivity on/off events
  BehaviorSubject<bool> _connectivitySubject = BehaviorSubject<bool>();

  Stream<bool> get isPhoneConnectedStream => _connectivitySubject.stream;

  /// Event to check the network status
  PublishSubject<Event> _getConnectivityStatusSubject = PublishSubject<Event>();

  Sink<Event> get getConnectivityStatusSink =>
      _getConnectivityStatusSubject.sink;

  /// Checkf if phone is connected to the internet
  ///
  /// This method tries to access google.com to verify for
  /// internet connection
  ///
  /// returns [Future<bool>] with value [true] of connected to the
  /// internet
  Future<bool> isPhoneConnected() async {
    // TODO: Make a fix for Web Version, CORS on Web doesn't allow ping new resources
    if (!kIsWeb) {
      try {
        // ignore: close_sinks
        final httpsUri = Uri.https(_serverToPing[0], _serverToPing[1]);
        final result = await http.get(httpsUri);
        if (result.statusCode > 199 && result.statusCode < 400) {
          if (_callback(result.body) == true) {
            return true;
          }
        }
      } catch (e) {
        return false;
      }
      return false;
    }
    return true;
  }
}
