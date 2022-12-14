import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
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
  late String _serverToPing;

  /// Verify Response Callback
  ///
  /// Callback to verify the response of the [_serverToPing]
  VerifyResponseCallback? _verifyResponseCallback;

  /// Duration after which we verify again the
  /// connectivity status, defaults to 3 seconds
  late Duration _debounceDuration;

  late Connectivity _connectivity;

  late http.Client _httpClient;

  /// Connectivity on/off events
  BehaviorSubject<bool> _connectivitySubject =
      BehaviorSubject<bool>.seeded(false);

  Stream<bool> get isPhoneConnectedStream =>
      _connectivitySubject.stream.distinct();

  bool get getPhoneConnection => _connectivitySubject.value;

  /// Event to check the network status
  PublishSubject<Event> _getConnectivityStatusSubject = PublishSubject<Event>();

  Sink<Event> get getConnectivityStatusSink =>
      _getConnectivityStatusSubject.sink;

  static ConnectivityUtils? _instance;

  static ConnectivityUtils get instance {
    _instance ??= ConnectivityUtils._();
    return _instance!;
  }

  @visibleForTesting
  static void setInstance(ConnectivityUtils utils) {
    _instance = utils;
  }

  @visibleForTesting
  static ConnectivityUtils createTestingInstance(
    Connectivity connectivity,
    http.Client httpClient,
  ) {
    _instance = ConnectivityUtils.test(
      connectivity: connectivity,
      httpClient: httpClient,
    );
    return _instance!;
  }

  @visibleForTesting
  ConnectivityUtils.test({
    required Connectivity connectivity,
    required http.Client httpClient,
  })  : _httpClient = httpClient,
        _connectivity = connectivity,
        _serverToPing = "http://www.gstatic.com/generate_204",
        _debounceDuration = Duration(seconds: 3) {
    _init();
  }

  ConnectivityUtils._()
      : _connectivity = Connectivity(),
        _httpClient = http.Client(),
        _serverToPing = "http://www.gstatic.com/generate_204",
        _debounceDuration = Duration(seconds: 3) {
    _init();
  }

  void _init() {
    _connectivity.onConnectivityChanged.listen((result) {
      if (!_getConnectivityStatusSubject.isClosed) {
        _getConnectivityStatusSubject.add(Event());
      }
    }, onError: (_) {
      if (!_getConnectivityStatusSubject.isClosed) {
        _getConnectivityStatusSubject.add(Event());
      }
    });

    /// Stream that receives events and verifies the network status
    _getConnectivityStatusSubject.stream
        .asyncMap((_) => isPhoneConnected())
        .listen((value) async {
      if (!_connectivitySubject.isClosed) {
        _connectivitySubject.add(value);
      }

      /// Every duration we will ping the service to see if we are live
      await Future.delayed(_debounceDuration);
      if (!_getConnectivityStatusSubject.isClosed) {
        _getConnectivityStatusSubject.add(Event());
      }
    }, onError: (error) async {
      if (!_connectivitySubject.value) {
        _connectivitySubject.add(false);
      }
      // if we are offline, retry until we are online
      await Future.delayed(_debounceDuration);
      if (!_getConnectivityStatusSubject.isClosed) {
        _getConnectivityStatusSubject.add(Event());
      }
    });

    _getConnectivityStatusSubject.add(Event());
  }

  /// Sets a new server to ping
  set serverToPing(String serverToPing) {
    this._serverToPing = serverToPing;
    if (!_getConnectivityStatusSubject.isClosed) {
      _getConnectivityStatusSubject.add(Event());
    }
  }

  String get serverToPing => _serverToPing;

  /// Sets a new VerifyResponseCallback
  set verifyResponseCallback(VerifyResponseCallback callback) {
    this._verifyResponseCallback = callback;
  }

  /// Sets a new Duration for the verification
  set debounceDuration(Duration duration) {
    this._debounceDuration = duration;
  }

  Duration get debounceDuration => this._debounceDuration;

  /// Checkf if phone is connected to the internet
  ///
  /// This method tries to access google.com to verify for
  /// internet connection
  ///
  /// returns [Future<bool>] with value [true] of connected to the
  /// internet
  Future<bool> isPhoneConnected() async {
    try {
      final result = await _httpClient.get(
        Uri.parse(_serverToPing),
      );
      if (result.statusCode > 199 &&
          result.statusCode < 400 &&
          (_verifyResponseCallback?.call(result.body) ?? true)) {
        return true;
      }
    } catch (e) {
      return false;
    }
    return false;
  }

  Future<void> dispose() async {
    await _connectivitySubject.close();
    await _getConnectivityStatusSubject.close();
  }
}
