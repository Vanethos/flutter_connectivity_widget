import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:connectivity_widget/connectivity_widget.dart';
import 'package:connectivity_widget/src/event.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;

import 'mocks.dart';

void main() {
  group('ConnectivityUtils', () {
    late Connectivity connectivity;
    late http.Client client;
    late http.Response response;
    const serverToPing = "https://gpalma.pt";
    const duration = Duration(milliseconds: 500);

    setUp(() {
      connectivity = MockConnectivity();

      client = MockHttpClient();

      response = MockResponse();

      when(() => connectivity.onConnectivityChanged)
          .thenAnswer((_) => Stream.empty());

      when(() => client.get(Uri.parse("http://www.gstatic.com/generate_204")))
          .thenAnswer(
        (invocation) => Future.value(
          response,
        ),
      );

      when(() => response.statusCode).thenReturn(200);
      when(() => response.body).thenReturn('bananas');
    });

    group('Setters', () {
      test("we can set serverToPing", () async {
        final utils = ConnectivityUtils.test(
            connectivity: connectivity, httpClient: client);
        utils.serverToPing = serverToPing;
        expect(utils.serverToPing, serverToPing);
      });

      test("we can set duration", () async {
        final utils = ConnectivityUtils.test(
            connectivity: connectivity, httpClient: client);
        utils.debounceDuration = duration;
        expect(utils.debounceDuration, duration);
      });
    });

    group('isPhoneConnected', () {
      test('uses correct serverToPing', () async {
        final utils = ConnectivityUtils.test(
            connectivity: connectivity, httpClient: client);
        utils.serverToPing = serverToPing;
        when(() => client.get(Uri.parse(serverToPing))).thenAnswer(
          (invocation) => Future.value(
            response,
          ),
        );
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn('bananas');
        await utils.isPhoneConnected();
        expect(verify(() => client.get(Uri.parse(serverToPing))).callCount > 1,
            isTrue);
      });

      test('correct status code returns true', () async {
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn('bananas');
        when(() => client.get(Uri.parse(serverToPing))).thenAnswer(
          (invocation) => Future.value(
            response,
          ),
        );
        final utils = ConnectivityUtils.test(
            connectivity: connectivity, httpClient: client);
        utils.serverToPing = serverToPing;
        final result = await utils.isPhoneConnected();
        expect(result, isTrue);
      });

      test('incorrect status code returns false', () async {
        final utils = ConnectivityUtils.test(
            connectivity: connectivity, httpClient: client);
        utils.serverToPing = serverToPing;
        when(() => client.get(Uri.parse(serverToPing))).thenAnswer(
          (invocation) => Future.value(
            response,
          ),
        );
        when(() => response.statusCode).thenReturn(500);
        when(() => response.body).thenReturn('bananas');
        final result = await utils.isPhoneConnected();
        expect(result, isFalse);
      });

      test('if verify response callback returns true, we verify response',
          () async {
        final utils = ConnectivityUtils.test(
            connectivity: connectivity, httpClient: client);
        utils.serverToPing = serverToPing;
        utils.verifyResponseCallback = (_) => true;
        when(() => client.get(Uri.parse(serverToPing))).thenAnswer(
          (invocation) => Future.value(
            response,
          ),
        );
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn('bananas');
        final result = await utils.isPhoneConnected();
        expect(result, isTrue);
      });

      test(
          'if verify response callback returns false, we don\'t verify response',
          () async {
        final utils = ConnectivityUtils.test(
            connectivity: connectivity, httpClient: client);
        utils.serverToPing = serverToPing;
        utils.verifyResponseCallback = (_) => false;
        when(() => client.get(Uri.parse(serverToPing))).thenAnswer(
          (invocation) => Future.value(
            response,
          ),
        );
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn('bananas');
        final result = await utils.isPhoneConnected();
        expect(result, isFalse);
      });

      test('in onVerifyResponse we output the correct response', () async {
        final utils = ConnectivityUtils.test(
            connectivity: connectivity, httpClient: client);
        const body = 'bananas';
        utils.serverToPing = serverToPing;
        String? result;
        utils.verifyResponseCallback = (response) {
          result = response;
          return true;
        };
        when(() => client.get(Uri.parse(serverToPing))).thenAnswer(
          (invocation) => Future.value(
            response,
          ),
        );
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn(body);
        await utils.isPhoneConnected();
        expect(result, body);
      });
    });

    group('GetConnectivityStatus', () {
      test('does not have a default value', () async {
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn('bananas');
        when(() => client.get(Uri.parse(serverToPing))).thenAnswer(
          (invocation) => Future.value(
            response,
          ),
        );
        final utils = ConnectivityUtils.test(
            connectivity: connectivity, httpClient: client);
        expectLater(utils.isPhoneConnectedStream, emitsDone);
        await utils.dispose();
      });

      test('streams outputs isPhoneConnected status', () async {
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn('bananas');
        when(() => client.get(Uri.parse(serverToPing))).thenAnswer(
          (invocation) => Future.value(
            response,
          ),
        );
        final utils = ConnectivityUtils.test(
            connectivity: connectivity, httpClient: client);
        utils.serverToPing = serverToPing;
        utils.getConnectivityStatusSink.add(Event());
        utils.debounceDuration = duration;
        expectLater(
          utils.isPhoneConnectedStream,
          emitsInOrder(
            [isTrue],
          ),
        );
        await Future.delayed(Duration(seconds: 1));
        await utils.dispose();
      });

      test('only emits distinct values', () async {
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn('bananas');
        when(() => client.get(Uri.parse(serverToPing))).thenAnswer(
          (invocation) => Future.value(
            response,
          ),
        );
        final utils = ConnectivityUtils.test(
            connectivity: connectivity, httpClient: client);
        utils.serverToPing = serverToPing;
        utils.debounceDuration = duration;
        expectLater(utils.isPhoneConnectedStream, emitsInOrder([isTrue]));
        utils.getConnectivityStatusSink.add(Event());
        await Future.delayed(duration);
        await utils.dispose();
      });

      test('if server response changes, we emit false', () async {
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn('bananas');
        when(() => client.get(Uri.parse(serverToPing))).thenAnswer(
          (invocation) => Future.value(
            response,
          ),
        );
        final utils = ConnectivityUtils.test(
            connectivity: connectivity, httpClient: client);
        utils.serverToPing = serverToPing;
        utils.debounceDuration = duration;
        expectLater(
            utils.isPhoneConnectedStream, emitsInOrder([isTrue, isFalse]));
        utils.getConnectivityStatusSink.add(Event());
        await Future.delayed(Duration(seconds: 1));
        const newServerToPing = 'https://my.app';
        when(() => response.statusCode).thenReturn(500);
        when(() => response.body).thenReturn('bananas');
        when(() => client.get(Uri.parse(newServerToPing))).thenAnswer(
          (invocation) => Future.value(
            response,
          ),
        );
        utils.serverToPing = newServerToPing;

        await Future.delayed(Duration(seconds: 1));

        utils.getConnectivityStatusSink.add(Event());

        await utils.dispose();
      });
    });
  });
}
