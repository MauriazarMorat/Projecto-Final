import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/selected_batch_provider.dart';
import '../providers/gallery_provider.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Cargar el batch seleccionado desde el provider
    final batch = ref.watch(selectedBatchProvider);
    
    final galleryData = ref.watch(galleryProvider);

    if (galleryData.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Estadísticas")),
        body: const Center(
          child: Text(
            "No hay datos disponibles",
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    final sortedNDCs = galleryData.keys.toList()
      ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Estadísticas"),
        actions: [
          // Mostrar indicador si hay un batch seleccionado
          if (batch != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Chip(
                  label: Text(
                    "Batch: NDC ${batch.ndc} - NDV ${batch.ndv}",
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: Colors.green[100],
                ),
              ),
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

            return Card(
              elevation: 4,
              child: InkWell(
                onTap: () {
                  // Al tocar el NDC, abrir la pantalla con cantidad de cabezas
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NdcDetailScreen(ndc: ndc),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder, size: 48, color: Colors.orange[600]),
                      const SizedBox(height: 12),
                      Text(
                        "NDC $ndc",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

class NdcDetailScreen extends ConsumerWidget {
  final String ndc;

  const NdcDetailScreen({super.key, required this.ndc});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Cargar el batch seleccionado desde el provider
    final batch = ref.watch(selectedBatchProvider);
    
    // Por ahora la cantidad de cabezas es fija
    const cantidadCabezas = 17;

    return Scaffold(
      appBar: AppBar(title: Text("NDC $ndc")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Cantidad de Cabezas: $cantidadCabezas",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            // Mostrar información del batch si existe
            if (batch != null) ...[
              const Divider(),
              const SizedBox(height: 16),
              Text(
                "Batch Seleccionado:",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "NDC: ${batch.ndc}",
                style: const TextStyle(fontSize: 16),
              ),
              Text(
                "NDV: ${batch.ndv}",
                style: const TextStyle(fontSize: 16),
              ),
              Text(
                "Capturas: ${batch.selectedPaths.length}",
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ],
        ),
      ),
    );
  }
}