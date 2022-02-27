import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'device.dart';

class FoundDevicesScreen extends StatefulWidget {
  const FoundDevicesScreen({Key? key, required this.title}) : super(key: key);
  final String title;
  @override
  State<FoundDevicesScreen> createState() => _FoundDevicesScreenState();
}

class _FoundDevicesScreenState extends State<FoundDevicesScreen> {


  Future<void> _scanForDevices() async {
    FlutterBlue.instance.startScan(withServices: [serviceUUID],timeout: Duration(seconds: 10));
  }

  Future<void> connectAndNavigate(BuildContext context, BluetoothDevice device) async {
    FlutterBlue.instance.stopScan();
    //this is a fix for ghost connections
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
    FlutterBlue.instance.startScan(withServices: [serviceUUID],timeout: Duration(seconds: 10));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          PopupMenuButton(
              icon: const Icon(Icons.copyright),
              itemBuilder: (BuildContext context) => <PopupMenuEntry>[
                PopupMenuItem(
                  child: ListTile(
                    title: Text(AppLocalizations.of(context)!.licences),
                    onTap: () => showLicensePage(context: context),
                  ),
                )
              ]
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _scanForDevices,
        child: SingleChildScrollView(
          child: Column(
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
                                      title: Text(scanResult.device.name + ("  (RSSI: "'${scanResult.rssi}'")"),
                                        style: const TextStyle(fontSize: 18),),
                                      // leading: Text("RSSI: " + scanResult.rssi.toString()),
                                      onTap: (stateBuilder.data == BluetoothDeviceState.connected)
                                          ? () => navigateToDeviceScreen(context, scanResult.device)
                                          : () => connectAndNavigate(context, scanResult.device),
                                      trailing:  Ink(
                                        decoration: ShapeDecoration(
                                            shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(50.0),
                                                side: const BorderSide(
                                                    width: 2,
                                                    color: Colors.black12
                                                )
                                            ),
                                            color: Colors.blueGrey),
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
        tooltip: AppLocalizations.of(context)!.scanToolTip,
        child: const Icon(Icons.search),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}