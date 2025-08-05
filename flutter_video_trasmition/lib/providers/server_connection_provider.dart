import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

final serverConnectionProvider = StreamProvider<bool>((ref) async* {
  const serverUrl = 'ws://localhost:8000';

  while (true) {
    try {
      final channel = WebSocketChannel.connect(Uri.parse(serverUrl));
      
      // Wait for connection to establish
      await channel.ready.timeout(const Duration(seconds: 2));
      
      // Connection successful
      yield true;
      
      // Close the connection
      channel.sink.close();
    } catch (_) {
      yield false;
    }
    await Future.delayed(const Duration(seconds: 5));
  }
});
