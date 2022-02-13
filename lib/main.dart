import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'dart:convert';

final Guid SERVICE_UUID = new Guid('4fafc201-1fb5-459e-8fcc-c5c9c331914b');
final Guid AVAILABE_NETWORKS_CHARACTERISTIC_UUID = new Guid('beb5483e-36e1-4688-b7f5-ea07361b26a8');
final Guid WIFI_SETUP_CHARACTERISTIC_UUID = new Guid('59a3861e-8d11-4f40-9597-912f562e4759');

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WiFi Configurator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'WiFi Configurator (ESP32)'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  Future<void> _scanForDevices() async {
    FlutterBlue.instance.startScan(withServices: [SERVICE_UUID],timeout: Duration(seconds: 10));
  }

  void connectAndNavigate(BuildContext context, BluetoothDevice device) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) {
          device.connect();
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
                    children: builder.data!.map((scanResult) => ListTile(
                        // TODO: maybe add device id
                        title: Text(scanResult.device.name),
                        leading: Text(scanResult.rssi.toString()),
                        trailing: StreamBuilder<BluetoothDeviceState>(
                          stream: scanResult.device.state,
                          initialData: BluetoothDeviceState.disconnected,
                          builder: (context, builder) => IconButton(
                            icon: (builder.data == BluetoothDeviceState.connected)
                              ? Icon(Icons.link_off)
                              : Icon(Icons.link),
                            onPressed: (builder.data == BluetoothDeviceState.connected)
                              ? scanResult.device.disconnect
                              : () => connectAndNavigate(context, scanResult.device)
                        )
                    )
                    )).toList(),
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

class DeviceScreen extends StatelessWidget {
  const DeviceScreen({Key? key, required this.device}) : super(key: key);

  final BluetoothDevice device;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(device.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            StreamBuilder<List<BluetoothService>>(
                stream: device.services,
                initialData: [],
                builder: (context, builder) => Column(
                  children: _buildWifiScreen(builder.data!),
                )
            )
          ],
        ),
      ),
    );
  }


  List<Widget> _buildWifiScreen(List<BluetoothService> services) {

    final BluetoothService wifiConfigService = services
        .firstWhere((service) => service.uuid == SERVICE_UUID);

    final BluetoothCharacteristic availableNetworks = wifiConfigService.characteristics
        .firstWhere((characterstics) => characterstics.uuid == AVAILABE_NETWORKS_CHARACTERISTIC_UUID);

    final BluetoothCharacteristic wifiConfig = wifiConfigService.characteristics
        .firstWhere((characterstics) => characterstics.uuid == WIFI_SETUP_CHARACTERISTIC_UUID);

    List<String> wifiNetworks;

    Future<void> doSomething() async {
      List<int> bytes = await availableNetworks.read();
      String allNames = utf8.decode(bytes);
      wifiNetworks = allNames.split('\n');
    }

    wifiNetworks.map((e) => ListTile()

    );
  }
}
