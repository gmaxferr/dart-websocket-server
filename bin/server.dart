import 'package:dart_websocket_server/main.dart' as mainFile;
import 'dart:io';

void main(List<String> arguments) async {
  if (arguments.isNotEmpty) {
    String screenName = arguments[0];
    final File f = File('lib/screen_name.txt');
    if(!(await f.exists())){
      await f.create();
    }
    String content = (await f.readAsLines()).where((element) => element.isNotEmpty).toList().join('\n');
    content += content.isEmpty ? '$screenName' : '\n$screenName';
    await f.writeAsString(content, mode: FileMode.write);
  }

  mainFile.main();
}

