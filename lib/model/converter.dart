import 'package:wifi_esp32_configurator/model/wifi_connection.dart';

const String openConnection = "0";

class Converter {

  WiFiConnection convertFromString(String stringRepresentation) {
    String connectionType = stringRepresentation.substring(stringRepresentation.length - 1);
    String name = stringRepresentation.substring(0, (stringRepresentation.length - 1));
    return WiFiConnection(name: name, openConnection: (connectionType == openConnection) ? true : false);
  }
}