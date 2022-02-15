import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'dart:convert';

import 'package:wifi_esp32_configurator/widgets.dart';

final Guid SERVICE_UUID = new Guid('4fafc201-1fb5-459e-8fcc-c5c9c331914b');
final Guid AVAILABE_NETWORKS_CHARACTERISTIC_UUID = new Guid('beb5483e-36e1-4688-b7f5-ea07361b26a8');
final Guid WIFI_SETUP_CHARACTERISTIC_UUID = new Guid('59a3861e-8d11-4f40-9597-912f562e4759');

//TODO: exract all Strings

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WiFi Configurator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: StreamBuilder<BluetoothState>(
        stream: FlutterBlue.instance.state,
        initialData: BluetoothState.unknown,
        builder: (stream, builder) {
          if (builder.data == BluetoothState.on) {
            return const FoundDevicesScreen(title: "WiFi Configurator (ESP32)");
          }
          return const BluetoothOffScreen();
        },
      ),
    );
  }
}

class FoundDevicesScreen extends StatefulWidget {
  const FoundDevicesScreen({Key? key, required this.title}) : super(key: key);
  final String title;
  @override
  State<FoundDevicesScreen> createState() => _FoundDevicesScreenState();
}

class _FoundDevicesScreenState extends State<FoundDevicesScreen> {


  Future<void> _scanForDevices() async {
    FlutterBlue.instance.startScan(withServices: [SERVICE_UUID],timeout: Duration(seconds: 10));
  }

  Future<void> connectAndNavigate(BuildContext context, BluetoothDevice device) async {
    FlutterBlue.instance.stopScan();
    //TODO: this is a fix for ghost connections
    await device.disconnect();
    await device.connect();
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) {
          return DeviceScreen(device: device);
       }));
  }

  void navigateToDeviceScreen(BuildContext context, BluetoothDevice device) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) {
      return DeviceScreen(device: device);
    }));
  }



  @override
  Widget build(BuildContext context) {
    FlutterBlue.instance.startScan(withServices: [SERVICE_UUID],timeout: Duration(seconds: 10));

    return Scaffold(
      appBar: AppBar(

        title: Text(widget.title),
      ),
      body: RefreshIndicator(
        onRefresh: _scanForDevices,
        child: SingleChildScrollView(
          child: Column(
            // TODO: maybe expansion tile
            children: <Widget>[
              StreamBuilder<List<ScanResult>>(
                stream: FlutterBlue.instance.scanResults,
                initialData: [],
                builder: (context, builder) => Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      ...builder.data!.map((scanResult) =>
                      StreamBuilder<BluetoothDeviceState>(
                        stream: scanResult.device.state,
                        initialData: BluetoothDeviceState.connecting,
                        builder: (stateContext, stateBuilder) => ListTile(
                        // TODO: maybe add device id
                        title: Text(scanResult.device.name + ("  (RSSI: "'${scanResult.rssi}'")"),
                          style: const TextStyle(fontSize: 18),),
                        // leading: Text("RSSI: " + scanResult.rssi.toString()),
                            //TODO: maybe ExpandTile with details infos
                        onTap: (stateBuilder.data == BluetoothDeviceState.connected)
                              ? () => navigateToDeviceScreen(context, scanResult.device)
                              : () => connectAndNavigate(context, scanResult.device),
                        trailing:  Ink(
                            decoration: ShapeDecoration(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                    side: const BorderSide(
                                        width: 2,
                                        color: Colors.black12
                                    )
                                ),
                                color: Colors.lightBlue),
                                  child: IconButton(
                                    color: Colors.white,
                                    icon: (stateBuilder.data == BluetoothDeviceState.connected)
                                        ? Icon(Icons.link_off)
                                        : Icon(Icons.link),
                                    onPressed: (stateBuilder.data == BluetoothDeviceState.connected)
                                        ? scanResult.device.disconnect
                                        : () => connectAndNavigate(context, scanResult.device)

                            ),
                          )
                        )
                      )).toList(),
                    ]
                  )
              )
            ]
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _scanForDevices,
        tooltip: 'Increment',
        child: const Icon(Icons.search),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({Key? key, required this.device}) : super(key: key);

  final BluetoothDevice device;

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}


class _DeviceScreenState extends State<DeviceScreen> {

  late Future<List<String>> _wifiNames;

  @override
  void initState() {
    super.initState();
    _wifiNames =  readWifiNames(widget.device);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            FutureBuilder<List<String>>(
                future: _wifiNames,
                initialData: [],
                builder: (context, builder)  {
                    if (builder.hasData) {
                      return Column(
                          children: builder.data!
                              .map((wifi) =>
                              ListTile(
                                  title: Text(wifi),
                                  leading: const Icon(Icons.wifi),
                                  trailing: IconButton(
                                    icon: Icon(Icons.link),
                                    onPressed: () => showDialog(
                                        context: context,
                                        builder: (builder) => _buildInputDialog(widget.device, wifi, context),
                                  )),
                                onTap: () => showDialog(
                                  context: context,
                                  builder: (builder) => _buildInputDialog(widget.device, wifi, context),
                          ),
                              )).toList()
                      );
                    } else {
                      return CircularProgressIndicator();
                    }
                  }
              )
          ],
        )
      )
    );
  }
  
  Future<BluetoothCharacteristic> getAvailableNetworksCharacteristics(BluetoothDevice device) async {
    final List<BluetoothService> services = await device.discoverServices();
    final BluetoothService service = services.firstWhere((service) => service.uuid == SERVICE_UUID);
    return service.characteristics
        .firstWhere((characteristics) => characteristics.uuid == AVAILABE_NETWORKS_CHARACTERISTIC_UUID);
  }

  Future<BluetoothCharacteristic> getWifiConfigCharacteristics(BluetoothDevice device) async {
    final List<BluetoothService> services = await device.discoverServices();
    final BluetoothService service = services.firstWhere((service) => service.uuid == SERVICE_UUID);
    return service.characteristics
        .firstWhere((characteristics) => characteristics.uuid == WIFI_SETUP_CHARACTERISTIC_UUID);
  }

  Future<List<String>> readWifiNames(BluetoothDevice device) async {
    //TODO: what about listening to the values?
    //TODO: build the screen here?
    final BluetoothCharacteristic availableNetworks = await getAvailableNetworksCharacteristics(device);

    List<int> bytes = await availableNetworks.read();
    String allNames = utf8.decode(bytes);
    return allNames.split('\n');
  }

  Widget _buildInputDialog(BluetoothDevice device, String ssid, BuildContext context) {

    final TextEditingController _inputController = TextEditingController();

    Future<void> _submitWifiCredentials(String password) async {
      final BluetoothCharacteristic wifiConfig = await getWifiConfigCharacteristics(device);
      String wifiCredentials = ssid + "\n" + password;
      await wifiConfig.write(utf8.encode(wifiCredentials));
    }

    return AlertDialog(
      content:
        TextField(
          controller: _inputController,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Enter the WiFi password',
            suffixIcon: IconButton(
              icon: Icon(Icons.delete),
              onPressed: _inputController.clear,
            )
          )
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context, 'Cancel'),
          child: const Text('Cancel'),
        ),
        TextButton(
          child: Text("Submit"),
          onPressed: () {
            //TODO: make method for this ?
            _submitWifiCredentials(_inputController.text);
            Navigator.pop(context, 'OK');
          },
        ),
      ],
    );
  }
}
