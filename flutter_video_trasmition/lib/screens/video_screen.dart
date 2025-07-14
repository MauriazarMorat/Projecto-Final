import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'dart:typed_data';

class VideoScreen extends StatelessWidget {
  const VideoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final connectionNotifier = ValueNotifier<bool>(false);

    return ValueListenableBuilder<bool>(
      valueListenable: connectionNotifier,
      builder: (context, isConnected, _) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: isConnected ? Colors.green : Colors.red,
            title: const Text("Video"),
          ),
          body: VideoStreamPage(connectionNotifier: connectionNotifier),
        );
      },
    );
  }
}

class VideoStreamPage extends StatefulWidget {
  final ValueNotifier<bool> connectionNotifier;

  const VideoStreamPage({super.key, required this.connectionNotifier});

  @override
  _VideoStreamPageState createState() => _VideoStreamPageState();
}

class _VideoStreamPageState extends State<VideoStreamPage> {
  WebSocketChannel? channel;
  Uint8List? currentFrame;

  int capturedCount = 0;
  String statusMessage = "Desconectado";

  ValueNotifier<bool> get connectionNotifier => widget.connectionNotifier;
  bool get isConnected => connectionNotifier.value;

  @override
  void initState() {
    super.initState();
    connectToServer();
  }

  void connectToServer() {
    // Cerrar canal previo si existe
    if (channel != null) {
      channel!.sink.close();
      channel = null;
    }

    try {
      channel = WebSocketChannel.connect(Uri.parse('ws://localhost:8000'));

      channel!.stream.listen(
        (data) {
          handleMessage(data);
        },
        onError: (error) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            connectionNotifier.value = false;
            if (!mounted) return;
            setState(() {
              statusMessage = "Error: $error";
            });
          });
        },
        onDone: () {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            connectionNotifier.value = false;
            if (!mounted) return;
            setState(() {
              statusMessage = "Conexión cerrada";
            });
          });
        },
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        connectionNotifier.value = true;
        if (!mounted) return;
        setState(() {
          statusMessage = "Conectado";
        });
      });
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        connectionNotifier.value = false;
        if (!mounted) return;
        setState(() {
          statusMessage = "Error al conectar: $e";
        });
      });
    }
  }

  void handleMessage(dynamic data) {
    try {
      final message = jsonDecode(data);

      if (message['type'] == 'frame') {
        final frameData = message['data'];
        final imageBytes = base64Decode(frameData);

        setState(() {
          currentFrame = imageBytes;
        });
      } else if (message['type'] == 'response') {
        final status = message['status'];

        if (status == 'captured') {
          setState(() {
            capturedCount = message['count'];
            statusMessage = "Frame capturado (${message['count']} total)";
          });
        } else if (status == 'processed') {
          final results = message['results'];
          setState(() {
            statusMessage = "Procesados ${results.length} frames";
            capturedCount = 0;
          });

          showProcessResults(results);
        } else if (status == 'cleared') {
          setState(() {
            capturedCount = 0;
            statusMessage = "Frames limpiados";
          });
        } else if (status == 'no_frames') {
          setState(() {
            statusMessage = "No hay frames para procesar";
          });
        }
      }
    } catch (e) {
      print("Error al procesar mensaje: $e");
    }
  }

  void showProcessResults(List results) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resultados del Procesamiento'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: results.length,
            itemBuilder: (context, index) {
              final result = results[index];
              return ListTile(
                title: Text(result['filename']),
                subtitle: Text('Predicción: ${result['prediction']}'),
                trailing:
                    Text('${(result['confidence'] * 100).toStringAsFixed(1)}%'),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void sendCommand(String command) {
    if (isConnected && channel != null) {
      channel!.sink.add(jsonEncode({"command": command}));
    }
  }

  @override
  void dispose() {
    try {
      sendCommand("stop");
    } catch (e) {
      // Ignorar error si no se puede enviar
    }
    channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.grey[200],
          child: Text(
            statusMessage,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Container(
            width: double.infinity,
            child: currentFrame != null
                ? Image.memory(
                    currentFrame!,
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text("Esperando video..."),
                      ],
                    ),
                  ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: isConnected ? () => sendCommand("capture") : null,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Capturar"),
                  ),
                  ElevatedButton.icon(
                    onPressed: isConnected && capturedCount > 0
                        ? () => sendCommand("process")
                        : null,
                    icon: const Icon(Icons.psychology),
                    label: Text("Procesar ($capturedCount)"),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed:
                        isConnected && capturedCount > 0 ? () => sendCommand("clear") : null,
                    icon: const Icon(Icons.clear),
                    label: const Text("Limpiar"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  ),
                  ElevatedButton.icon(
                    onPressed: isConnected ? () => sendCommand("status") : null,
                    icon: const Icon(Icons.info),
                    label: const Text("Estado"),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: !isConnected ? connectToServer : null,
                icon: const Icon(Icons.refresh),
                label: const Text("Reconectar"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
