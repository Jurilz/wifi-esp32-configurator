import 'package:wifi_esp32_configurator/model/wifi_connection.dart';

const String openConnection = "0";

class Converter {

  WiFiConnection convertFromString(String stringRepresentation) {
    String connectionType = stringRepresentation.substring(stringRepresentation.length - 1);
    String name = stringRepresentation.substring(0, (stringRepresentation.length - 1));
    return WiFiConnection(name: name, openConnection: (connectionType == openConnection) ? true : false);
  }

  // static List<WiFiConnection> convertFromString(String names) {
  //   final List<String> namesAsList = names.split('\n');
  //   List<WiFiConnection> result = [];
  //   for (String nameStringEncoded in namesAsList) {
  //     if (nameStringEncoded.isEmpty) continue;
  //     String connectionType = nameStringEncoded.substring(nameStringEncoded.length - 1);
  //     String name = nameStringEncoded.substring(0, (nameStringEncoded.length - 1));
  //     result.add(WiFiConnection(name: name, openConnection: (connectionType == "0") ? true : false));
  //   }
  //   return result;
  // }
}