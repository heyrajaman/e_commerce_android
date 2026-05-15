import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/screens/delivery_login_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/cart/presentation/screens/cart_screen.dart';
import '../../features/checkout/presentation/screens/checkout_screen.dart';
import '../../features/checkout/presentation/screens/order_success_screen.dart';
import '../../features/delivery/data/models/delivery_task_model.dart';
import '../../features/delivery/presentation/screens/delivery_dashboard_screen.dart';
import '../../features/delivery/presentation/screens/delivery_profile_screen.dart';
import '../../features/delivery/presentation/screens/delivery_task_detail_screen.dart';
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

      errorBuilder: (context, state) {
        developer.log(
          'Invalid route accessed: ${state.uri.toString()}',
          name: 'AppRouter_Error',
          error: state.error,
        );
        return const SplashScreen();
      },

      redirect: (context, state) {
        final authState = authBloc.state;

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

          if (isAuthRoute || isSplash) {
            if (isDeliveryBoy) {
              return '/delivery-dashboard';
            } else {
              return '/home';
            }
          }

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
        GoRoute(
          path: '/',
          name: 'splash',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          name: 'login',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          name: 'register',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/delivery-login',
          name: 'delivery_login',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const DeliveryLoginScreen(),
        ),
        GoRoute(
          path: '/delivery-dashboard',
          name: 'delivery_dashboard',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const DeliveryDashboardScreen(),
        ),
        GoRoute(
          path: '/delivery-task-details',
          name: 'delivery_task_details',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            if (state.extra is! DeliveryTask) {
              developer.log(
                'Attempted to navigate to task details without valid DeliveryTask extra.',
                name: 'AppRouter',
              );
              return const DeliveryDashboardScreen();
            }
            final task = state.extra as DeliveryTask;
            return DeliveryTaskDetailScreen(task: task);
          },
        ),
        GoRoute(
          path: '/delivery-profile',
          name: 'delivery_profile',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const DeliveryProfileScreen(),
        ),

        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return MainLayoutScreen(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/home',
                  name: 'home',
                  builder: (context, state) => const HomeScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/shop',
                  name: 'shop',
                  builder: (context, state) => const ShopScreen(),
                  routes: [
                    GoRoute(
                      path: 'product/:id',
                      name: 'product_details',
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: (context, state) => ProductDetailsScreen(
                        productId: state.pathParameters['id'] ?? '',
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
                  name: 'cart',
                  builder: (context, state) => const CartScreen(),
                  routes: [
                    GoRoute(
                      path: 'checkout',
                      name: 'checkout',
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: (context, state) => const CheckoutScreen(),
                    ),
                    GoRoute(
                      path: 'order-success/:id',
                      name: 'order_success',
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: (context, state) => OrderSuccessScreen(
                        orderId: state.pathParameters['id'] ?? '',
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
                  name: 'profile',
                  builder: (context, state) => const ProfileScreen(),
                ),
              ],
            ),
          ],
        ),

        GoRoute(
          path: '/orders',
          name: 'orders',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const OrdersScreen(),
        ),
        GoRoute(
          path: '/orders/:id',
          // PROD ROUTING FIX: Matched the name used in your UI dispatches
          name: 'order_details',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) =>
              OrderDetailScreen(orderId: state.pathParameters['id'] ?? ''),
        ),
        GoRoute(
          path: '/addresses',
          name: 'addresses',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const AddressesScreen(),
        ),
      ],
    );
  }
}

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
  GoRouterRefreshStream(Stream<AuthState> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
