import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../providers/selected_batch_provider.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batch = ref.watch(selectedBatchProvider);

    if (batch == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Resultados")),
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

    if (!batch.isProcessed) {
      return Scaffold(
        appBar: AppBar(title: const Text("Procesando...")),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 24),
              Text(
                "Procesando imágenes con Roboflow...",
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

    final images = batch.processedImages ?? [];
    final totalDetections = batch.totalDetections ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Resultados del Escaneo"),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_a_photo),
            onPressed: () {
              Navigator.pop(context);
            },
            tooltip: "Escanear más imágenes",
          ),
        ],
      ),
      body: Column(
        children: [
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
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: images.length,
              itemBuilder: (context, index) {
                final processedImage = images[index];
                return _buildImageComparisonCard(processedImage);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageComparisonCard(ProcessedImage processedImage) {
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Captura #${processedImage.imageIndex}",
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
                  "Conteo de vacas: ${processedImage.detectionsCount}",
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
                        child: Image.file(
                          File(processedImage.originalPath),
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 200,
                              color: Colors.grey[300],
                              child: const Center(
                                child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
                              ),
                            );
                          },
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
                        child: processedImage.annotatedImageBase64 != null
                            ? Image.memory(
                                base64Decode(processedImage.annotatedImageBase64!),
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 200,
                                    color: Colors.grey[300],
                                    child: const Center(
                                      child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                    ),
                                  );
                                },
                              )
                            : Container(
                                height: 200,
                                color: Colors.grey[300],
                                child: const Center(
                                  child: Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              processedImage.imageName,
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
}