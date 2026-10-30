import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/materials/screens/add_material_screen.dart';
import '../features/materials/screens/material_detail_screen.dart';
import '../features/search/screens/search_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/messages/screens/conversations_screen.dart';
import '../features/messages/screens/chat_screen.dart';
import '../features/subscriptions/screens/subscription_screen.dart';
import '../shared/widgets/main_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),

    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
        GoRoute(path: '/search', builder: (context, state) => const SearchScreen()),
        GoRoute(path: '/add', builder: (context, state) => const AddMaterialScreen()),
        GoRoute(path: '/messages', builder: (context, state) => const ConversationsScreen()),
        GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
      ],
    ),

    GoRoute(
      path: '/materials/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return MaterialDetailScreen(materialId: id);
      },
    ),

    GoRoute(
      path: '/subscription',
      builder: (context, state) => const SubscriptionScreen(),
    ),
    GoRoute(
      path: '/messages/:partnerId',
      builder: (context, state) {
        final partnerId = state.pathParameters['partnerId']!;
        final name = state.uri.queryParameters['name'] ?? '';
        final materialId = state.uri.queryParameters['materialId'];
        return ChatScreen(
          partnerId: partnerId,
          partnerName: name,
          materialId: materialId,
        );
      },
    ),
  ],
);
