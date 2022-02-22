import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class BluetoothOffScreen extends StatelessWidget {

  const BluetoothOffScreen({Key? key, this.state}): super(key: key);

  final BluetoothState? state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.bluetooth_disabled,
              size: 100.0,
              color: Colors.blueGrey,
            ),
            Text(
              AppLocalizations.of(context)!.bleOff,
              style: const TextStyle(fontSize: 24)
            ),
          ],
        ),
      ),
    );
  }
}