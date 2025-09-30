import 'package:flutter/material.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Soporte")),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ExpansionTile(
            leading: const Icon(Icons.contact_mail),
            title: const Text(
              "Contactos",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Para la página web:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text("maurimorat@gmail.com"),
                    Text("esanwos@gmail.com"),
                    SizedBox(height: 12),
                    Text(
                      "Para el dron:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text("martinmanrique@gmail.com"),
                    Text("RivasValen@gmail.com"),
                  ],
                ),
              ),
            ],
          ),
          // Puedes agregar más ExpansionTile para otras secciones si quieres
        ],
      ),
    );
  }
}
