import 'package:flutter/material.dart';
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
import '../models/resource.dart';

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
        pageBuilder: (context, state) => _buildPageWithTransition(
          context,
          state,
          const SplashScreen(),
        ),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => _buildPageWithTransition(
          context,
          state,
          const LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) => _buildPageWithTransition(
          context,
          state,
          const RegisterScreen(),
        ),
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) => _buildPageWithTransition(
          context,
          state,
          const HomeScreen(),
        ),
        routes: [
          GoRoute(
            path: 'topics/:subjectId',
            pageBuilder: (context, state) {
              final subjectId = state.pathParameters['subjectId']!;
              final subjectName = state.extra as String? ?? 'Subject';
              return _buildPageWithTransition(
                context,
                state,
                TopicsScreen(subjectId: subjectId, subjectName: subjectName),
              );
            },
          ),
          GoRoute(
            path: 'topics/:subjectId/:topicId/resources',
            pageBuilder: (context, state) {
              final topicId = state.pathParameters['topicId']!;
              final topicName = state.extra as String? ?? 'Topic';
              return _buildPageWithTransition(
                context,
                state,
                ResourcesScreen(topicId: topicId, topicName: topicName),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/pdf-viewer',
        pageBuilder: (context, state) {
          final resource = state.extra as Resource;
          return _buildPageWithTransition(
            context,
            state,
            PdfViewerScreen(resource: resource),
          );
        },
      ),
    ],
  );
});

CustomTransitionPage _buildPageWithTransition(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.0, 0.03);
      const end = Offset.zero;
      const curve = Curves.easeInOut;

      var tween = Tween(begin: begin, end: end).chain(
        CurveTween(curve: curve),
      );

      var offsetAnimation = animation.drive(tween);
      var fadeAnimation = CurvedAnimation(
        parent: animation,
        curve: curve,
      );

      return FadeTransition(
        opacity: fadeAnimation,
        child: SlideTransition(
          position: offsetAnimation,
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 200),
  );
}
