import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import 'repository_providers.dart';
import '../../features/auth/providers/auth_notifier.dart';

final userProfileProvider = FutureProvider<User>((ref) async {
  // Watch auth status to re-fetch profile when user changes
  final authState = ref.watch(authControllerProvider);
  
  if (authState.status != AuthStatus.authenticated) {
    throw Exception('User not authenticated');
  }

  final repository = ref.watch(userRepositoryProvider);
  return await repository.getProfile();
});
