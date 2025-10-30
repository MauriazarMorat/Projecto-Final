import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_video_trasmition/providers/gallery_provider.dart';
import 'package:flutter_video_trasmition/providers/selected_batch_provider.dart';
import 'package:flutter_video_trasmition/screens/stats_screen.dart';
import 'package:flutter_video_trasmition/core/websocket_service.dart'; // IMPORTAR EL SERVICIO

class GaleryScreen extends ConsumerWidget {
  const GaleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final galleryData = ref.watch(galleryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Galería - Números de Campo"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(galleryProvider.notifier).loadGalleryData(),
          ),
        ],
      ),
      body: galleryData.isEmpty
          ? const Center(child: Text("No hay capturas disponibles", style: TextStyle(fontSize: 18)))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                ),
                itemCount: galleryData.keys.length,
                itemBuilder: (context, index) {
                  final sortedNDCs = galleryData.keys.toList()..sort((a, b) => int.parse(a).compareTo(int.parse(b)));
                  final ndc = sortedNDCs[index];
                  final flightCount = galleryData[ndc]!.keys.length;
                  final totalCapturas = galleryData[ndc]!.values
                      .map((files) => files.length)
                      .reduce((a, b) => a + b);

                  return Card(
                    elevation: 4,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FlightListScreen(ndc: ndc),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.folder, size: 48, color: Colors.blue[600]),
                            const SizedBox(height: 12),
                            Text("NDC $ndc", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text("$flightCount vuelos", style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                            Text("$totalCapturas capturas", style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class FlightListScreen extends ConsumerWidget {
  final String ndc;

  const FlightListScreen({super.key, required this.ndc});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final galleryData = ref.watch(galleryProvider);
    final flights = galleryData[ndc] ?? {};

    final sortedNDVs = flights.keys.toList()..sort((a, b) => int.parse(a).compareTo(int.parse(b)));

    return Scaffold(
      appBar: AppBar(title: Text("NDC $ndc - Vuelos")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
          ),
          itemCount: sortedNDVs.length,
          itemBuilder: (context, index) {
            final ndv = sortedNDVs[index];
            final capturas = flights[ndv]!;

            return Card(
              elevation: 4,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CaptureListScreen(ndc: ndc, ndv: ndv),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.flight, size: 48, color: Colors.green[600]),
                      const SizedBox(height: 12),
                      Text("NDV $ndv", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text("${capturas.length} capturas", style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class CaptureListScreen extends ConsumerStatefulWidget {
  final String ndc;
  final String ndv;

  const CaptureListScreen({super.key, required this.ndc, required this.ndv});

  @override
  ConsumerState<CaptureListScreen> createState() => _CaptureListScreenState();
}

class _CaptureListScreenState extends ConsumerState<CaptureListScreen> {
  final Set<String> _selected = {};
  bool _isProcessing = false;
  
  void _deleteSelected() {
    if (_selected.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmar eliminación"),
        content: Text("¿Eliminar ${_selected.length} capturas?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () {
              ref.read(galleryProvider.notifier).deleteCaptures(_selected.toList());
              _selected.clear();
              Navigator.pop(context);
            },
            child: const Text("Eliminar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _processCaptures() async {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecciona al menos una captura")),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Guardar el batch seleccionado en el provider
      ref.read(selectedBatchProvider.notifier).setBatch(
        widget.ndc,
        widget.ndv,
        _selected.toList(),
      );

      // Marcar como procesando
      ref.read(selectedBatchProvider.notifier).setProcessing();

      // Mostrar mensaje de inicio
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Procesando ${_selected.length} imágenes con Roboflow..."),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Conectar al servidor WebSocket si no está conectado
      final wsService = WebSocketService.instance;
      if (!wsService.isConnected) {
        wsService.connect();
        // Dar tiempo para conectar
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // Procesar las imágenes
      final results = await wsService.processBatchImages(
        ndc: widget.ndc,
        ndv: widget.ndv,
        imagePaths: _selected.toList(),
      );

      if (results != null && results['status'] == 'success') {
        // Guardar resultados en el provider
        ref.read(selectedBatchProvider.notifier).setProcessingResults(results);

        if (mounted) {
          // Navegar a la pantalla de estadísticas
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const StatsScreen(),
            ),
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "✓ Procesamiento completado: ${results['total_detections']} detecciones",
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✗ Error al procesar las imágenes"),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('Error en _processCaptures: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✗ Error: $e"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final galleryData = ref.watch(galleryProvider);
    final capturas = galleryData[widget.ndc]?[widget.ndv] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text("NDC ${widget.ndc} - NDV ${widget.ndv}"),
        actions: [
          if (_selected.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteSelected,
            ),
          IconButton(
            icon: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.analytics),
            onPressed: _isProcessing ? null : _processCaptures,
            tooltip: "Procesar con Roboflow",
          ),
        ],
      ),
      body: Column(
        children: [
          if (_selected.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.blue[50],
              child: Text(
                "${_selected.length} capturas seleccionadas",
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          if (_isProcessing)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.orange[50],
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text(
                    "Procesando imágenes con Roboflow...",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemCount: capturas.length,
                itemBuilder: (context, index) {
                  final file = capturas[index];
                  final filename = file.path.split('\\').last;
                  final isSelected = _selected.contains(file.path);

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selected.remove(file.path);
                        } else {
                          _selected.add(file.path);
                        }
                      });
                    },
                    onLongPress: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FullScreenImage(file: file),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected ? Border.all(color: Colors.blue, width: 3) : null,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(file, fit: BoxFit.cover),
                            if (isSelected)
                              Container(
                                color: Colors.blue.withOpacity(0.3),
                                child: const Icon(Icons.check_circle, color: Colors.white, size: 32),
                              ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                color: Colors.black.withOpacity(0.7),
                                child: Text(
                                  filename.split('_').last.split('.').first,
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FullScreenImage extends StatelessWidget {
  final File file;

  const FullScreenImage({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(file.path.split('\\').last),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.file(file),
        ),
      ),
    );
  }
}