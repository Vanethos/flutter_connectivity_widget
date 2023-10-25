import 'package:flutter/material.dart';
import 'package:connectivity_widget/connectivity_widget.dart';

void main() {
  /// Setup Connectivity Utils
  ConnectivityUtils.instance
    ..serverToPing =
        "https://gist.githubusercontent.com/Vanethos/dccc4b4605fc5c5aa4b9153dacc7391c/raw/355ccc0e06d0f84fdbdc83f5b8106065539d9781/gistfile1.txt"
    ..verifyResponseCallback =
        (response) => response.contains("This is a test!");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    //setup connectivity server to ping and callback

    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Connectivity Widget Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({required this.title, super.key});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ConnectivityWidget(
        onlineCallback: _incrementCounter,
        builder: (context, isOnline) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                isOnline ? 'Online' : 'Offline',
                style: TextStyle(
                    fontSize: 30, color: isOnline ? Colors.green : Colors.red),
              ),
              const SizedBox(
                height: 20,
              ),
              const Text(
                'Number of times we checked internet connection:',
              ),
              Text(
                '$_counter',
                style: Theme.of(context).textTheme.displayLarge,
              ),
            ],
          ),
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
