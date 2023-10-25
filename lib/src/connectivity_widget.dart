import 'package:flutter/material.dart';
import 'package:stream_disposable/stream_disposable.dart';

import '../connectivity_widget.dart';

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
  final VoidCallback? onlineCallback;

  /// Callback for when the device is offline
  ///
  /// Example:
  ///
  /// `onlineCallback: () => _decrementCounter()`
  final VoidCallback? offlineCallback;

  /// OfflineBanner to be shown at the bottom of the widget
  ///
  /// If none is provided, the [NoConnectivityBanner] is shown
  final Widget? offlineBanner;

  /// Flag to show or hide the [offlineBanner]
  final bool showOfflineBanner;

  /// Disables animations
  final bool disableAnimations;

  /// Loader widget to show while the first connection check is in progress
  final Widget? initialLoadingWidget;

  ConnectivityWidget(
      {required this.builder,
      this.onlineCallback,
      this.offlineCallback,
      this.showOfflineBanner = true,
      this.disableAnimations = false,
      this.offlineBanner,
      this.initialLoadingWidget,
      Key? key})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => ConnectivityWidgetState();
}

class ConnectivityWidgetState extends State<ConnectivityWidget>
    with SingleTickerProviderStateMixin {
  late bool _dontAnimate;

  AnimationController? _animationController;

  StreamDisposable _disposable = StreamDisposable();

  Stream<bool> _connectedStream =
      ConnectivityUtils.instance.isPhoneConnectedStream;

  @override
  @mustCallSuper
  void initState() {
    super.initState();

    _dontAnimate = widget.disableAnimations;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    if (!_dontAnimate &&
        !(ConnectivityUtils.instance.getPhoneConnection ?? false)) {
      this._dontAnimate = true;
      this._animationController?.value = 1.0;
    }

    _disposable.add(
      _connectedStream.listen(
        (status) {
          /// At the start, if we have a status set, we must consider that we came from another screen with that status
          if (!_dontAnimate) {
            this._dontAnimate = true;
            if (!(ConnectivityUtils.instance.getPhoneConnection ?? false)) {
              this._animationController?.value = 1.0;
            }
            return;
          }

          if (!status) {
            this._animationController?.forward();
            if (widget.offlineCallback != null) widget.offlineCallback!();
          } else {
            this._animationController?.reverse();
            if (widget.onlineCallback != null) widget.onlineCallback!();
          }
          this._dontAnimate = true;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget child = StreamBuilder<bool>(
      stream: _connectedStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return widget.initialLoadingWidget ??
              Center(
                child: CircularProgressIndicator(),
              );
        }

        return Stack(
          children: <Widget>[
            widget.builder.call(context, snapshot.data ?? true),
            if (widget.showOfflineBanner &&
                !(snapshot.data ?? true) &&
                _animationController != null)
              Align(
                alignment: Alignment.bottomCenter,
                child: SlideTransition(
                  position: _animationController!.drive(
                    Tween<Offset>(
                      begin: const Offset(0.0, 1.0),
                      end: Offset.zero,
                    ).chain(
                      CurveTween(
                        curve: Curves.fastOutSlowIn,
                      ),
                    ),
                  ),
                  child: widget.offlineBanner ?? NoConnectivityBanner(),
                ),
              )
          ],
        );
      },
    );
    return child;
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _disposable.dispose();
    super.dispose();
  }
}

/// Default Banner for offline mode
class NoConnectivityBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8),
      width: double.infinity,
      color: Colors.red,
      child: Text(
        "No connectivity",
        style: TextStyle(
          fontSize: 16,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
