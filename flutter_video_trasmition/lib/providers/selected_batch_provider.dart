import 'package:flutter_riverpod/flutter_riverpod.dart';

// Clase para representar el batch seleccionado
class SelectedBatch {
  final String ndc;
  final String ndv;
  final List<String> selectedPaths;

  SelectedBatch({
    required this.ndc,
    required this.ndv,
    required this.selectedPaths,
  });

  SelectedBatch copyWith({
    String? ndc,
    String? ndv,
    List<String>? selectedPaths,
  }) {
    return SelectedBatch(
      ndc: ndc ?? this.ndc,
      ndv: ndv ?? this.ndv,
      selectedPaths: selectedPaths ?? this.selectedPaths,
    );
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
    );
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