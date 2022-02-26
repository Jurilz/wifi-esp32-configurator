import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'dart:convert';

import 'package:wifi_esp32_configurator/widgets.dart';

final Guid serviceUUID = Guid('4fafc201-1fb5-459e-8fcc-c5c9c331914b');
final Guid availableNetworksCharacteristicsUUID = Guid('beb5483e-36e1-4688-b7f5-ea07361b26a8');
final Guid wifiSetupCharacteristicsUUID = Guid('59a3861e-8d11-4f40-9597-912f562e4759');


const String appBarTitle = "WiFi Configurator (ESP32)";
const String appTitle = "WiFi Configurator";
const String success = "SUCCESS";
const String closed = "CLOSED";
const String cancel = 'Cancel';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    addLicences();
    return MaterialApp(
      title: appTitle,
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: StreamBuilder<BluetoothState>(
        stream: FlutterBlue.instance.state,
        initialData: BluetoothState.unknown,
        builder: (stream, builder) {
          if (builder.data == BluetoothState.on) {
            return const FoundDevicesScreen(title: appBarTitle);
          }
          return const BluetoothOffScreen();
        },
      ),
    );
  }

  void addLicences() {
    LicenseRegistry.addLicense(() async* {
      yield const LicenseEntryWithLineBreaks(<String>['Wifi icons created by Freepik - Flaticon'], "https://www.flaticon.com/free-icons/wifi"
      );
      yield const LicenseEntryWithLineBreaks(<String>['Bluetooth icons created by Smashicons - Flaticon'], "https://www.flaticon.com/free-icons/bluetooth"
      );
    });
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
    FlutterBlue.instance.startScan(withServices: [serviceUUID],timeout: Duration(seconds: 10));
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

  Future<String> _submitWifiCredentials(String ssid, String password) async {
    final BluetoothCharacteristic wifiConfig = await getWifiConfigCharacteristics(widget.device);
    String wifiCredentials = ssid + "\n" + password;
    await wifiConfig.write(utf8.encode(wifiCredentials));
    return readStatusAndDisconnect(widget.device, context);
  }

  Future<String> _submitNameToOpenWiFi(String ssid) async {
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
           return FutureBuilder<String>(
               future: _submitWifiCredentials(wifi.name, pw),
               builder: (context, credentialBuilder) {
                 if (credentialBuilder.hasData) {
                   return AlertDialog(
                     content:
                       Text(credentialBuilder.data!),
                       actions: <Widget>[
                         TextButton(
                           onPressed: () {
                             if (credentialBuilder.data! == AppLocalizations.of(context)!.connectionEstablished) {
                               Navigator.pop(context);
                               Navigator.pop(context);
                             } else {
                               Navigator.pop(context);
                             }
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
          return FutureBuilder<String>(
              future: _submitNameToOpenWiFi(wifi.name),
              builder: (context, credentialBuilder) {
                if (credentialBuilder.hasData) {
                  return AlertDialog(
                    content:
                    Text(credentialBuilder.data!),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () {
                          if (credentialBuilder.data! == AppLocalizations.of(context)!.connectionEstablished) {
                            Navigator.pop(context);
                            Navigator.pop(context);
                          } else {
                            Navigator.pop(context);
                          }
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
    return convertFromString(allNames);
  }

  List<WiFiConnection> convertFromString(String names) {
    final List<String> namesAsList = names.split('\n');
    List<WiFiConnection> result = [];
    for (String nameStringEncoded in namesAsList) {
      if (nameStringEncoded.isEmpty) continue;
      String connectionType = nameStringEncoded.substring(nameStringEncoded.length - 1);
      String name = nameStringEncoded.substring(0, (nameStringEncoded.length - 1));
      result.add(WiFiConnection(name: name, openConnection: (connectionType == "0") ? true : false));
    }
    return result;
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

  //TODO: maybe in try block
  Future<String> readStatusAndDisconnect(BluetoothDevice device, BuildContext context) async {
    final BluetoothCharacteristic general = await getAvailableNetworksCharacteristics(device);
    List<int> bytes = await general.read();
    String status = utf8.decode(bytes);
    if (status == success) {
      await device.disconnect();
      return AppLocalizations.of(context)!.connectionEstablished;
    } else {
      return AppLocalizations.of(context)!.connectionFailed;
    }
  }
}

class WiFiConnection {
  final String name;
  final bool openConnection;

  const WiFiConnection({
    required this.name,
    required this.openConnection
  });
}
