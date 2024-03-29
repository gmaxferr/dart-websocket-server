import 'dart:io';

import 'package:dart_websocket_server/core/models/message.dart';
import 'package:dart_websocket_server/database/database.dart';

class DeviceManager {
  final MyDatabase database;
  DeviceManager(this.database);
  Map<String, WebSocket> connectedDevices = {};

  // Adds a device with the given deviceId. Returns true if added successfully, false if the deviceId is already in use.
  bool addDevice(String deviceId, WebSocket socket) {
    if (connectedDevices.containsKey(deviceId)) {
      // Device ID is already in use.
      connectedDevices[deviceId]!.close();
      connectedDevices[deviceId] = socket;
      print('Device $deviceId connected.');
      return true;
    } else {
      connectedDevices[deviceId] = socket;
      print('Device $deviceId connected.');
      return true;
    }
  }

  // Removes a device with the given deviceId.
  void removeDevice(String deviceId) {
    if (connectedDevices.containsKey(deviceId)) {
      connectedDevices.remove(deviceId);
      print('Device $deviceId disconnected.');
    }
  }

  // Sends a message to the device with the given deviceId. Returns true if the message was sent, false if the device is not connected.
  bool sendMessage(String deviceId, String message) {
    if (connectedDevices.containsKey(deviceId)) {
      connectedDevices[deviceId]?.add(message);
      return true;
    } else {
      // Device not connected or does not exist.
      return false;
    }
  }

  String? getDeviceResponseTo(String deviceId, String msgId) {
    String? response;
    List<Message> messages = database.getMessages(deviceId);

    messages = messages
        .where((element) =>
            element.content.contains(msgId) && element.sender == deviceId)
        .toList();

    response = messages.firstOrNull?.content;
    return response;
  }

  // Returns a list of currently connected device IDs.
  List<String> getConnectedDeviceIds() {
    return connectedDevices.keys.toList();
  }

  bool isConnected(String deviceId) {
    return connectedDevices.containsKey(deviceId);
  }
}
