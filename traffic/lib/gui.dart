import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'connection.dart';

class BluetoothHome extends StatefulWidget {
  @override
  _BluetoothHomeState createState() => _BluetoothHomeState();
}

class _BluetoothHomeState extends State<BluetoothHome> {
  BluetoothConnectionHandler _bluetoothHandler = BluetoothConnectionHandler();
  List<String> _messages = []; // Store incoming messages
  bool _isConnected = false;
  String _connectionStateMessage = 'Waiting for connection...';

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _loadMessages();
  }

  // Request necessary Bluetooth permissions and show appropriate message
  Future<void> _requestPermissions() async {
    bool isGranted = await _bluetoothHandler.requestPermissions();
    setState(() {
      if (isGranted) {
        _connectionStateMessage = 'Bluetooth Permissions granted.';
      } else {
        _connectionStateMessage = 'Please grant Bluetooth permissions.';
      }
    });
  }

  // Load messages from SharedPreferences
  Future<void> _loadMessages() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _messages = prefs.getStringList('messages') ?? [];
    });
  }

  // Save messages to SharedPreferences
  Future<void> _saveMessages() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('messages', _messages);
  }

  // Connect to Bluetooth device
  void _connectToBluetooth() async {
    String connectionMessage =
        await _bluetoothHandler.connectToDevice('00:23:09:01:73:D7', (message) {
      setState(() {
        _messages.insert(0, message); // Add message to the top of the list
        _saveMessages(); // Save updated messages list to SharedPreferences
      });
    });
    setState(() {
      _isConnected = true;
      _connectionStateMessage = connectionMessage;
    });
  }

  // Disconnect from Bluetooth device
  void _disconnectFromBluetooth() async {
    await _bluetoothHandler.disconnect();
    setState(() {
      _isConnected = false;
      _connectionStateMessage = 'Disconnected from the device.';
    });
  }

  @override
  void dispose() {
    _bluetoothHandler.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bluetooth Device Connection'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(
              _isConnected
                  ? Icons.bluetooth_connected
                  : Icons.bluetooth_disabled,
              color: _isConnected ? Colors.green : Colors.red,
              size: 40,
            ),
            onPressed:
                _isConnected ? _disconnectFromBluetooth : _connectToBluetooth,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true, // Display messages from bottom
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  color: Colors.blue[100],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                    child: Text(
                      _messages[index],
                      style: TextStyle(fontSize: 18, color: Colors.black),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              _connectionStateMessage,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
