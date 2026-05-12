import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/discover/presentation/discover_screen.dart';
import '../../features/discover/presentation/category_results_screen.dart';
import '../../features/live/presentation/live_session_screen.dart';
import '../../features/live/presentation/live_explorer_screen.dart';
import '../../shared/models/live_session.dart';
import '../../features/product/presentation/product_detail_screen.dart';
import '../../features/shop/presentation/shop_page_screen.dart';
import '../../features/cart/presentation/cart_screen.dart';
import '../../features/chat/presentation/chat_list_screen.dart';
import '../../features/chat/presentation/chat_detail_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/profile_edit_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/order_tracking/presentation/order_tracking_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';

import '../../features/seller/presentation/seller_dashboard_screen.dart';
import '../../features/seller/presentation/seller_products_screen.dart';
import '../../features/seller/presentation/seller_orders_screen.dart';
import '../../features/seller/presentation/seller_analytics_screen.dart';
import '../../features/seller/presentation/add_product_screen.dart';
import '../../features/seller/presentation/go_live_setup_screen.dart';
import '../../features/reels/presentation/post_reel_screen.dart';
import '../../features/reels/presentation/reels_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/providers/auth_notifier.dart';

import '../../shared/widgets/app_bottom_nav.dart';
import '../../shared/widgets/seller_bottom_nav.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _buyerShellNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _sellerShellNavigatorKey = GlobalKey<NavigatorState>();

class AuthRefreshNotifier extends ChangeNotifier {
  AuthRefreshNotifier(Ref ref) {
    ref.listen(authControllerProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: AuthRefreshNotifier(ref),
    redirect: (context, state) {
      final status = authState.status;
      final user = authState.user;

      // While checking auth status or loading, don't redirect yet
      if (status == AuthStatus.initial || status == AuthStatus.loading) {
        return null;
      }

      final isLoggingIn = state.uri.path == '/login' || state.uri.path == '/register' || state.uri.path == '/';

      if (status == AuthStatus.authenticated) {
        if (isLoggingIn) {
          return user?.role == 'seller' ? '/seller' : '/home';
        }
      } else if (status == AuthStatus.unauthenticated || status == AuthStatus.error) {
        if (!isLoggingIn) {
          return '/';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const OnboardingScreen(),
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
        path: '/home/live',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LiveExplorerScreen(),
      ),
      GoRoute(
        path: '/home/live-session',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => LiveSessionScreen(
          session: state.extra as LiveSession?,
        ),
      ),
      GoRoute(
        path: '/home/product/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => ProductDetailScreen(
          productId: state.pathParameters['id'],
        ),
      ),
      GoRoute(
        path: '/home/shop/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ShopPageScreen(),
      ),
      GoRoute(
        path: '/home/cart',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: '/home/notifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/home/order-track',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => OrderTrackingScreen(
          orderId: state.uri.queryParameters['orderId'],
        ),
      ),
      GoRoute(
        path: '/home/profile/orders/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => OrderTrackingScreen(
          orderId: state.pathParameters['id'],
        ),
      ),
      GoRoute(
        path: '/home/settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/home/discover/:category',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => CategoryResultsScreen(
          category: state.pathParameters['category'] ?? 'Category',
        ),
      ),
      GoRoute(
        path: '/home/chat/:name',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => ChatDetailScreen(
          name: state.pathParameters['name'] ?? 'Chat',
        ),
      ),
      ShellRoute(
        navigatorKey: _buyerShellNavigatorKey,
        builder: (context, state, child) {
          return Scaffold(
            body: child,
            bottomNavigationBar: AppBottomNav(currentRoute: state.uri.path),
          );
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/home/videos',
            builder: (context, state) => const ReelsScreen(),
          ),
          GoRoute(
            path: '/home/discover',
            builder: (context, state) => const DiscoverScreen(),
          ),
          GoRoute(
            path: '/home/chat',
            builder: (context, state) => const ChatListScreen(),
          ),
          GoRoute(
            path: '/home/profile',
            builder: (context, state) => const ProfileScreen(),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (context, state) => const ProfileEditScreen(),
              ),
            ],
          ),
        ],
      ),
      ShellRoute(
        navigatorKey: _sellerShellNavigatorKey,
        builder: (context, state, child) {
          return Scaffold(
            body: child,
            bottomNavigationBar: SellerBottomNav(currentRoute: state.uri.path),
          );
        },
        routes: [
          GoRoute(
            path: '/seller',
            builder: (context, state) => const SellerDashboardScreen(),
          ),
          GoRoute(
            path: '/seller/products',
            builder: (context, state) => const SellerProductsScreen(),
          ),
          GoRoute(
            path: '/seller/orders',
            builder: (context, state) => const SellerOrdersScreen(),
          ),
          GoRoute(
            path: '/seller/analytics',
            builder: (context, state) => const SellerAnalyticsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/seller/products/add',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AddProductScreen(),
      ),
      GoRoute(
        path: '/seller/golive',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const GoLiveSetupScreen(),
      ),
      GoRoute(
        path: '/seller/post-reel',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PostReelScreen(),
      ),
    ],
  );
});

}
