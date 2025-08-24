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

  // Para los TextField de NDV y NDC
  final TextEditingController ndvController = TextEditingController();
  final TextEditingController ndcController = TextEditingController();

  String? lastNDV;
  String? lastNDC;

  ValueNotifier<bool> get connectionNotifier => widget.connectionNotifier;
  bool get isConnected => connectionNotifier.value;

  @override
  void initState() {
    super.initState();
    connectToServer();
  }

 void connectToServer() {
  channel?.sink.close();
  channel = WebSocketChannel.connect(Uri.parse('ws://localhost:8000'));

  channel!.stream.listen(
    (data) => handleMessage(data),
    onError: (error) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        connectionNotifier.value = false;
        setState(() {
          statusMessage = "Error: $error";
        });
      });
    },
    onDone: () {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        connectionNotifier.value = false;
      });
    },
  );

  WidgetsBinding.instance.addPostFrameCallback((_) {
    connectionNotifier.value = true;
    setState(() {
      statusMessage = "Conectado";
    });
  });
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
    channel?.sink.add(jsonEncode({"command": command}));
  }

  void sendCommandWithData(String command,
      {required String ndv, required String ndc}) {
    channel?.sink.add(jsonEncode({
      "command": command,
      "NDV": ndv,
      "NDC": ndc,
    }));
  }

  @override
  void dispose() {
    ndvController.dispose();
    ndcController.dispose();
    try {
      sendCommand("stop");
    } catch (_) {}
    channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Parte del video
        Expanded(
          flex: 3,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.grey[200],
                child: Text(
                  statusMessage,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
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
                      : const Center(
                          child: Text("Desconectado"),
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
                          onPressed: () {
                            final ndv = ndvController.text;
                            final ndc = ndcController.text;
                            if (ndv.isNotEmpty && ndc.isNotEmpty) {
                              lastNDV = ndv;
                              lastNDC = ndc;
                              sendCommandWithData("capture",
                                  ndv: ndv, ndc: ndc);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text("Debe ingresar NDV y NDC para capturar"),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.camera_alt),
                          label: const Text("Capturar"),
                        ),
                        ElevatedButton.icon(
  onPressed:
      capturedCount > 0 ? () => sendCommand("saveCaptures") : null,
  icon: const Icon(Icons.psychology),
  label: Text("Guardar ($capturedCount)"),
),

                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed:
                              capturedCount > 0 ? () => sendCommand("clear") : null,
                          icon: const Icon(Icons.clear),
                          label: const Text("Limpiar"),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => sendCommand("status"),
                          icon: const Icon(Icons.info),
                          label: const Text("Estado"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Parte de los TextField para NDV y NDC
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lastNDV != null
                      ? "Último número de vuelo: $lastNDV"
                      : "No hay último número de vuelo",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: ndvController,
                  decoration: const InputDecoration(
                    labelText: "NDV",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  lastNDC != null
                      ? "Último número de campo: $lastNDC"
                      : "No hay último número de campo",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: ndcController,
                  decoration: const InputDecoration(
                    labelText: "NDC",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
