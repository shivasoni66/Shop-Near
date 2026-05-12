import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/providers/live_providers.dart';
import '../../../shared/models/live_session.dart';
import '../../../shared/widgets/live_badge.dart';
import '../../../core/network/socket_service.dart';
import '../../../shared/providers/repository_providers.dart';

class LiveExplorerScreen extends ConsumerStatefulWidget {
  const LiveExplorerScreen({super.key});

  @override
  ConsumerState<LiveExplorerScreen> createState() => _LiveExplorerScreenState();
}

class _LiveExplorerScreenState extends ConsumerState<LiveExplorerScreen> {
  @override
  void initState() {
    super.initState();
    // Listen for real-time live updates so list refreshes instantly
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final socketService = ref.read(socketServiceProvider);
      socketService.on('live_update', (data) {
        if (mounted) ref.invalidate(liveSessionsProvider);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(liveSessionsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.liveRed,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('● LIVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
            ),
            const SizedBox(width: 10),
            Text('Live Shopping', style: AppTextStyles.h3),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(liveSessionsProvider),
          ),
        ],
      ),
      body: sessionsAsync.when(
        data: (sessions) {
          if (sessions.isEmpty) {
            return _buildEmptyState();
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(liveSessionsProvider),
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.72,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final session = sessions[index];
                return _buildLiveCard(context, session);
              },
            ),
          );
        },
        loading: () => _buildShimmerGrid(),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off, size: 60, color: AppColors.muted),
              const SizedBox(height: 12),
              Text('Could not load live sessions', style: AppTextStyles.h4),
              const SizedBox(height: 8),
              Text(err.toString(), style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(liveSessionsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.sensors_off, size: 50, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          Text('No Live Sessions Yet', style: AppTextStyles.h4),
          const SizedBox(height: 8),
          Text(
            'When a seller goes live, they\'ll\nappear here in real-time!',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => ref.invalidate(liveSessionsProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveCard(BuildContext context, LiveSession session) {
    return GestureDetector(
      onTap: () => context.push('/home/live-session', extra: session),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background gradient
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _getGradientForCategory(session.category),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(
                    session.thumbnailPlaceholder,
                    style: const TextStyle(fontSize: 52),
                  ),
                ),
              ),
              // Bottom dark overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 140,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.black.withOpacity(0.85)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              // LIVE badge top-left
              Positioned(
                top: 10,
                left: 10,
                child: const LiveBadge(),
              ),
              // Viewer count top-right
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.remove_red_eye, color: Colors.white, size: 11),
                      const SizedBox(width: 3),
                      Text(
                        '${session.viewers}',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              // Info + Join button
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        session.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.storefront, color: Colors.white60, size: 11),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              session.sellerName,
                              style: const TextStyle(color: Colors.white60, fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Join Live button
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, Color(0xFFFF6B35)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.play_arrow, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Join Live',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Color> _getGradientForCategory(String category) {
    if (category.contains('Fashion') || category.contains('Clothing')) {
      return [const Color(0xFF6A0572), const Color(0xFFEE7B9D)];
    } else if (category.contains('Food')) {
      return [const Color(0xFFFF6B35), const Color(0xFFFFD166)];
    } else if (category.contains('Electronics')) {
      return [const Color(0xFF1A1A2E), const Color(0xFF16213E)];
    } else if (category.contains('Handicraft')) {
      return [const Color(0xFF2E7D32), const Color(0xFF66BB6A)];
    } else if (category.contains('Organic')) {
      return [const Color(0xFF1B5E20), const Color(0xFF81C784)];
    }
    return [const Color(0xFF2B1B54), const Color(0xFF8B5CF6)];
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 4,
      itemBuilder: (context, index) => Container(
        decoration: BoxDecoration(
          color: AppColors.border.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
