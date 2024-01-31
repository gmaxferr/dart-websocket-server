import 'package:dart_websocket_server/testing/helpers/helper_functions.dart';

class MacroProcessor {
  Map<String, String> _macros;
  late Map<String, String Function()> _runTimeOperationMacros;

  MacroProcessor(this._macros) {
    _runTimeOperationMacros = {
      'random': () => generateRandomString(length: 8)
    };
  }

  // Method to store a value as a macro
  void storeValueAsMacro(String macroName, String value) {
    _macros[macroName] = value;
  }

  // Process a message and replace all macros
  String process(String message) {
    String processedMessage = message;
    _runTimeOperationMacros.forEach((macroName, value) {
      processedMessage =
          processedMessage.replaceAll('__${macroName}__', value());
    });
    _macros.forEach((macroName, value) {
      processedMessage = processedMessage.replaceAll('__${macroName}__', value);
    });
    return processedMessage;
  }

  // Optionally, a method to remove a macro
  void removeMacro(String macroName) {
    _macros.remove(macroName);
  }

  // Method to extract and store a value as a macro from a given message
  bool extractAndStoreMacro(String message, String macroName, String pattern) {
    RegExp regExp = RegExp(pattern);
    var matches = regExp.allMatches(message);

    if (matches.isNotEmpty) {
      // Assuming the first group in the regex contains the value to store
      String extractedValue = matches.first.group(1) ?? '';
      storeValueAsMacro(macroName, extractedValue);
      return true;
    }
    return false;
  }
}
