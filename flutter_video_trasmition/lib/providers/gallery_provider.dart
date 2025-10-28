import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

final galleryProvider =
    StateNotifierProvider<GalleryNotifier, Map<String, Map<String, List<File>>>>(
  (ref) => GalleryNotifier()..loadGalleryData(),
);

class GalleryNotifier extends StateNotifier<Map<String, Map<String, List<File>>>> {
  GalleryNotifier() : super({});

  void loadGalleryData() {
    final scriptDir = Directory.current.path;
    final projectRoot = p.dirname(scriptDir);
    final dir = Directory(p.join(projectRoot, 'carpeta_frames/before'));

    Map<String, Map<String, List<File>>> data = {};

    if (dir.existsSync()) {
      final files = dir
          .listSync()
          .where((f) => f.path.toLowerCase().endsWith(".jpg"))
          .map((f) => File(f.path))
          .toList();

      for (var file in files) {
        final filename = p.basename(file.path);
        final parts = filename.split('_');

        if (parts.length >= 6) {
          final ndc = parts[1];
          final ndv = parts[3];

          data[ndc] ??= {};
          data[ndc]![ndv] ??= [];
          data[ndc]![ndv]!.add(file);
        }
      }

      // Ordenar archivos
      for (var ndc in data.keys) {
        for (var ndv in data[ndc]!.keys) {
          data[ndc]![ndv]!.sort((a, b) => p.basename(a.path).compareTo(p.basename(b.path)));
        }
      }
    }

    state = data;
  }

  void deleteCaptures(List<String> paths) {
    for (var path in paths) {
      try {
        File(path).deleteSync();
      } catch (_) {}
    }
    loadGalleryData(); // recarga toda la estructura automáticamente
  }
}
