import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../screens/home_screen.dart';
import '../screens/video_screen.dart';
import '../screens/gallery_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path:  '/video',
        builder: (context, state) => const VideoScreen(),
        ),
        GoRoute(
        path: '/gallery',
        builder: (context, state) => const GalleryScreen(),
        ),

    
    
    
    ],
  );
});
