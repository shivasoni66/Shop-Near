import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/live_badge.dart';
import '../../../../shared/providers/live_providers.dart';

class LiveCardsRowWidget extends ConsumerWidget {
  const LiveCardsRowWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(liveSessionsProvider);

    return sessionsAsync.when(
      data: (sessions) => SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(left: 16, right: 4, bottom: 12),
      child: Row(
        children: sessions.map((session) {
          return GestureDetector(
            onTap: () => context.push('/home/live'),
            child: Container(
              width: 136,
              height: 178,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  colors: [Color(0xFFF093FB), Color(0xFFF5576C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Center(
                      child: Text(session.thumbnailPlaceholder,
                          style: const TextStyle(fontSize: 44))),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.75)
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.35, 1.0],
                      ),
                    ),
                  ),
                  const Positioned(
                    top: 9,
                    left: 9,
                    child: LiveBadge(),
                  ),
                  Positioned(
                    top: 9,
                    right: 9,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.remove_red_eye,
                              color: Colors.white, size: 10),
                          const SizedBox(width: 3),
                          Text(
                            session.viewers.toString(),
                            style: AppTextStyles.labelSmall
                                .copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    left: 10,
                    right: 10,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.sellerName,
                          style: AppTextStyles.labelMedium.copyWith(
                              color: Colors.white, fontWeight: FontWeight.w800),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          session.category,
                          style: AppTextStyles.labelSmall
                              .copyWith(color: Colors.white.withOpacity(0.8)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    ),
      loading: () => const SizedBox(height: 178, child: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}
