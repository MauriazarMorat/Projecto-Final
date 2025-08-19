// objects/capture_record.dart
class CaptureRecord {
  final String ndc;
  final String ndv;
  final int nc;
  final String filename; // Path completo en carpeta_records

  CaptureRecord({
    required this.ndc,
    required this.ndv,
    required this.nc,
    required this.filename,
  });
}
