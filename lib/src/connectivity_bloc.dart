import 'package:rxdart/rxdart.dart';

import 'connectivity_util.dart';
import 'event.dart';

/// Connectivity Bloc for [ConnectivityWidget]
///
/// Bloc that holds the state of the [ConnectivityWidget] and verifies with
/// the [ConnectivityUtils] if there is a connection to the internet
class ConnectivityBloc {

  /// Connectivity status Stream
  var connectivityStatusSubject = BehaviorSubject<bool>();

  Sink<bool> get connectivityStatusSink => connectivityStatusSubject.sink;

  Stream<bool> get connectivityStatusStream => connectivityStatusSubject.stream;

  /// Check the network status
  var _checkInternetConnectivitySubject = PublishSubject<Event>();

  Sink<Event> get checkInternetConnectivitySink =>
      _checkInternetConnectivitySubject.sink;

  ConnectivityBloc._() {
    /// Listens for the value from [ConnectivityUtils] and sends a new event
    /// to the [ConnectivityWidget]
    ConnectivityUtils.instance.isPhoneConnectedStream
        .listen((value) {
          if (value != null) connectivityStatusSink.add(value);
    });

    _checkInternetConnectivitySubject.stream.listen((_) =>
        ConnectivityUtils.instance.getConnectivityStatusSink.add(Event()));
  }

  static final ConnectivityBloc _instance = ConnectivityBloc._();

  static ConnectivityBloc get instance {
    return _instance;
  }
}
