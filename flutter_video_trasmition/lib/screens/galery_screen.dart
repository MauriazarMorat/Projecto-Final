import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

class GaleryScreen extends StatefulWidget {
  const GaleryScreen({super.key});

  @override
  State<GaleryScreen> createState() => _GaleryScreenState();
}

class _GaleryScreenState extends State<GaleryScreen> {
  Map<String, Map<String, List<File>>> _galleryData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGalleryData();
  }

  void _loadGalleryData() {
    setState(() => _isLoading = true);

    final scriptDir = Directory.current.path; // flutter_video_trasmition
    final projectRoot = p.dirname(scriptDir); // sube un nivel -> Projecto-Final
    final dir = Directory(p.join(projectRoot, 'carpeta_frames'));

    Map<String, Map<String, List<File>>> data = {};

    if (dir.existsSync()) {
      final files = dir
          .listSync()
          .where((f) => f.path.toLowerCase().endsWith(".jpg"))
          .map((f) => File(f.path))
          .toList();

      for (var file in files) {
        final filename = file.path.split('\\').last; // Obtener solo el nombre del archivo
        
        // Parsear el nombre: NDC_123_NDV_456_NC_001.jpg
        final parts = filename.split('_');
        if (parts.length >= 6) {
          final ndc = parts[1]; // "123"
          final ndv = parts[3]; // "456"
          
          // Inicializar estructuras si no existen
          data[ndc] ??= {};
          data[ndc]![ndv] ??= [];
          
          // Agregar archivo a la estructura
          data[ndc]![ndv]!.add(file);
        }
      }

      // Ordenar todo de menor a mayor
      for (var ndc in data.keys) {
        for (var ndv in data[ndc]!.keys) {
          data[ndc]![ndv]!.sort((a, b) {
            final aName = a.path.split('\\').last;
            final bName = b.path.split('\\').last;
            return aName.compareTo(bName);
          });
        }
      }
    }

    setState(() {
      _galleryData = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Galería")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Galería - Números de Campo"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadGalleryData,
          ),
        ],
      ),
      body: _galleryData.isEmpty
          ? const Center(
              child: Text(
                "No hay capturas disponibles",
                style: TextStyle(fontSize: 18),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                ),
                itemCount: _galleryData.keys.length,
                itemBuilder: (context, index) {
                  final sortedNDCs = _galleryData.keys.toList()..sort((a, b) => int.parse(a).compareTo(int.parse(b)));
                  final ndc = sortedNDCs[index];
                  final flightCount = _galleryData[ndc]!.keys.length;
                  final totalCapturas = _galleryData[ndc]!.values
                      .map((files) => files.length)
                      .reduce((a, b) => a + b);

                  return Card(
                    elevation: 4,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FlightListScreen(
                              ndc: ndc,
                              flights: _galleryData[ndc]!,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.folder,
                              size: 48,
                              color: Colors.blue[600],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "NDC $ndc",
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "$flightCount vuelos",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              "$totalCapturas capturas",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
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
    );
  }
}

class FlightListScreen extends StatelessWidget {
  final String ndc;
  final Map<String, List<File>> flights;

  const FlightListScreen({
    super.key,
    required this.ndc,
    required this.flights,
  });

  @override
  Widget build(BuildContext context) {
    final sortedNDVs = flights.keys.toList()..sort((a, b) => int.parse(a).compareTo(int.parse(b)));

    return Scaffold(
      appBar: AppBar(
        title: Text("NDC $ndc - Vuelos"),
      ),
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
                      builder: (context) => CaptureListScreen(
                        ndc: ndc,
                        ndv: ndv,
                        capturas: capturas,
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.flight,
                        size: 48,
                        color: Colors.green[600],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "NDV $ndv",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${capturas.length} capturas",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
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
    );
  }
}

class CaptureListScreen extends StatefulWidget {
  final String ndc;
  final String ndv;
  final List<File> capturas;

  const CaptureListScreen({
    super.key,
    required this.ndc,
    required this.ndv,
    required this.capturas,
  });

  @override
  State<CaptureListScreen> createState() => _CaptureListScreenState();
}

class _CaptureListScreenState extends State<CaptureListScreen> {
  final Set<String> _selected = {};

  void _deleteSelected() {
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
            setState(() {
              for (var path in _selected) {
                try {
                  File(path).deleteSync();
                  widget.capturas.removeWhere((f) => f.path == path);
                } catch (e) {
                  debugPrint("Error al borrar $path: $e");
                }
              }
              _selected.clear();
            });
            Navigator.pop(context); // cerrar el AlertDialog
          },
          child: const Text("Eliminar", style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("NDC ${widget.ndc} - NDV ${widget.ndv}"),
        actions: [
          if (_selected.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteSelected,
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
                itemCount: widget.capturas.length,
                itemBuilder: (context, index) {
                  final file = widget.capturas[index];
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
                      // Mostrar imagen en pantalla completa
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FullScreenImage(file: file),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected
                            ? Border.all(color: Colors.blue, width: 3)
                            : null,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(
                              file,
                              fit: BoxFit.cover,
                            ),
                            if (isSelected)
                              Container(
                                color: Colors.blue.withOpacity(0.3),
                                child: const Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                color: Colors.black.withOpacity(0.7),
                                child: Text(
                                  filename.split('_').last.split('.').first, // Solo mostrar "001", "002", etc.
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
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