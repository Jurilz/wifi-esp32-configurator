
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:wifi_esp32_configurator/model/wifi_connection.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

final Guid serviceUUID = Guid('4fafc201-1fb5-459e-8fcc-c5c9c331914b');
final Guid availableNetworksCharacteristicsUUID = Guid('beb5483e-36e1-4688-b7f5-ea07361b26a8');
final Guid wifiSetupCharacteristicsUUID = Guid('59a3861e-8d11-4f40-9597-912f562e4759');

const String cancel = 'Cancel';
const String success = "SUCCESS";
const String closed = "CLOSED";

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({Key? key, required this.device}) : super(key: key);

  final BluetoothDevice device;

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {

  late Future<List<WiFiConnection>> _wifiNames;

  bool _isObscure = true;

  @override
  void initState() {
    super.initState();
    _wifiNames =  readWifiNames(widget.device);
  }

  Future<bool> _submitWifiCredentials(String ssid, String password) async {
    final BluetoothCharacteristic wifiConfig = await getWifiConfigCharacteristics(widget.device);
    String wifiCredentials = ssid + "\n" + password;
    await wifiConfig.write(utf8.encode(wifiCredentials));
    return readStatusAndDisconnect(widget.device, context);
  }

  Future<bool> _submitNameToOpenWiFi(String ssid) async {
    final BluetoothCharacteristic wifiConfig = await getWifiConfigCharacteristics(widget.device);
    String wifiCredentials = ssid + "\n" + "";
    await wifiConfig.write(utf8.encode(wifiCredentials));
    return readStatusAndDisconnect(widget.device, context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.name),
      ),
      body: FutureBuilder<List<WiFiConnection>>(
          future: _wifiNames,
          builder: (context, builder)  {
            if (builder.hasData) {
              return SingleChildScrollView(
                  child: Column(
                      children: builder.data!
                          .map((wifi) =>
                          ListTile(
                            title: Text(wifi.name),
                            leading: const Icon(Icons.wifi),
                            trailing: !wifi.openConnection ? const Icon(Icons.lock) : null,
                            onTap: () {
                              if (wifi.openConnection) {
                                connectToOpenWiFi(context, wifi);
                              } else {
                                askAndSendCredentials(context, wifi);
                              }
                            },
                          )).toList()
                  )
              );
            } else {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
          }
      ),
    );
  }

  Future<void> askAndSendCredentials(BuildContext context, WiFiConnection wifi) async {
    String pw = await showDialog(
        context: context,
        builder: (builder) => _buildInputDialog(widget.device, wifi, context)
    );
    if (pw == cancel) return;
    showDialog(
        context: context,
        builder: (builder) {
          return FutureBuilder<bool>(
              future: _submitWifiCredentials(wifi.name, pw),
              builder: (context, credentialBuilder) {
                if (credentialBuilder.hasData && credentialBuilder.data!) {
                  return AlertDialog(
                    content:
                    Text( AppLocalizations.of(context)!.connectionEstablished),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        child: const Text('Ok'),
                      )
                    ],
                  );
                } else if (credentialBuilder.hasData && !credentialBuilder.data!) {
                  return AlertDialog(
                    content:
                    Text( AppLocalizations.of(context)!.connectionFailed),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Ok'),
                      )
                    ],
                  );
                }
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
          );
        }
    );
  }

  Future<void> connectToOpenWiFi(BuildContext context, WiFiConnection wifi) async {
    bool connect = await showDialog(
        context: context,
        builder: (builder) => _buildOpenInputDialog(widget.device, wifi, context)
    );
    if (!connect) return;
    showDialog(
        context: context,
        builder: (builder) {
          return FutureBuilder<bool>(
              future: _submitNameToOpenWiFi(wifi.name),
              builder: (context, credentialBuilder) {
                if (credentialBuilder.hasData && credentialBuilder.data!) {
                  return AlertDialog(
                    content:
                    Text( AppLocalizations.of(context)!.connectionEstablished),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        child: const Text('Ok'),
                      )
                    ],
                  );
                } else if (credentialBuilder.hasData && !credentialBuilder.data!) {
                  return AlertDialog(
                    content:
                    Text( AppLocalizations.of(context)!.connectionFailed),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Ok'),
                      )
                    ],
                  );
                }
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
          );
        }
    );
  }

  Future<BluetoothCharacteristic> getAvailableNetworksCharacteristics(BluetoothDevice device) async {
    final List<BluetoothService> services = await device.discoverServices();
    final BluetoothService service = services.firstWhere((service) => service.uuid == serviceUUID);
    return service.characteristics
        .firstWhere((characteristics) => characteristics.uuid == availableNetworksCharacteristicsUUID);
  }

  Future<BluetoothCharacteristic> getWifiConfigCharacteristics(BluetoothDevice device) async {
    final List<BluetoothService> services = await device.discoverServices();
    final BluetoothService service = services.firstWhere((service) => service.uuid == serviceUUID);
    return service.characteristics
        .firstWhere((characteristics) => characteristics.uuid == wifiSetupCharacteristicsUUID);
  }

  Future<List<WiFiConnection>> readWifiNames(BluetoothDevice device) async {
    final BluetoothCharacteristic availableNetworks = await getAvailableNetworksCharacteristics(device);
    final List<int> bytes = await availableNetworks.read();
    final String allNames = utf8.decode(bytes);
    return WiFiConnection.convertFromString(allNames);
  }

  Widget _buildInputDialog(BluetoothDevice device, WiFiConnection wifi, BuildContext context) {

    final TextEditingController _inputController = TextEditingController();


    return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text("${AppLocalizations.of(context)!.wifi}: ${wifi.name}"),
            content:
            TextField(
                controller: _inputController,
                obscureText: _isObscure,
                decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.password,
                    border: const OutlineInputBorder(),
                    hintText: AppLocalizations.of(context)!.inputHint,
                    suffixIcon: IconButton(
                      icon: Icon(
                          _isObscure ? Icons.visibility : Icons.visibility_off
                      ),
                      onPressed: () {
                        setState(() {
                          _isObscure = !_isObscure;
                        });
                      },
                    )
                )
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, cancel),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              TextButton(
                child: Text(AppLocalizations.of(context)!.connect),
                onPressed: () {
                  Navigator.pop(context, _inputController.text);
                },
              ),
            ],
          );
        });
  }

  Widget _buildOpenInputDialog(BluetoothDevice device, WiFiConnection wifi, BuildContext context) {


    return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text("Connect to ${AppLocalizations.of(context)!.wifi}: ${wifi.name}?"),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              TextButton(
                child: Text(AppLocalizations.of(context)!.connect),
                onPressed: () {
                  Navigator.pop(context, true);
                },
              ),
            ],
          );
        });
  }

  Future<bool> readStatusAndDisconnect(BluetoothDevice device, BuildContext context) async {
    final BluetoothCharacteristic general = await getAvailableNetworksCharacteristics(device);
    List<int> bytes = await general.read();
    String status = utf8.decode(bytes);
    if (status == success) {
      general.write(utf8.encode(closed));
      device.disconnect();
      return true;
      // return AppLocalizations.of(context)!.connectionEstablished;
    } else {
      return false;
      // return AppLocalizations.of(context)!.connectionFailed;
    }
  }
}