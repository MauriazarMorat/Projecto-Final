import 'package:flutter/material.dart';
import 'package:flutter_video_trasmition/screens/video_screen.dart';
// Pantalla de ejemplo para navegación


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int? hoveredIndexFila1;
  int? hoveredIndexFila2;
  int? hoveredIndexFila3;
  int? hoveredFila;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tooSmall = constraints.maxWidth < 500 || constraints.maxHeight < 500;

        return Scaffold(
          backgroundColor: const Color.fromARGB(255, 34, 34, 34),
          body: tooSmall
              ? const Center(
                  child: Text(
                    'Pantalla demasiado pequeña para mostrar la interfaz.',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : Column(
                  children: [
                    // Fila 1
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
                              child: buildCard(
                                color: const Color(0xFFB39DDB),
                                icon: Icons.dashboard,
                                text: 'Panel principal',
                                onTap: null,
                                isHovered: isHovered,
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
                        children: [
                          buildHoverableCard(
                            index: 0,
                            hoveredIndex: hoveredIndexFila2,
                            onEnter: () {
                              hoveredIndexFila2 = 0;
                              hoveredFila = 2;
                            },
                            onExit: () {
                              hoveredIndexFila2 = null;
                              hoveredFila = null;
                            },
                            color: const Color(0xFF81D4FA),
                            icon: Icons.analytics,
                            text: 'Estadísticas',
                          ),
                          buildHoverableCard(
                            index: 1,
                            hoveredIndex: hoveredIndexFila2,
                            onEnter: () {
                              hoveredIndexFila2 = 1;
                              hoveredFila = 2;
                            },
                            onExit: () {
                              hoveredIndexFila2 = null;
                              hoveredFila = null;
                            },
                            color: const Color(0xFFA5D6A7),
                            icon: Icons.video_camera_back_rounded,
                            text: 'Ver video',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const VideoScreen()),
                              );
                            },
                          ),
                          buildHoverableCard(
                            index: 2,
                            hoveredIndex: hoveredIndexFila2,
                            onEnter: () {
                              hoveredIndexFila2 = 2;
                              hoveredFila = 2;
                            },
                            onExit: () {
                              hoveredIndexFila2 = null;
                              hoveredFila = null;
                            },
                            color: const Color(0xFFFFAB91),
                            icon: Icons.settings,
                            text: 'Configuración',
                          ),
                        ],
                      ),
                    ),

                    // Fila 3
                    Expanded(
                      flex: hoveredFila == 3 ? 4 : 2,
                      child: Row(
                        children: [
                          buildHoverableCard(
                            index: 0,
                            hoveredIndex: hoveredIndexFila3,
                            onEnter: () {
                              hoveredIndexFila3 = 0;
                              hoveredFila = 3;
                            },
                            onExit: () {
                              hoveredIndexFila3 = null;
                              hoveredFila = null;
                            },
                            color: const Color(0xFFFFF59D),
                            icon: Icons.notifications,
                            text: 'Notificaciones',
                          ),
                          buildHoverableCard(
                            index: 1,
                            hoveredIndex: hoveredIndexFila3,
                            onEnter: () {
                              hoveredIndexFila3 = 1;
                              hoveredFila = 3;
                            },
                            onExit: () {
                              hoveredIndexFila3 = null;
                              hoveredFila = null;
                            },
                            color: const Color.fromARGB(255, 179, 18, 157),
                            icon: Icons.support,
                            text: 'Soporte',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  /// Función para oscurecer levemente un color
  Color darken(Color color, [double amount = .2]) {
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  /// Tarjeta con InkWell y hover color
  Widget buildCard({
    required Color color,
    required IconData icon,
    required String text,
    VoidCallback? onTap,
    bool isHovered = false,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: isHovered ? darken(color) : color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: const Color.fromARGB(255, 0, 0, 0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: const Color.fromARGB(221, 0, 0, 0)),
              const SizedBox(height: 10),
              Text(
                text,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builder reutilizable
  Widget buildHoverableCard({
    required int index,
    required int? hoveredIndex,
    required VoidCallback onEnter,
    required VoidCallback onExit,
    required Color color,
    required IconData icon,
    required String text,
    VoidCallback? onTap,
  }) {
    final isHovered = hoveredIndex == index;
    final flexValue = isHovered ? 4 : 2;

    return Expanded(
      flex: flexValue,
      child: MouseRegion(
        onEnter: (_) => setState(onEnter),
        onExit: (_) => setState(onExit),
        child: buildCard(
          color: color,
          icon: icon,
          text: text,
          onTap: onTap,
          isHovered: isHovered,
        ),
      ),
    );
  }
}
