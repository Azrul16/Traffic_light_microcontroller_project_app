import 'package:flutter/material.dart';
import 'connection.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: TrafficLightApp(),
    );
  }
}

class TrafficLightApp extends StatefulWidget {
  @override
  _TrafficLightAppState createState() => _TrafficLightAppState();
}

class _TrafficLightAppState extends State<TrafficLightApp> {
  final BluetoothConnectionHandler handler = BluetoothConnectionHandler();
  String statusMessage = "Disconnected";
  String deviceAddress =
      "6A:FF:39:44:8E:E9"; // Replace with your HC-05 device address
  Color bluetoothIconColor = Colors.red;

  @override
  void initState() {
    super.initState();
    requestBluetoothPermissions();
  }

  Future<void> requestBluetoothPermissions() async {
    bool permissionsGranted = await handler.requestPermissions();
    if (!permissionsGranted) {
      setState(() {
        statusMessage = "Permissions not granted";
      });
    }
  }

  Future<void> connectToBluetooth() async {
    setState(() {
      statusMessage = "Connecting...";
    });

    String connectionResult = await handler.connectToDevice(
      deviceAddress,
      (message) {
        setState(() {
          statusMessage = message;
        });
      },
    );

    setState(() {
      if (connectionResult.contains("Connected")) {
        bluetoothIconColor = Colors.green;
      } else {
        bluetoothIconColor = Colors.red;
      }
      statusMessage = connectionResult;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Traffic Light Control'),
        actions: [
          IconButton(
            icon: Icon(
              Icons.bluetooth,
              color: bluetoothIconColor,
            ),
            onPressed: connectToBluetooth,
          ),
        ],
      ),
      body: Center(
        child: Text(
          statusMessage,
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
