import 'dart:io';
import 'package:flutter/material.dart';

class GaleryScreen extends StatefulWidget {
  const GaleryScreen({super.key});

  @override
  State<GaleryScreen> createState() => _GaleryScreenState();
}

class _GaleryScreenState extends State<GaleryScreen> {
  List<FileSystemEntity> _images = [];
  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  void _loadImages() {
    final dir = Directory(
        "C:/Users/Mauricio/Documents/GitHub/Projecto-Final/carpeta_frames");

    if (dir.existsSync()) {
      final files = dir
          .listSync()
          .where((f) => f.path.toLowerCase().endsWith(".jpg"))
          .toList();

      files.sort((a, b) {
        final aTime = File(a.path).lastModifiedSync();
        final bTime = File(b.path).lastModifiedSync();
        return bTime.compareTo(aTime); // más recientes arriba
      });

      setState(() {
        _images = files;
      });
    }
  }

  void _deleteSelected() {
    for (var path in _selected) {
      try {
        File(path).deleteSync();
        _images.removeWhere((f) => f.path == path);
      } catch (e) {
        debugPrint("Error al borrar $path: $e");
      }
    }
    _selected.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Galería")),
      body: Column(
        children: [
          Expanded(
            child: _images.isEmpty
                ? const Center(child: Text("No hay imágenes"))
                : ListView.builder(
                    itemCount: _images.length,
                    itemBuilder: (context, index) {
                      final file = File(_images[index].path);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (_selected.contains(file.path)) {
                              _selected.remove(file.path);
                            } else {
                              _selected.add(file.path);
                            }
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          height: 150, // mismo tamaño para todas
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: FileImage(file),
                              fit: BoxFit.cover,
                              colorFilter: _selected.contains(file.path)
                                  ? ColorFilter.mode(
                                      Colors.black.withOpacity(0.4),
                                      BlendMode.darken,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: _selected.isEmpty ? null : _deleteSelected,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50), // botón grande
              ),
              child: Text(
                  _selected.isEmpty ? "Selecciona al menos 1 imagen" : "Borrar (${_selected.length})"),
            ),
          ),
        ],
      ),
    );
  }
}
