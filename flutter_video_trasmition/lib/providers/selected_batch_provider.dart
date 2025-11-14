import 'dart:io';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

// Clase para representar una imagen procesada
class ProcessedImage {
  final String originalPath;
  final String imageName;
  final int imageIndex;
  final int detectionsCount;
  final String? outputPath;
  final String? annotatedImageBase64;
  final List<dynamic> predictions;

  ProcessedImage({
    required this.originalPath,
    required this.imageName,
    required this.imageIndex,
    required this.detectionsCount,
    this.outputPath,
    this.annotatedImageBase64,
    required this.predictions,
  });

  factory ProcessedImage.fromJson(Map<String, dynamic> json) {
    return ProcessedImage(
      originalPath: json['original_path'] ?? '',
      imageName: json['image_name'] ?? '',
      imageIndex: json['image_index'] ?? 0,
      detectionsCount: json['detections_count'] ?? 0,
      outputPath: json['output_path'],
      annotatedImageBase64: json['annotated_image_base64'],
      predictions: json['predictions'] ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'original_path': originalPath,
      'image_name': imageName,
      'image_index': imageIndex,
      'detections_count': detectionsCount,
      'output_path': outputPath,
      'annotated_image_base64': annotatedImageBase64,
      'predictions': predictions,
    };
  }
}

// Clase para representar el batch seleccionado con resultados
class SelectedBatch {
  final String ndc;
  final String ndv;
  final List<String> selectedPaths;
  final bool isProcessed;
  final int? totalDetections;
  final Map<String, int>? summary;
  final List<ProcessedImage>? processedImages;
  final String? status;

  SelectedBatch({
    required this.ndc,
    required this.ndv,
    required this.selectedPaths,
    this.isProcessed = false,
    this.totalDetections,
    this.summary,
    this.processedImages,
    this.status,
  });

  SelectedBatch copyWith({
    String? ndc,
    String? ndv,
    List<String>? selectedPaths,
    bool? isProcessed,
    int? totalDetections,
    Map<String, int>? summary,
    List<ProcessedImage>? processedImages,
    String? status,
  }) {
    return SelectedBatch(
      ndc: ndc ?? this.ndc,
      ndv: ndv ?? this.ndv,
      selectedPaths: selectedPaths ?? this.selectedPaths,
      isProcessed: isProcessed ?? this.isProcessed,
      totalDetections: totalDetections ?? this.totalDetections,
      summary: summary ?? this.summary,
      processedImages: processedImages ?? this.processedImages,
      status: status ?? this.status,
    );
  }

  // Obtener promedio de detecciones por imagen
  double get averageDetectionsPerImage {
    if (processedImages == null || processedImages!.isEmpty) return 0.0;
    return totalDetections! / processedImages!.length;
  }
}

// Provider para el batch seleccionado
final selectedBatchProvider = StateNotifierProvider<SelectedBatchNotifier, SelectedBatch?>(
  (ref) => SelectedBatchNotifier(),
);

class SelectedBatchNotifier extends StateNotifier<SelectedBatch?> {
  SelectedBatchNotifier() : super(null);

  // Establecer el batch seleccionado con los paths de las capturas
  void setBatch(String ndc, String ndv, List<String> selectedPaths) {
    state = SelectedBatch(
      ndc: ndc,
      ndv: ndv,
      selectedPaths: selectedPaths,
      isProcessed: false,
    );
  }

  // Actualizar con los resultados del procesamiento
  Future<void> setProcessingResults(Map<String, dynamic> results) async {
    if (state == null) return;

    final processedImages = (results['processed_images'] as List?)
        ?.map((img) => ProcessedImage.fromJson(img as Map<String, dynamic>))
        .toList();

    final summary = (results['summary'] as Map<String, dynamic>?)
        ?.map((key, value) => MapEntry(key, value as int));

    state = state!.copyWith(
      isProcessed: true,
      totalDetections: results['total_detections'] as int?,
      summary: summary,
      processedImages: processedImages,
      status: results['status'] as String?,
    );

    // Guardar las imágenes procesadas y el registro
    await _saveProcessedData(processedImages);
  }

  // Guardar las imágenes procesadas en carpeta_frames/after y crear registro
  Future<void> _saveProcessedData(List<ProcessedImage>? images) async {
    if (images == null || images.isEmpty || state == null) return;

    try {
      // Crear carpeta after si no existe
      final afterDir = Directory('carpeta_frames/after');
      if (!await afterDir.exists()) {
        await afterDir.create(recursive: true);
      }

      // Crear archivo de registro
      final registroFile = File('carpeta_frames/registro_procesamiento.txt');
      final timestamp = DateTime.now().toIso8601String();
      final buffer = StringBuffer();
      
      buffer.writeln('=== PROCESAMIENTO: $timestamp ===');
      buffer.writeln('NDC: ${state!.ndc}');
      buffer.writeln('NDV: ${state!.ndv}');
      buffer.writeln('Total de imágenes: ${images.length}');
      buffer.writeln('Total de vacas detectadas: ${state!.totalDetections}');
      buffer.writeln('');

      // Guardar cada imagen procesada
      for (final img in images) {
        if (img.annotatedImageBase64 != null) {
          // Obtener nombre del archivo original sin extensión
          final originalName = p.basenameWithoutExtension(img.imageName);
          final afterPath = p.join(afterDir.path, '$originalName.jpg');
          
          // Decodificar y guardar imagen procesada
          final bytes = base64Decode(img.annotatedImageBase64!);
          final file = File(afterPath);
          await file.writeAsBytes(bytes);

          // Agregar al registro
          buffer.writeln('Captura: $originalName');
          buffer.writeln('  - Conteo de vacas: ${img.detectionsCount}');
          buffer.writeln('  - Path original: ${img.originalPath}');
          buffer.writeln('  - Path procesada: $afterPath');
          buffer.writeln('');
        }
      }

      buffer.writeln('=====================================');
      buffer.writeln('');

      // Guardar registro (append mode)
      await registroFile.writeAsString(
        buffer.toString(),
        mode: FileMode.append,
      );

      print('✓ Datos guardados en carpeta_frames/after');
      print('✓ Registro actualizado en registro_procesamiento.txt');
    } catch (e) {
      print('Error guardando datos procesados: $e');
    }
  }

  // Marcar como procesando
  void setProcessing() {
    if (state != null) {
      state = state!.copyWith(status: 'processing');
    }
  }

  // Actualizar solo los paths seleccionados
  void updateSelectedPaths(List<String> paths) {
    if (state != null) {
      state = state!.copyWith(selectedPaths: paths);
    }
  }

  // Limpiar la selección
  void clear() {
    state = null;
  }
}