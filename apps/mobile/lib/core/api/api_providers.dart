import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';
import '../auth/auth_repository.dart';
import 'materials_repository.dart';
import 'messages_repository.dart';
import 'subscriptions_repository.dart';
import 'media_repository.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiClientProvider));
});

/// Utilisateur connecté (null si non connecté)
final currentUserProvider = StateProvider<Map<String, dynamic>?>((ref) => null);

/// État d'authentification
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});

final materialsRepositoryProvider = Provider<MaterialsRepository>((ref) {
  return MaterialsRepository(ref.watch(apiClientProvider));
});


final messagesRepositoryProvider = Provider<MessagesRepository>((ref) {
  return MessagesRepository(ref.watch(apiClientProvider));
});


final subscriptionsRepositoryProvider = Provider<SubscriptionsRepository>((ref) {
  return SubscriptionsRepository(ref.watch(apiClientProvider));
});


final mediaRepositoryProvider = Provider<MediaRepository>((ref) {
  return MediaRepository(ref.watch(apiClientProvider));
});
