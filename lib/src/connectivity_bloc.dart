import 'package:rxdart/rxdart.dart';

import '../connectivity_widget.dart';
import 'event.dart';

class ConnectivityBloc {

  /// Connectivity status
  var connectivityStatusSubject = BehaviorSubject<bool>(seedValue: true);

  Sink<bool> get connectivityStatusSink => connectivityStatusSubject.sink;

  Stream<bool> get connectivityStatusStream => connectivityStatusSubject.stream;

  /// Check the network status
  var _checkInternetConnectivitySubject = PublishSubject<Event>();

  Sink<Event> get checkInternetConnectivitySink =>
      _checkInternetConnectivitySubject.sink;

  ConnectivityBloc._() {

    ConnectivityUtils.instance
        .isPhoneConnectedStream
        .listen(connectivityStatusSink.add);

    _checkInternetConnectivitySubject.stream.listen(
            (_) => ConnectivityUtils.instance.getConnectivityStatusSink.add(Event()));
  }

  static final ConnectivityBloc _instance = ConnectivityBloc._();

  static ConnectivityBloc get instance {
    return _instance;
  }
}