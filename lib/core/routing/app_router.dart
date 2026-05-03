import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/cart/presentation/screens/cart_screen.dart';
import '../../features/checkout/presentation/screens/checkout_screen.dart';
import '../../features/checkout/presentation/screens/order_success_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/orders/presentation/screens/order_detail_screen.dart';
import '../../features/orders/presentation/screens/orders_screen.dart';
import '../../features/profile/presentation/screens/addresses_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/shop/presentation/screens/product_details_screen.dart';
import '../../features/shop/presentation/screens/shop_screen.dart';
import '../../shared/screens/main_layout_screen.dart';
import '../../shared/widgets/mesh_gradient_background.dart';
import '../theme/app_colors.dart';

class AppRouter {
  // We define a root navigator key so that screens like Product Details,
  // Checkout, and Order Details can push full-screen over the bottom nav bar.
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter createRouter(AuthBloc authBloc) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/',
      refreshListenable: GoRouterRefreshStream(authBloc.stream),
      redirect: (context, state) {
        final authState = authBloc.state;
        final isAuthRoute =
            state.matchedLocation == '/login' ||
            state.matchedLocation == '/register';
        final isSplash = state.matchedLocation == '/';

        if (authState is AuthInitial ||
            (authState is AuthLoading && isSplash)) {
          return null;
        }

        if (authState is AuthUnauthenticated && !isAuthRoute) {
          return '/login';
        }

        if (authState is AuthAuthenticated && (isAuthRoute || isSplash)) {
          return '/home';
        }

        return null;
      },
      routes: [
        // --- Splash & Auth (Full Screen) ---
        GoRoute(
          path: '/',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const RegisterScreen(),
        ),

        // --- The Bottom Navigation Shell ---
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return MainLayoutScreen(navigationShell: navigationShell);
          },
          branches: [
            // Branch 0: Home
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/home',
                  builder: (context, state) => const HomeScreen(),
                ),
              ],
            ),

            // Branch 1: Shop
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/shop',
                  builder: (context, state) => const ShopScreen(),
                  routes: [
                    // Nested route pushed over the root navigator (hides bottom nav)
                    GoRoute(
                      path: 'product/:id',
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: (context, state) {
                        final productId = state.pathParameters['id']!;
                        return ProductDetailsScreen(productId: productId);
                      },
                    ),
                  ],
                ),
              ],
            ),

            // Branch 2: Cart
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/cart',
                  builder: (context, state) => const CartScreen(),
                  routes: [
                    // Checkout flow pushed over bottom nav
                    GoRoute(
                      path: 'checkout',
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: (context, state) => const CheckoutScreen(),
                    ),
                    GoRoute(
                      path: 'order-success/:id',
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: (context, state) {
                        final orderId = state.pathParameters['id']!;
                        return OrderSuccessScreen(orderId: orderId);
                      },
                    ),
                  ],
                ),
              ],
            ),

            // Branch 3: Profile & Orders
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/profile',
                  builder: (context, state) => const ProfileScreen(),
                ),
              ],
            ),
          ],
        ),

        // --- Order Screens (Full Screen, pushed over bottom nav) ---
        // Note: These are placed at the root level because we want them to
        // cover the bottom navigation bar completely when navigating from Profile.
        GoRoute(
          path: '/orders',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const OrdersScreen(),
        ),
        GoRoute(
          path: '/orders/:id',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final orderId = state.pathParameters['id']!;
            return OrderDetailScreen(orderId: orderId);
          },
        ),
        GoRoute(
          path: '/addresses',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const AddressesScreen(),
        ),
      ],
    );
  }
}

// --- Inline Splash Screen ---
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthBloc>().add(const AuthCheckStatusRequested());
    });
  }

  @override
  Widget build(BuildContext context) {
    return const MeshGradientBackground(
      child: Center(
        child: CircularProgressIndicator(color: AppColors.kAccentIndigo),
      ),
    );
  }
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final dynamic _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
