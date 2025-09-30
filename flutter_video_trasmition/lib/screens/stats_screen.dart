import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/gallery_provider.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      appBar: AppBar(title: const Text("Estadísticas")),
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

class NdcDetailScreen extends StatelessWidget {
  final String ndc;

  const NdcDetailScreen({super.key, required this.ndc});

  @override
  Widget build(BuildContext context) {
    // Por ahora la cantidad de cabezas es fija
    const cantidadCabezas = 17;

    return Scaffold(
      appBar: AppBar(title: Text("NDC $ndc")),
      body: Center(
        child: Text(
          "Cantidad de Cabezas: $cantidadCabezas",
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
