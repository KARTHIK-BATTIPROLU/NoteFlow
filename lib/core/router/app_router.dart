import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/home/presentation/screens/topics_screen.dart';
import '../../features/home/presentation/screens/resources_screen.dart';
import '../../features/home/presentation/screens/pdf_viewer_screen.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      if (authState.isLoading) return '/';
      
      final loggedIn = authState.valueOrNull != null;
      final loggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/register';

      if (!loggedIn && !loggingIn) return '/login';
      if (loggedIn && loggingIn) return '/home';
      if (loggedIn && state.matchedLocation == '/') return '/home';

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
        routes: [
          GoRoute(
            path: 'topics/:subjectId',
            builder: (context, state) {
              final subjectId = state.pathParameters['subjectId']!;
              final subjectName = state.extra as String? ?? 'Subject';
              return TopicsScreen(subjectId: subjectId, subjectName: subjectName);
            },
          ),
          GoRoute(
            path: 'topics/:subjectId/:topicId/resources',
            builder: (context, state) {
              final topicId = state.pathParameters['topicId']!;
              final topicName = state.extra as String? ?? 'Topic';
              return ResourcesScreen(topicId: topicId, topicName: topicName);
            },
          ),
          GoRoute(
            path: 'pdf-viewer',
            builder: (context, state) {
              final path = state.extra as String;
              return PdfViewerScreen(path: path);
            },
          ),
        ],
      ),
    ],
  );
});
