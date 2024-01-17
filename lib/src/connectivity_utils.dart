import 'dart:async';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:retry/retry.dart';
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

  // When doing the http call to verify if we are connected, we fail with
  // a timeout after 3 seconds
  late Duration _timeoutDuration;

  /// If set to 0, as soon as the first call has an error, [isPhoneConnectedStream] changes state.
  /// Else, it will retry the call [retries] times before changing the state on
  /// [isPhoneConnectedStream]
  late int _retries;

  /// The number of consecutive successfull calls needed for the system to state that
  /// there is a valid internet connection.
  ///
  /// Defaults to 1, meaning that the first valid call validates the system as connected
  /// to the internet
  late int _minSuccessCalls;

  late Connectivity _connectivity;

  late http.Client _httpClient;

  int _currentSuccessCalls = 0;

  int _currentErrorCalls = 0;

  /// Connectivity on/off events
  BehaviorSubject<bool> _connectivitySubject = BehaviorSubject<bool>();

  Stream<bool> get isPhoneConnectedStream =>
      _connectivitySubject.stream.distinct();

  bool? get getPhoneConnection => _connectivitySubject.valueOrNull;

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
    int retries = 0,
    int minSuccessCalls = 1,
    String? serverToPing,
  })  : _httpClient = httpClient,
        _connectivity = connectivity,
        _serverToPing = serverToPing ?? "http://www.gstatic.com/generate_204",
        _debounceDuration = Duration(seconds: 3),
        _timeoutDuration = Duration(seconds: 2),
        _retries = retries,
        _minSuccessCalls = minSuccessCalls {
    _init();
  }

  ConnectivityUtils._()
      : _connectivity = Connectivity(),
        _httpClient = http.Client(),
        _serverToPing = "http://www.gstatic.com/generate_204",
        _debounceDuration = Duration(seconds: 3),
        _timeoutDuration = Duration(seconds: 2),
        _retries = 0,
        _minSuccessCalls = 1 {
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
      /// Every duration we will ping the service to see if we are live
      await Future.delayed(_debounceDuration);
      if (!_getConnectivityStatusSubject.isClosed) {
        _getConnectivityStatusSubject.add(Event());
      }
    }, onError: (error) async {
      if (!(_connectivitySubject.valueOrNull ?? false)) {
        if (!_connectivitySubject.isClosed) {
          _connectivitySubject.add(false);
        }
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
    if (!_getConnectivityStatusSubject.isClosed) {
      _getConnectivityStatusSubject.add(Event());
    }
  }

  /// Sets a new Duration for the verification
  set debounceDuration(Duration duration) {
    this._debounceDuration = duration;
    if (!_getConnectivityStatusSubject.isClosed) {
      _getConnectivityStatusSubject.add(Event());
    }
  }

  /// Sets a new Duration for the timeout
  set timeoutDuration(Duration duration) {
    this.timeoutDuration = duration;
    if (!_getConnectivityStatusSubject.isClosed) {
      _getConnectivityStatusSubject.add(Event());
    }
  }

  Duration get debounceDuration => this._debounceDuration;

  /// Sets a new number of tries before setting connection to false
  set retries(int retries) {
    this._retries = retries;
    if (!_getConnectivityStatusSubject.isClosed) {
      _getConnectivityStatusSubject.add(Event());
    }
  }

  /// Sets a new number of success calls before setting connection to true
  set minSuccessCalls(int minSuccessCalls) {
    this._minSuccessCalls = minSuccessCalls;
    if (!_getConnectivityStatusSubject.isClosed) {
      _getConnectivityStatusSubject.add(Event());
    }
  }

  /// Checkf if phone is connected to the internet
  ///
  /// This method tries to access google.com to verify for
  /// internet connection
  ///
  /// returns [Future<bool>] with value [true] of connected to the
  /// internet
  Future<bool> isPhoneConnected() async {
    try {
      final result = await retry(
        () => _httpClient
            .get(
              Uri.parse(_serverToPing),
            )
            .timeout(
              _timeoutDuration,
              onTimeout: () => throw TimeoutException(
                'Exceeded timeout time',
              ),
            )
            .then(
          (result) {
            if (result.statusCode > 199 &&
                result.statusCode < 400 &&
                (_verifyResponseCallback?.call(result.body) ?? true)) {
              _currentSuccessCalls++;
              _currentErrorCalls = 0;

              if (_currentSuccessCalls < _minSuccessCalls) {
                throw _InsufficientConsecutiveCallsException();
              }

              _currentSuccessCalls = 0;
              return true;
            }

            _currentErrorCalls++;
            throw TimeoutException("Exceeded timeout time between calls");
          },
        ),
        retryIf: (exc) =>
            exc is _InsufficientConsecutiveCallsException &&
                _currentSuccessCalls < _minSuccessCalls ||
            exc is TimeoutException && _currentErrorCalls < _retries,
        maxAttempts: max(_retries, _minSuccessCalls),
      );

      _currentSuccessCalls = 0;
      _currentErrorCalls = 0;

      if (result) {
        _connectivitySubject.add(true);
        return true;
      }
    } catch (e) {
      _currentSuccessCalls = 0;
      _currentErrorCalls = 0;
      _connectivitySubject.add(false);
      return false;
    }
    _connectivitySubject.add(false);
    return false;
  }

  Future<void> dispose() async {
    await _connectivitySubject.close();
    await _getConnectivityStatusSubject.close();
  }
}

/// Helper exception to signal a success call
class _InsufficientConsecutiveCallsException implements Exception {}
