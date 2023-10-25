import 'dart:async';

import 'package:connectivity_widget/connectivity_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'mocks.dart';

void main() {
  group('ConnectivityWidget', () {
    late ConnectivityUtils utils;

    testWidgets('when we have no connection, we show the default widget',
        (tester) async {
      utils = MockConnectivityUtils();

      when(() => utils.getPhoneConnection).thenReturn(false);
      when(() => utils.isPhoneConnectedStream).thenAnswer(
        (_) => Stream.value(false).asBroadcastStream(),
      );

      ConnectivityUtils.setInstance(utils);

      await tester.pumpWidget(TestShell(
        widget: ConnectivityWidget(
          builder: (context, isOnline) {
            return Container();
          },
        ),
      ));

      await tester.pumpAndSettle();

      expect(find.byType(NoConnectivityBanner), findsOneWidget);
    });

    testWidgets('when we have connection, we show don\'t  the default widget',
        (tester) async {
      utils = MockConnectivityUtils();

      when(() => utils.getPhoneConnection).thenReturn(true);
      when(() => utils.isPhoneConnectedStream).thenAnswer(
        (_) => Stream.value(true).asBroadcastStream(),
      );

      ConnectivityUtils.setInstance(utils);

      await tester.pumpWidget(TestShell(
        widget: ConnectivityWidget(
          builder: (context, isOnline) {
            return Container();
          },
        ),
      ));

      await tester.pumpAndSettle();

      expect(find.byType(NoConnectivityBanner), findsNothing);
    });

    testWidgets('we show custom banner when offline', (tester) async {
      utils = MockConnectivityUtils();

      when(() => utils.getPhoneConnection).thenReturn(false);
      when(() => utils.isPhoneConnectedStream).thenAnswer(
        (_) => Stream.value(false).asBroadcastStream(),
      );

      ConnectivityUtils.setInstance(utils);

      await tester.pumpWidget(TestShell(
        widget: ConnectivityWidget(
          offlineBanner: CustomBanner(),
          builder: (context, isOnline) {
            return Container();
          },
        ),
      ));

      await tester.pumpAndSettle();

      expect(find.byType(CustomBanner), findsOneWidget);
    });

    testWidgets('if showOfflineBanner is false, we don\'t show the banner',
        (tester) async {
      utils = MockConnectivityUtils();

      when(() => utils.getPhoneConnection).thenReturn(false);
      when(() => utils.isPhoneConnectedStream).thenAnswer(
        (_) => Stream.value(false).asBroadcastStream(),
      );

      ConnectivityUtils.setInstance(utils);

      await tester.pumpWidget(TestShell(
        widget: ConnectivityWidget(
          showOfflineBanner: false,
          builder: (context, isOnline) {
            return Container();
          },
        ),
      ));

      await tester.pumpAndSettle();

      expect(find.byType(NoConnectivityBanner), findsNothing);
    });

    testWidgets('we don\'t show custom banner when online', (tester) async {
      utils = MockConnectivityUtils();

      when(() => utils.getPhoneConnection).thenReturn(true);
      when(() => utils.isPhoneConnectedStream).thenAnswer(
        (_) => Stream.value(true).asBroadcastStream(),
      );

      ConnectivityUtils.setInstance(utils);

      await tester.pumpWidget(TestShell(
        widget: ConnectivityWidget(
          offlineBanner: CustomBanner(),
          builder: (context, isOnline) {
            return Container();
          },
        ),
      ));

      await tester.pumpAndSettle();

      expect(find.byType(CustomBanner), findsNothing);
    });

    testWidgets('we show our child widget when offline', (tester) async {
      utils = MockConnectivityUtils();

      when(() => utils.getPhoneConnection).thenReturn(false);
      when(() => utils.isPhoneConnectedStream).thenAnswer(
        (_) => Stream.value(false).asBroadcastStream(),
      );

      final child = Text("Bananas");

      ConnectivityUtils.setInstance(utils);

      await tester.pumpWidget(TestShell(
        widget: ConnectivityWidget(
          showOfflineBanner: false,
          builder: (context, isOnline) {
            return child;
          },
        ),
      ));

      await tester.pumpAndSettle();

      expect(find.byWidget(child), findsOneWidget);
    });

    testWidgets('we show our child widget when online', (tester) async {
      utils = MockConnectivityUtils();

      when(() => utils.getPhoneConnection).thenReturn(true);
      when(() => utils.isPhoneConnectedStream).thenAnswer(
        (_) => Stream.value(true).asBroadcastStream(),
      );

      final child = Text("Bananas");

      ConnectivityUtils.setInstance(utils);

      await tester.pumpWidget(TestShell(
        widget: ConnectivityWidget(
          showOfflineBanner: false,
          builder: (context, isOnline) {
            return child;
          },
        ),
      ));

      await tester.pumpAndSettle();

      expect(find.byWidget(child), findsOneWidget);
    });

    testWidgets('offlineCallback is called only when going offline',
        (tester) async {
      utils = MockConnectivityUtils();

      final controller = StreamController<bool>.broadcast();

      when(() => utils.getPhoneConnection).thenReturn(true);
      when(() => utils.isPhoneConnectedStream)
          .thenAnswer((_) => controller.stream);

      int called = 0;

      ConnectivityUtils.setInstance(utils);

      await tester.pumpWidget(TestShell(
        widget: ConnectivityWidget(
          offlineCallback: () => called++,
          builder: (context, isOnline) {
            return Container();
          },
        ),
      ));

      controller.add(true);

      await tester.pumpAndSettle();

      controller.add(false);

      await tester.pumpAndSettle();

      expect(called, 1);

      await controller.close();
    });

    testWidgets('onlineCallback is called only when going online',
        (tester) async {
      utils = MockConnectivityUtils();

      final controller = StreamController<bool>.broadcast();

      when(() => utils.getPhoneConnection).thenReturn(false);
      when(() => utils.isPhoneConnectedStream)
          .thenAnswer((_) => controller.stream);

      int called = 0;

      ConnectivityUtils.setInstance(utils);

      await tester.pumpWidget(TestShell(
        widget: ConnectivityWidget(
          onlineCallback: () => called++,
          builder: (context, isOnline) {
            return Container();
          },
        ),
      ));

      controller.add(true);

      await tester.pumpAndSettle();

      controller.add(false);

      await tester.pumpAndSettle();

      expect(called, 1);

      await controller.close();
    });

    testWidgets('the loading widget is shown before we receive any data',
        (tester) async {
      utils = MockConnectivityUtils();

      final controller = StreamController<bool>.broadcast();

      when(() => utils.getPhoneConnection).thenReturn(false);
      when(() => utils.isPhoneConnectedStream)
          .thenAnswer((_) => controller.stream);

      ConnectivityUtils.setInstance(utils);

      final expectedText = "Loading the widget";

      await tester.pumpWidget(TestShell(
        widget: ConnectivityWidget(
          initialLoadingWidget: Text(expectedText),
          builder: (context, isOnline) {
            return Container();
          },
        ),
      ));

      await tester.pump(
        Duration(
          milliseconds: 500,
        ),
      );

      expect(find.text(expectedText), findsOneWidget);

      await controller.close();
    });

    testWidgets(
        'by default, the loading widget is a [CircularProgressIndicator]',
        (tester) async {
      utils = MockConnectivityUtils();

      final controller = StreamController<bool>.broadcast();

      when(() => utils.getPhoneConnection).thenReturn(false);
      when(() => utils.isPhoneConnectedStream)
          .thenAnswer((_) => controller.stream);

      ConnectivityUtils.setInstance(utils);

      await tester.pumpWidget(TestShell(
        widget: ConnectivityWidget(
          builder: (context, isOnline) {
            return Container();
          },
        ),
      ));

      await tester.pump(
        Duration(
          milliseconds: 500,
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await controller.close();
    });

    testWidgets('builder is called with correct value', (tester) async {
      utils = MockConnectivityUtils();

      final controller = StreamController<bool>.broadcast();

      when(() => utils.getPhoneConnection).thenReturn(false);
      when(() => utils.isPhoneConnectedStream)
          .thenAnswer((_) => controller.stream);

      bool? online;

      ConnectivityUtils.setInstance(utils);

      await tester.pumpWidget(
        TestShell(
          widget: ConnectivityWidget(
            builder: (context, isOnline) {
              online = isOnline;
              return Container();
            },
          ),
        ),
      );

      controller.add(true);

      await tester.pump(
        Duration(
          milliseconds: 500,
        ),
      );

      expect(online, isTrue);

      await controller.close();
    });

    testWidgets('builder is called with the updated value', (tester) async {
      utils = MockConnectivityUtils();

      final controller = StreamController<bool>.broadcast();

      when(() => utils.getPhoneConnection).thenReturn(false);
      when(() => utils.isPhoneConnectedStream)
          .thenAnswer((_) => controller.stream);

      bool? online;

      ConnectivityUtils.setInstance(utils);

      await tester.pumpWidget(TestShell(
        widget: ConnectivityWidget(
          builder: (context, isOnline) {
            online = isOnline;
            return Container();
          },
        ),
      ));

      controller.add(true);

      await tester.pump(
        Duration(
          milliseconds: 500,
        ),
      );

      controller.add(false);

      await tester.pump(
        Duration(
          milliseconds: 500,
        ),
      );

      expect(online, isFalse);

      await controller.close();
    });
  });
}

class TestShell extends StatelessWidget {
  final Widget widget;

  const TestShell({required this.widget, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: widget,
    );
  }
}

class CustomBanner extends StatelessWidget {
  const CustomBanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.red,
      height: 200,
      width: 200,
    );
  }
}
