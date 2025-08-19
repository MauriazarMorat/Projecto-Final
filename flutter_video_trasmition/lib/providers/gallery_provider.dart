import 'package:flutter_riverpod/flutter_riverpod.dart';

class CaptureData {
  final String flight;
  final String field;
  final int capture;
  final String filename;

  CaptureData({
    required this.flight,
    required this.field,
    required this.capture,
    required this.filename,
  });

  factory CaptureData.fromJson(Map<String, dynamic> json) {
    return CaptureData(
      flight: json["flight"],
      field: json["field"],
      capture: json["capture"],
      filename: json["filename"],
    );
  }
}

class GalleryNotifier extends StateNotifier<List<CaptureData>> {
  GalleryNotifier() : super([]);

  void setCaptures(List<CaptureData> captures) {
    state = captures;
  }

  void addCapture(CaptureData capture) {
    state = [...state, capture];
  }

  void removeLast() {
    if (state.isNotEmpty) {
      state = state.sublist(0, state.length - 1);
    }
  }
}

final galleryProvider =
    StateNotifierProvider<GalleryNotifier, List<CaptureData>>(
        (ref) => GalleryNotifier());
