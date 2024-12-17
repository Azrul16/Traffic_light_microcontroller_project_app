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

  // Connect to Bluetooth device
  Future<String> connectToDevice(
      String deviceAddress, Function(String) onMessageReceived) async {
    try {
      BluetoothDevice device = BluetoothDevice(address: deviceAddress);

      BluetoothConnection.toAddress(device.address).then((connection) {
        _connection = connection;

        _connection!.input!.listen((data) {
          String receivedMessage = String.fromCharCodes(data).trim();
          print("Received raw message: $receivedMessage");

          String time = _getCurrentTime();
          String messageWithTime = "$time - $receivedMessage";

          // Check if the message has been received before to avoid duplicates
          if (!_receivedMessages.contains(messageWithTime)) {
            if (receivedMessage == "c") {
              onMessageReceived(
                  "The Train entered, The gate is closing at $time");
            } else if (receivedMessage == "o") {
              onMessageReceived("The Train left, The gate is opening at $time");
            }
            _receivedMessages.add(messageWithTime); // Mark message as received
          }
        }).onError((error) {
          print("Error receiving data: $error");
        });
      }).catchError((e) {
        print("Error connecting to Bluetooth: $e");
        return 'Error connecting to Bluetooth: $e';
      });

      return 'Connected to the device!';
    } catch (e) {
      print("Error in connection attempt: $e");
      return 'Error connecting to Bluetooth: $e';
    }
  }

  // Disconnect from Bluetooth device
  Future<void> disconnect() async {
    await _connection?.close();
    print("Bluetooth connection closed.");
  }
}
