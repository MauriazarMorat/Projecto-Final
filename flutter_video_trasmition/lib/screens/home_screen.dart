import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int? hoveredIndexFila1;
  int? hoveredIndexFila2;
  int? hoveredIndexFila3;
  int? hoveredFila; // Nueva: para expandir fila entera verticalmente

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 27, 27, 27),
      body: Column(
        children: [
          // Fila 1 (vertical hover)
          Expanded(
            flex: hoveredFila == 1 ? 4 : 2,
            child: Row(
              children: List.generate(1, (index) {
                final isHovered = hoveredIndexFila1 == index;
                final flexValue = isHovered ? 4 : 2;

                return Expanded(
                  flex: flexValue,
                  child: MouseRegion(
                    onEnter: (_) {
                      setState(() {
                        hoveredIndexFila1 = index;
                        hoveredFila = 1;
                      });
                    },
                    onExit: (_) {
                      setState(() {
                        hoveredIndexFila1 = null;
                        hoveredFila = null;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.all(10),
                      child: Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        clipBehavior: Clip.antiAlias,
                        child: Container(color: const Color.fromARGB(255, 138, 36, 206)),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Fila 2
          Expanded(
            flex: hoveredFila == 2 ? 5 : 3,
            child: Row(
              children: List.generate(3, (index) {
                final isHovered = hoveredIndexFila2 == index;
                final flexValue = isHovered ? 4 : 2;

                return Expanded(
                  flex: flexValue,
                  child: MouseRegion(
                    onEnter: (_) {
                      setState(() {
                        hoveredIndexFila2 = index;
                        hoveredFila = 2;
                      });
                    },
                    onExit: (_) {
                      setState(() {
                        hoveredIndexFila2 = null;
                        hoveredFila = null;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      child: Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        clipBehavior: Clip.antiAlias,
                        child: Container(
                          color: [
                            Colors.red,
                            const Color.fromARGB(255, 0, 255, 55),
                            const Color.fromARGB(255, 0, 110, 255)
                          ][index],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Fila 3
          Expanded(
            flex: hoveredFila == 3 ? 4 : 2,
            child: Row(
              children: List.generate(2, (index) {
                final isHovered = hoveredIndexFila3 == index;
                final flexValue = isHovered ? 4 : 2;

                return Expanded(
                  flex: flexValue,
                  child: MouseRegion(
                    onEnter: (_) {
                      setState(() {
                        hoveredIndexFila3 = index;
                        hoveredFila = 3;
                      });
                    },
                    onExit: (_) {
                      setState(() {
                        hoveredIndexFila3 = null;
                        hoveredFila = null;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      child: Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        clipBehavior: Clip.antiAlias,
                        child: Container(
                          color: [
                            const Color.fromARGB(255, 187, 250, 12),
                            const Color.fromARGB(255, 255, 0, 119),
                          ][index],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
