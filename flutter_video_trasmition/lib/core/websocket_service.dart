import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  static WebSocketService? _instance;
  WebSocketChannel? _channel;
  String _serverUrl = 'ws://localhost:8000';

  WebSocketService._();

  static WebSocketService get instance {
    _instance ??= WebSocketService._();
    return _instance!;
  }

  // Conectar al servidor
  void connect({String? customUrl}) {
    if (customUrl != null) {
      _serverUrl = customUrl;
    }
    
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_serverUrl));
      print('✓ Conectado al servidor: $_serverUrl');
    } catch (e) {
      print('✗ Error conectando al servidor: $e');
    }
  }

  // Enviar comando de procesamiento de batch
  Future<Map<String, dynamic>?> processBatchImages({
    required String ndc,
    required String ndv,
    required List<String> imagePaths,
  }) async {
    if (_channel == null) {
      print('✗ No hay conexión con el servidor');
      return null;
    }

    try {
      // Enviar comando
      final command = jsonEncode({
        'command': 'batch_image_process',
        'ndc': ndc,
        'ndv': ndv,
        'image_paths': imagePaths,
      });

      _channel!.sink.add(command);
      print('📤 Comando enviado: batch_image_process');

      // Esperar respuesta
      await for (final message in _channel!.stream) {
        final data = jsonDecode(message as String);
        
        if (data['type'] == 'response') {
          final status = data['status'];
          
          if (status == 'processing') {
            print('⏳ ${data['message']}');
            continue; // Esperar siguiente mensaje
          } else if (status == 'batch_processed') {
            print('✓ Batch procesado exitosamente');
            return data['results'] as Map<String, dynamic>;
          } else if (status == 'error') {
            print('✗ Error: ${data['message']}');
            return null;
          }
        }
      }
    } catch (e) {
      print('✗ Error procesando batch: $e');
      return null;
    }

    return null;
  }

  // Cerrar conexión
  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    print('🔌 Desconectado del servidor');
  }

  // Verificar si está conectado
  bool get isConnected => _channel != null;
}