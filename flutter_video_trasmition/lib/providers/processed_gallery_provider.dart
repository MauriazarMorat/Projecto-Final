import 'dart:io';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

class ProcessedImageData {
  final String ncFolder; // e.g., "NDC_1_NDV_2_NC_3"
  final String beforePath; // Original image in carpeta_frames/before
  final String afterPath; // Annotated image in carpeta_frames/after/{ncFolder}
  final String resultsJsonPath; // resultados.json path
  int detectionsCount = 0;
  List<dynamic> predictions = [];

  ProcessedImageData({
    required this.ncFolder,
    required this.beforePath,
    required this.afterPath,
    required this.resultsJsonPath,
  });

  // Load detection count from resultados.json
  Future<void> loadResults() async {
    try {
      final file = File(resultsJsonPath);
      if (await file.exists()) {
        final content = await file.readAsString();
        final json = jsonDecode(content);
        detectionsCount = json['detections_count'] ?? 0;
        predictions = json['predictions'] ?? [];
      }
    } catch (e) {
      print('Error loading results.json for $ncFolder: $e');
    }
  }
}

final processedGalleryProvider = StateNotifierProvider<
    ProcessedGalleryNotifier,
    Map<String, Map<String, List<ProcessedImageData>>>>(
  (ref) => ProcessedGalleryNotifier()..loadProcessedGalleryData(),
);

class ProcessedGalleryNotifier
    extends StateNotifier<Map<String, Map<String, List<ProcessedImageData>>>> {
  ProcessedGalleryNotifier() : super({});

  void loadProcessedGalleryData() async {
    final scriptDir = Directory.current.path;
    final projectRoot = p.dirname(scriptDir);
    final afterDir = Directory(p.join(projectRoot, 'carpeta_frames/after'));
    final beforeDir = Directory(p.join(projectRoot, 'carpeta_frames/before'));

    Map<String, Map<String, List<ProcessedImageData>>> data = {};

    if (afterDir.existsSync()) {
      // List all NC folders (e.g., NDC_1_NDV_2_NC_3)
      final ncFolders = afterDir
          .listSync()
          .where((f) => f is Directory && p.basename(f.path).contains('NDC_'))
          .map((f) => f as Directory)
          .toList();

      for (var ncFolder in ncFolders) {
        final folderName = p.basename(ncFolder.path); // e.g., "NDC_1_NDV_2_NC_3"
        final parts = folderName.split('_');

        // Parse: NDC_<ndc>_NDV_<ndv>_NC_<nc>
        if (parts.length >= 6) {
          final ndc = parts[1];
          final ndv = parts[3];

          // Find corresponding image in before
          final beforeImageName = '$folderName.jpg';
          final beforePath = p.join(beforeDir.path, beforeImageName);
          final afterImagePath = p.join(ncFolder.path, '$folderName.jpg');
          final resultsJsonPath = p.join(ncFolder.path, 'resultados.json');

          if (File(beforePath).existsSync() &&
              File(afterImagePath).existsSync()) {
            final processedImage = ProcessedImageData(
              ncFolder: folderName,
              beforePath: beforePath,
              afterPath: afterImagePath,
              resultsJsonPath: resultsJsonPath,
            );

            // Load detection count from resultados.json
            await processedImage.loadResults();

            data[ndc] ??= {};
            data[ndc]![ndv] ??= [];
            data[ndc]![ndv]!.add(processedImage);
          }
        }
      }

      // Sort by NC number
      for (var ndc in data.keys) {
        for (var ndv in data[ndc]!.keys) {
          data[ndc]![ndv]!.sort((a, b) {
            final aNC = int.tryParse(a.ncFolder.split('_').last) ?? 0;
            final bNC = int.tryParse(b.ncFolder.split('_').last) ?? 0;
            return aNC.compareTo(bNC);
          });
        }
      }
    }

    state = data;
  }

  void refresh() {
    loadProcessedGalleryData();
  }
}
