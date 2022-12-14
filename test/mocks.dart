import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:connectivity_widget/connectivity_widget.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;

class MockConnectivity extends Mock implements Connectivity {}

class MockHttpClient extends Mock implements http.Client {}

class MockResponse extends Mock implements http.Response {}

class MockConnectivityUtils extends Mock implements ConnectivityUtils {}
