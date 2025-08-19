import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../providers/gallery_provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';

class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({super.key});

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  WebSocketChannel? channel;

  @override
  void initState() {
    super.initState();
    connectToServer();
  }

  void connectToServer() {
    channel?.sink.close();
    channel = WebSocketChannel.connect(Uri.parse('ws://localhost:8000'));

    channel!.stream.listen(
      handleMessage,
      onError: (error) {
        if (!mounted) return;
        // opcional: manejar error visualmente
        print("WebSocket error: $error");
      },
      onDone: () {
        if (!mounted) return;
        // opcional: manejar cierre
        print("WebSocket cerrado");
      },
    );

    sendCommand("list_captures");
  }

  void handleMessage(dynamic data) {
    try {
      final message = jsonDecode(data);

      if (message['type'] == 'captures_list') {
        final captures = (message['captures'] as List)
            .map((json) => CaptureData.fromJson(json))
            .toList();

        if (!mounted) return;
        ref.read(galleryProvider.notifier).setCaptures(captures);
      }
    } catch (e) {
      if (!mounted) return;
      print("Error galería: $e");
    }
  }

  void sendCommand(String command) {
    channel?.sink.add(jsonEncode({"command": command}));
  }

  @override
  void dispose() {
    channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final captures = ref.watch(galleryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Galería")),
      body: captures.isEmpty
          ? const Center(child: Text("No hay capturas aún"))
          : ListView.builder(
              itemCount: captures.length,
              itemBuilder: (context, index) {
                final capture = captures[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    leading: Image.file(
                      File(capture.filename),
                      width: 50,
                      fit: BoxFit.cover,
                    ),
                    title: Text("Campo ${capture.field} - Vuelo ${capture.flight}"),
                    subtitle: Text("Captura #${capture.capture}"),
                  ),
                );
              },
            ),
    );
  }
}
