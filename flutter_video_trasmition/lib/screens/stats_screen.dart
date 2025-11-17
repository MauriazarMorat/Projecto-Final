import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/processed_gallery_provider.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final processedData = ref.watch(processedGalleryProvider);

    if (processedData.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Resultados Procesados"),
          backgroundColor: Colors.teal,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.analytics_outlined, size: 80, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                "No hay imágenes procesadas",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final sortedNDCs = processedData.keys.toList()
      ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Resultados Procesados"),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(processedGalleryProvider.notifier).refresh(),
            tooltip: "Actualizar",
          ),
        ],
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
          itemCount: sortedNDCs.length,
          itemBuilder: (context, index) {
            final ndc = sortedNDCs[index];
            final ndvMap = processedData[ndc]!;
            final ndvCount = ndvMap.keys.length;
            final totalImages = ndvMap.values
                .map((list) => list.length)
                .reduce((a, b) => a + b);

            return Card(
              elevation: 4,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StatsNDVScreen(
                        ndc: ndc,
                        ndvMap: ndvMap,
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder, size: 48, color: Colors.teal[600]),
                      const SizedBox(height: 12),
                      Text("NDC $ndc",
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text("$ndvCount vuelos",
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey[600])),
                      Text("$totalImages imágenes",
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey[600])),
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

class StatsNDVScreen extends ConsumerWidget {
  final String ndc;
  final Map<String, List<ProcessedImageData>> ndvMap;

  const StatsNDVScreen({
    super.key,
    required this.ndc,
    required this.ndvMap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sortedNDVs = ndvMap.keys.toList()
      ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));

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
            final images = ndvMap[ndv]!;
            final totalDetections =
                images.fold<int>(0, (sum, img) => sum + img.detectionsCount);

            return Card(
              elevation: 4,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StatsNCScreen(
                        ndc: ndc,
                        ndv: ndv,
                        images: images,
                      ),
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
                      Text("NDV $ndv",
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text("${images.length} capturas",
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey[600])),
                      Text("$totalDetections vacas detectadas",
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey[600])),
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

class StatsNCScreen extends ConsumerWidget {
  final String ndc;
  final String ndv;
  final List<ProcessedImageData> images;

  const StatsNCScreen({
    super.key,
    required this.ndc,
    required this.ndv,
    required this.images,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalDetections =
        images.fold<int>(0, (sum, img) => sum + img.detectionsCount);

    return Scaffold(
      appBar: AppBar(
        title: Text("NDC $ndc - NDV $ndv"),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          // Summary Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade400, Colors.teal.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                const Text(
                  "Total de Vacas Detectadas",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  totalDetections.toString(),
                  style: const TextStyle(
                    fontSize: 56,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "en ${images.length} imágenes procesadas",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          // Image Comparison List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: images.length,
              itemBuilder: (context, index) {
                final image = images[index];
                return _buildImageComparisonCard(image, index + 1);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageComparisonCard(ProcessedImageData image, int index) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Captura #$index",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal.shade700,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(Icons.pets, color: Colors.teal.shade600, size: 20),
                const SizedBox(width: 6),
                Text(
                  "Conteo de vacas: ${image.detectionsCount}",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const Text(
                        "Original",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _buildImageWidget(
                          image.beforePath,
                          height: 200,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      const Text(
                        "Procesada",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _buildImageWidget(
                          image.afterPath,
                          height: 200,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              image.ncFolder,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget(String imagePath, {required double height}) {
    final file = File(imagePath);

    if (!file.existsSync()) {
      return Container(
        height: height,
        color: Colors.grey[300],
        child: const Center(
          child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
        ),
      );
    }

    return Image.file(
      file,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: height,
          color: Colors.grey[300],
          child: const Center(
            child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
          ),
        );
      },
    );
  }
}
