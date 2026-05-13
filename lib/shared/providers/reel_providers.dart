import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/reel.dart';
import 'repository_providers.dart';

// ---------------------------------------------------------------------------
// ReelsNotifier — holds the live reel list, handles initial fetch + socket
// ---------------------------------------------------------------------------
class ReelsNotifier extends StateNotifier<AsyncValue<List<Reel>>> {
  ReelsNotifier(this._ref) : super(const AsyncValue.loading()) {
    _load();
    _listenSocket();
  }

  final Ref _ref;

  Future<void> _load() async {
    try {
      final reels = await _ref.read(reelRepositoryProvider).getAllReels();
      if (mounted) state = AsyncValue.data(reels);
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  void _listenSocket() {
    final socket = _ref.read(socketServiceProvider);
    socket.connect();
    socket.on('new_reel', (data) {
      if (!mounted) return;
      try {
        final newReel = Reel.fromMap(Map<String, dynamic>.from(data as Map));
        state.whenData((current) {
          // Prepend the new reel so it appears at the top of the feed
          state = AsyncValue.data([newReel, ...current]);
        });
      } catch (_) {
        // Malformed payload — silently ignore and re-fetch
        refresh();
      }
    });

    socket.on('reel_updated', (data) {
      if (!mounted) return;
      try {
        final updatedReel = Reel.fromMap(Map<String, dynamic>.from(data as Map));
        state.whenData((current) {
          final updatedList = current.map((reel) {
            return reel.id == updatedReel.id ? updatedReel : reel;
          }).toList();
          state = AsyncValue.data(updatedList);
        });
      } catch (_) {
        // Silently ignore
      }
    });

    socket.on('reel_deleted', (data) {
      if (!mounted) return;
      try {
        final deletedId = data as String;
        state.whenData((current) {
          final updatedList = current.where((reel) => reel.id != deletedId).toList();
          state = AsyncValue.data(updatedList);
        });
      } catch (_) {
        // Silently ignore
      }
    });
  }

  /// Call this to force a fresh fetch (e.g. pull-to-refresh).
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _load();
  }

  @override
  void dispose() {
    _ref.read(socketServiceProvider).off('new_reel');
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------
final reelsProvider =
    StateNotifierProvider<ReelsNotifier, AsyncValue<List<Reel>>>(
  (ref) => ReelsNotifier(ref),
);

// Provider to fetch only the logged-in seller's reels
final sellerReelsProvider = FutureProvider.autoDispose<List<Reel>>((ref) async {
  final repository = ref.watch(reelRepositoryProvider);
  return await repository.getMyReels();
});

final reelCommentsProvider = FutureProvider.family<List<dynamic>, String>((ref, reelId) async {
  final repository = ref.watch(reelRepositoryProvider);
  return await repository.getReelComments(reelId);
});
