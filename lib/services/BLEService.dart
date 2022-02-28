
import 'dart:convert';

import 'package:flutter_blue/flutter_blue.dart';
import 'package:wifi_esp32_configurator/model/converter.dart';
import 'package:wifi_esp32_configurator/model/wifi_connection.dart';

final Guid serviceUUID = Guid('4fafc201-1fb5-459e-8fcc-c5c9c331914b');
final Guid availableNetworksCharacteristicsUUID = Guid('beb5483e-36e1-4688-b7f5-ea07361b26a8');
final Guid wifiSetupCharacteristicsUUID = Guid('59a3861e-8d11-4f40-9597-912f562e4759');

const String success = "SUCCESS";
const String closed = "CLOSED";

class BLEService {

  final Converter converter = Converter();

  Guid getServiceUUID() {
    return serviceUUID;
  }


  Future<BluetoothCharacteristic> _getAvailableNetworksCharacteristics(BluetoothDevice device) async {
    final List<BluetoothService> services = await device.discoverServices();
    final BluetoothService service = services.firstWhere((service) => service.uuid == serviceUUID);
    return service.characteristics
        .firstWhere((characteristics) => characteristics.uuid == availableNetworksCharacteristicsUUID);
  }

  Future<BluetoothCharacteristic> _getWifiConfigCharacteristics(BluetoothDevice device) async {
    final List<BluetoothService> services = await device.discoverServices();
    final BluetoothService service = services.firstWhere((service) => service.uuid == serviceUUID);
    return service.characteristics
        .firstWhere((characteristics) => characteristics.uuid == wifiSetupCharacteristicsUUID);
  }

  Future<List<WiFiConnection>> readWifiNames(BluetoothDevice device) async {
    final BluetoothCharacteristic availableNetworks = await _getAvailableNetworksCharacteristics(device);
    final List<int> bytes = await availableNetworks.read();
    final String allNames = utf8.decode(bytes);

    return allNames.split('\n')
        .where((element) => element.length > 2)
        .map((name) => converter.convertFromString(name)).toList();
  }

  Future<bool> _readStatusAndDisconnect(BluetoothDevice device) async {
    final BluetoothCharacteristic general = await _getAvailableNetworksCharacteristics(device);
    List<int> bytes = await general.read();
    String status = utf8.decode(bytes);
    if (status == success) {
      general.write(utf8.encode(closed));
      device.disconnect();
      return true;
    } else {
      return false;
    }
  }

  Future<bool> submitWifiCredentials(String ssid, String password, BluetoothDevice device) async {
    final BluetoothCharacteristic wifiConfig = await _getWifiConfigCharacteristics(device);
    String wifiCredentials = ssid + "\n" + password;
    await wifiConfig.write(utf8.encode(wifiCredentials));
    return _readStatusAndDisconnect(device);
  }

  Future<bool> submitNameToOpenWiFi(String ssid, BluetoothDevice device) async {
    final BluetoothCharacteristic wifiConfig = await _getWifiConfigCharacteristics(device);
    String wifiCredentials = ssid + "\n" + "";
    await wifiConfig.write(utf8.encode(wifiCredentials));
    return _readStatusAndDisconnect(device);
  }
}