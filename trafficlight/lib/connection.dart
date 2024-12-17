import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

class BluetoothConnectionHandler {
  BluetoothConnection? _connection;
  final Set<String> _receivedMessages = {}; // Store unique messages

  // Request necessary Bluetooth permissions
  Future<bool> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
    ].request();

    return statuses.values.every((status) => status.isGranted);
  }

  // Get the current time in HH:MM format
  String _getCurrentTime() {
    final now = DateTime.now();
    final formatter = DateFormat('HH:mm');
    return formatter.format(now);
  }

  // Method to validate Bluetooth MAC address
  bool isValidBluetoothAddress(String address) {
    final regex = RegExp(r'^([0-9A-Fa-f]{2}[:]){5}[0-9A-Fa-f]{2}$');
    return regex.hasMatch(address);
  }

  // Connect to Bluetooth device without password
  Future<String> connectToDevice(
      String deviceAddress, Function(String) onMessageReceived) async {
    try {
      // Validate Bluetooth address
      if (!isValidBluetoothAddress(deviceAddress)) {
        throw Exception("Invalid Bluetooth address: $deviceAddress");
      }

      BluetoothConnection connection =
          await BluetoothConnection.toAddress(deviceAddress);

      _connection = connection;
      print("Connected to the device!");

      // Listen to incoming data
      _connection!.input!.listen((data) {
        String receivedMessage = String.fromCharCodes(data).trim();
        print("Received message: $receivedMessage");

        String time = _getCurrentTime();
        String messageWithTime = "$time - $receivedMessage";

        if (!_receivedMessages.contains(messageWithTime)) {
          if (receivedMessage == "c") {
            onMessageReceived(
                "The Train entered, The gate is closing at $time");
          } else if (receivedMessage == "o") {
            onMessageReceived("The Train left, The gate is opening at $time");
          }
          _receivedMessages.add(messageWithTime);
        }
      }).onError((error) {
        print("Error receiving data: $error");
      });

      return 'Connected to the device!';
    } catch (e) {
      print("Error connecting to Bluetooth: $e");
      return 'Error connecting to Bluetooth: $e';
    }
  }

  // Disconnect from Bluetooth device
  Future<void> disconnect() async {
    await _connection?.close();
    print("Bluetooth connection closed.");
  }
}
