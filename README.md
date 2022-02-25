# WiFi Configurator App for ESP32 Controller

This Flutter Application allows you to set WiFi credentials on an ESP32 controller via a BLE connection.

It was developed to be used in combination with the [ESP32 WiFi Configuration](https://github.com/Jurilz/esp32_wifi_lib) Library for ESP32 Controller, although it can be used with any BLE Server, which implements the API.

## API

### BLE Service Scan
As a BLE Client the App scans for availble BLE Devices, that offer (resp. advertise) a BLE Service with the UUID `4fafc201-1fb5-459e-8fcc-c5c9c331914b`

### BLE Characteristics
The BLE Service is expected to provide two Characteristics:

* Available Networks Characteristics
* WiFi Configuration

### Available Networks Characteristics
UUID: `beb5483e-36e1-4688-b7f5-ea07361b26a8`

The App expects to read a list of avaible WiFi Networks from these Characteristics. The SSIDs are expected to seperated by a newline character (`\n`) and encoded as a byte array.

The App also expects to be informed whether the WiFi connection was successfully established by a `SUCCESS` message wrote to these Characteristics by the ESP32 Controller.

It then writes a `CLOSED` message to these Characteristics and disconnects from the BLE Device.

### WiFi Setup Characteristics
 UUID: `59a3861e-8d11-4f40-9597-912f562e4759`

 The App writes the WiFi name (SSID) and the password seperated by a newline character (`\n`) and encoded as a byte array to these Characteritics.

## Android SDK version

The minimum SKD Version is 19 due to compatibility of the [Flutter Blue](https://pub.dev/packages/flutter_blue) Plugin. 

## Permisions

As the [Flutter Blue](https://pub.dev/packages/flutter_blue) Plugin is used for BLE communication following permissions are needed:

### Android
* Bluetooth
* Bluetooth Admin
* Access Coarse Location

### iOS
* Bluetooth Always Usage
* Bluetooth Peripheral Usage
* Location Always And When In Use Usage
* Location When In Use Usage
* Location Always Usage

For more information refer to the [Flutter Blue](https://pub.dev/documentation/flutter_blue/latest/) documentation.

## Used Dependencies

* [Flutter Blue (0.8.8)](https://pub.dev/packages/flutter_blue) 
Copyright 2017 Paul DeMarco. All rights reserved. [Licence BSD-3-Clause](https://pub.dev/packages/flutter_blue/license)

## Licence
Apache License 2.0 (Apache-2.0)