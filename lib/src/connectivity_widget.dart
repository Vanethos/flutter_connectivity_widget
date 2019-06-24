import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:stream_disposable/stream_disposable.dart';

import '../connectivity_widget.dart';
import 'event.dart';

typedef void OfflineCallback();
typedef void OnlineCallback();
typedef Widget ConnectivityBuilder(BuildContext context, bool isOnline);

class ConnectivityWidget extends StatefulWidget {
  final ConnectivityBuilder builder;
  final Widget offlineBanner;
  final OnlineCallback onlineCallback;
  final OfflineCallback offlineCallback;
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

    ConnectivityBloc.instance.checkInternetConnectivitySink.add(Event());

    animationController = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);

    if (dontAnimate == null &&
        !ConnectivityBloc.instance.connectivityStatusSubject.value) {
      this.animationController.value = 1.0;
    }

    disposable.add(
        ConnectivityBloc.instance.connectivityStatusStream.listen((status) {
      if (dontAnimate == null) {
        this.dontAnimate = true;
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
      builder: (context, snapshot) =>
          widget.builder(context, snapshot.data ?? true),
    );

    if (widget.showOfflineBanner) {
      child = Stack(
        children: <Widget>[
          child,
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
      );
    }

    return child;
  }
}

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
