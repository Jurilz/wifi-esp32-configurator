import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:wifi_esp32_configurator/screens/found_devices.dart';

import 'package:wifi_esp32_configurator/widgets.dart';

const String appBarTitle = "WiFi Configurator (ESP32)";
const String appTitle = "WiFi Configurator";


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



