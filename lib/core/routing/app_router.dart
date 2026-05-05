import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/screens/delivery_login_screen.dart'; // NEW
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/cart/presentation/screens/cart_screen.dart';
import '../../features/checkout/presentation/screens/checkout_screen.dart';
import '../../features/checkout/presentation/screens/order_success_screen.dart';
import '../../features/delivery/data/models/delivery_task_model.dart'; // NEW
import '../../features/delivery/presentation/screens/delivery_dashboard_screen.dart'; // NEW
import '../../features/delivery/presentation/screens/delivery_task_detail_screen.dart'; // NEW
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
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter createRouter(AuthBloc authBloc) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/',
      refreshListenable: GoRouterRefreshStream(authBloc.stream),
      redirect: (context, state) {
        final authState = authBloc.state;

        // 1. ADDED /delivery-login to the auth routes check
        final isAuthRoute =
            state.matchedLocation == '/login' ||
            state.matchedLocation == '/register' ||
            state.matchedLocation == '/delivery-login';

        final isSplash = state.matchedLocation == '/';

        if (authState is AuthInitial ||
            (authState is AuthLoading && isSplash)) {
          return null;
        }

        if (authState is AuthUnauthenticated && !isAuthRoute) {
          return '/login';
        }

        if (authState is AuthAuthenticated) {
          final role = authState.user.role;
          final isDeliveryBoy = role == 'delivery_boy';

          // 2. Routing logic based on role when hitting splash or auth screens
          if (isAuthRoute || isSplash) {
            if (isDeliveryBoy) {
              return '/delivery-dashboard'; // Route Delivery Boys here
            } else {
              return '/home'; // Route Customers here
            }
          }

          // 3. Security: Prevent customers from accessing delivery routes and vice versa
          final isGoingToDelivery = state.matchedLocation.startsWith(
            '/delivery',
          );
          if (isDeliveryBoy && !isGoingToDelivery) {
            return '/delivery-dashboard';
          } else if (!isDeliveryBoy && isGoingToDelivery) {
            return '/home';
          }
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

        // --- NEW: Delivery Login Route ---
        GoRoute(
          path: '/delivery-login',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const DeliveryLoginScreen(),
        ),

        // --- NEW: Delivery Dashboard Route (Full Screen, bypasses bottom nav) ---
        GoRoute(
          path: '/delivery-dashboard',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const DeliveryDashboardScreen(),
        ),

        GoRoute(
          path: '/delivery-task-details',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            // Read the task we passed in the button's 'extra' parameter
            final task = state.extra as DeliveryTask;
            return DeliveryTaskDetailScreen(task: task);
          },
        ),

        // --- The Bottom Navigation Shell ---
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return MainLayoutScreen(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/home',
                  builder: (context, state) => const HomeScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/shop',
                  builder: (context, state) => const ShopScreen(),
                  routes: [
                    GoRoute(
                      path: 'product/:id',
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: (context, state) => ProductDetailsScreen(
                        productId: state.pathParameters['id']!,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/cart',
                  builder: (context, state) => const CartScreen(),
                  routes: [
                    GoRoute(
                      path: 'checkout',
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: (context, state) => const CheckoutScreen(),
                    ),
                    GoRoute(
                      path: 'order-success/:id',
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: (context, state) => OrderSuccessScreen(
                        orderId: state.pathParameters['id']!,
                      ),
                    ),
                  ],
                ),
              ],
            ),
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

        // --- Order & Profile Screens (Full Screen) ---
        GoRoute(
          path: '/orders',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const OrdersScreen(),
        ),
        GoRoute(
          path: '/orders/:id',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) =>
              OrderDetailScreen(orderId: state.pathParameters['id']!),
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
