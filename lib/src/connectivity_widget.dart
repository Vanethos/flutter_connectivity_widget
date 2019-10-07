import 'package:flutter/material.dart';
import 'package:stream_disposable/stream_disposable.dart';

import '../connectivity_widget.dart';

/// Callback to be called when the phone is in offline mode
typedef void OfflineCallback();

/// Callback to be called when the phone is in online mode
typedef void OnlineCallback();

/// Builder method with [isOnline] parameter to build widgets
/// in function of the connectivity status
typedef Widget ConnectivityBuilder(BuildContext context, bool isOnline);

/// Connectivity Widget
///
/// Widget that is aware of the network status from the network.
///
/// Has a a [builder] parameter so that the child widget can be built in
/// accordance to the online/offline status.
///
/// A [onlineCallback] and [offlineCallback] are provided so that methods can
/// be called when the device is turned online or offline, respectively
///
/// [offlineBanner] is the banner to be shown at the bottom of the child widget
/// created in the [builder]. Its visibility can be switched off with the [offlineBanner]
/// parameter
///
/// Example:
///
/// ```
///   ConnectivityWidget(
///        onlineCallback: _incrementCounter,
///        builder: (context, isOnline) => Center(
///          child: Column(
///            mainAxisAlignment: MainAxisAlignment.center,
///            children: <Widget>[
///              Text("${isOnline ? 'Online' : 'Offline'}", style: TextStyle(fontSize: 30, color: isOnline ? Colors.green : Colors.red),),
///              SizedBox(height: 20,),
///              Text(
///                'Number of times we connected to the internet:',
///              ),
///              Text(
///                '$_counter',
///                style: Theme.of(context).textTheme.display1,
///              ),
///            ],
///          ),
///        ),
///      )
/// ```
class ConnectivityWidget extends StatefulWidget {
  /// Builder method for the child widget.
  ///
  /// Provides a [iSOnline] parameter and a [context] to build the child
  final ConnectivityBuilder builder;

  /// Callback for when the device is online
  ///
  /// Example:
  ///
  /// `onlineCallback: () => _incrementCounter()`
  final OnlineCallback onlineCallback;

  /// Callback for when the device is offline
  ///
  /// Example:
  ///
  /// `onlineCallback: () => _decrementCounter()`
  final OfflineCallback offlineCallback;

  /// OfflineBanner to be shown at the bottom of the widget
  ///
  /// If none is provided, the [_NoConnectivityBanner] is shown
  final Widget offlineBanner;

  /// Flag to show or hide the [offlineBanner]
  final bool showOfflineBanner;

  ConnectivityWidget(
      {this.builder,
      this.onlineCallback,
      this.offlineCallback,
      this.showOfflineBanner = true,
      this.offlineBanner,
      Key key})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => ConnectivityWidgetState();
}

class ConnectivityWidgetState extends State<ConnectivityWidget>
    with SingleTickerProviderStateMixin {
  bool dontAnimate;

  AnimationController animationController;

  StreamDisposable disposable = StreamDisposable();

  @override
  @mustCallSuper
  void initState() {
    super.initState();

    animationController = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);

    if (dontAnimate == null &&
        !(ConnectivityBloc.instance.connectivityStatusSubject.value ?? true)) {
      this.animationController.value = 1.0;
    }

    disposable.add(
        ConnectivityBloc.instance.connectivityStatusStream.listen((status) {
      /// At the start, if we have a status set, we must consider that we came from another screen with that status
      if (dontAnimate == null) {
        this.dontAnimate = true;
        if (!(ConnectivityBloc.instance.connectivityStatusSubject.value ?? true)) {
          this.animationController.value = 1.0;
        }
        return;
      }
      if (!status) {
        this.animationController.forward();
        if (widget.offlineCallback != null) widget.offlineCallback();
      } else {
        this.animationController.reverse();
        if (widget.onlineCallback != null) widget.onlineCallback();
      }
      this.dontAnimate = true;
    }));
  }

  @override
  Widget build(BuildContext context) {
    Widget child = StreamBuilder(
      stream: ConnectivityBloc.instance.connectivityStatusStream,
      builder: (context, snapshot) => Stack(
        children: <Widget>[
          widget.builder(context, snapshot.data ?? true),
          if (widget.showOfflineBanner && !(snapshot.data ?? true))
            Align(
                alignment: Alignment.bottomCenter,
                child: SlideTransition(
                    position: animationController.drive(Tween<Offset>(
                      begin: const Offset(0.0, 1.0),
                      end: Offset.zero,
                    ).chain(CurveTween(
                      curve: Curves.fastOutSlowIn,
                    ))),
                    child: widget.offlineBanner ?? _NoConnectivityBanner()))
        ],
      )
    );
    return child;
  }
}


/// Default Banner for offline mode
class _NoConnectivityBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.all(8),
        width: double.infinity,
        color: Colors.red,
        child: Text(
          "No connectivity",
          style: TextStyle(
              fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ));
  }
}
