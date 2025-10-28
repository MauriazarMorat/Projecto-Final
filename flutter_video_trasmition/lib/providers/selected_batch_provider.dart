import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  void setProcessingResults(Map<String, dynamic> results) {
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