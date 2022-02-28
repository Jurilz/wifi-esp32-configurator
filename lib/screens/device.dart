
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:wifi_esp32_configurator/model/wifi_connection.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:wifi_esp32_configurator/services/BLEService.dart';

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

  BLEService bleService = BLEService();


  bool _isObscure = true;

  @override
  void initState() {
    super.initState();
    _wifiNames =  bleService.readWifiNames(widget.device);
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
              future: bleService.submitWifiCredentials(wifi.name, pw, widget.device),
              builder: (context, credentialBuilder) {
                if (credentialBuilder.hasData && credentialBuilder.data!) {
                  return AlertDialog(
                    content:
                    Text(AppLocalizations.of(context)!.connectionEstablished),
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
                    Text(AppLocalizations.of(context)!.connectionFailed),
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
              future: bleService.submitNameToOpenWiFi(wifi.name, widget.device),
              builder: (context, credentialBuilder) {
                if (credentialBuilder.hasData && credentialBuilder.data!) {
                  return AlertDialog(
                    content:
                    Text(AppLocalizations.of(context)!.connectionEstablished),
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
                    Text(AppLocalizations.of(context)!.connectionFailed),
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
}