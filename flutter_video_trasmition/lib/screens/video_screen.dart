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

  final TextEditingController ndvController = TextEditingController();
  final TextEditingController ndcController = TextEditingController();

  String? lastNDV;
  String? lastNDC;

  ValueNotifier<bool> get connectionNotifier => widget.connectionNotifier;
  bool get isConnected => connectionNotifier.value;

  @override
void initState() {
  super.initState();

  clearFrames();        // <--- Limpiar al entrar
  connectToServer();
}

void clearFrames() {
  if (!mounted) return;
  setState(() {
    currentFrame = null;
    capturedCount = 0;
    lastNDV = null;
    lastNDC = null;
    statusMessage = "Limpiando frames...";
  });

  sendCommand("clear"); // Enviar al servidor para que también limpie
}

  void connectToServer() {
    channel?.sink.close();
    channel = WebSocketChannel.connect(Uri.parse('ws://localhost:8000'));

    channel!.stream.listen(
      (data) => handleMessage(data),
      onError: (error) {
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          connectionNotifier.value = false;
          setState(() {
            statusMessage = "Error: $error";
          });
        });
      },
      onDone: () {
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          connectionNotifier.value = false;
          setState(() {
            statusMessage = "Conexión cerrada";
          });
        });
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
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

        if (!mounted) return;
        setState(() {
          currentFrame = imageBytes;
        });
      } else if (message['type'] == 'response') {
        final status = message['status'];

        if (status == 'captured') {
          if (!mounted) return;
          setState(() {
            capturedCount = message['count'];
            statusMessage = "Frame capturado (${message['count']} total)";
          });
        } else if (status == 'processed') {
          final results = message['results'];
          if (!mounted) return;
          setState(() {
            statusMessage = "Procesados ${results.length} frames";
            capturedCount = 0;
          });

          showProcessResults(results);
        } else if (status == 'cleared') {
          if (!mounted) return;
          setState(() {
    capturedCount = 0;
    currentFrame = null;   // <--- Aseguramos limpiar el frame
    lastNDV = null;
    lastNDC = null;
    statusMessage = "Frames limpiados";
  });
        } else if (status == 'no_frames') {
          if (!mounted) return;
          setState(() {
            statusMessage = "No hay frames para procesar";
          });
        } else if (status == 'undone') {
  final count = message['count'];
  final filename = message['filename'];
  if (!mounted) return;
  setState(() {
    capturedCount = count;
    statusMessage = "Última captura deshecha ($filename)";
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
                    // Parte de los botones dentro del Column en VideoStreamPage
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
          sendCommandWithData("capture", ndv: ndv, ndc: ndc);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Debe ingresar NDV y NDC para capturar"),
            ),
          );
        }
      },
      icon: const Icon(Icons.camera_alt),
      label: const Text("Capturar"),
    ),
    ElevatedButton.icon(
      onPressed: capturedCount > 0
          ? () {
              sendCommand("saveCaptures");
              if (!mounted) return;
              setState(() {
                capturedCount = 0; // Después de guardar, se limpian las capturas
                statusMessage = "Capturas guardadas";
              });
            }
          : null,
      icon: const Icon(Icons.save),
      label: Text("Guardar ($capturedCount)"),
    ),
  ],
),
const SizedBox(height: 8),
Row(
  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  children: [
    ElevatedButton.icon(
      onPressed: capturedCount > 0
    ? () {
        sendCommand("undo"); // Python borra la última
      }
    : null,

      icon: const Icon(Icons.undo),
      label: const Text("Deshacer"),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
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
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                
              ],
            ),
          ),
        ),
      ],
    );
  }
}
