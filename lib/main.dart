import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/network/api_client.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_state.dart'; // Added for the listener
import 'features/cart/data/repositories/cart_repository.dart'; // Added for Cart
import 'features/cart/presentation/bloc/cart_bloc.dart'; // Added for Cart
import 'features/cart/presentation/bloc/cart_event.dart';
import 'features/delivery/data/repositories/delivery_repository.dart';
import 'features/delivery/presentation/bloc/delivery_bloc.dart';
import 'features/orders/data/repositories/order_repository.dart';
import 'features/orders/presentation/bloc/order_bloc.dart';
import 'features/profile/data/repositories/profile_repository.dart';
import 'features/profile/presentation/bloc/profile_bloc.dart'; // Added for Cart
import 'features/shop/data/repositories/product_repository.dart';
import 'features/shop/presentation/bloc/product_bloc.dart';
import 'shared/services/storage_service.dart';

final sl = GetIt.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await initDependencies();
  runApp(const MyApp());
}

Future<void> initDependencies() async {
  // 1. Core Services
  final sharedPrefs = await SharedPreferences.getInstance();
  const secureStorage = FlutterSecureStorage();
  sl.registerLazySingleton<StorageService>(
    () => StorageService(secureStorage, sharedPrefs),
  );

  final apiClient = ApiClient();
  await apiClient.init();
  sl.registerSingleton<ApiClient>(apiClient);
  // 2. Features - Auth
  sl.registerLazySingleton(
    () => AuthRepository(sl<ApiClient>(), sl<StorageService>()),
  );
  sl.registerLazySingleton<AuthBloc>(
    () => AuthBloc(
      authRepository: sl<AuthRepository>(),
      storageService: sl<StorageService>(),
    ),
  );

  // 2. Features - Shop
  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepository(sl<ApiClient>()),
  );
  sl.registerLazySingleton<ProductBloc>(
    () => ProductBloc(productRepository: sl<ProductRepository>()),
  );

  // 2. Features - Cart
  sl.registerLazySingleton<CartRepository>(
    () => CartRepository(
      apiClient: sl<ApiClient>(),
      storageService: sl<StorageService>(),
    ),
  );
  sl.registerLazySingleton<CartBloc>(
    () => CartBloc(cartRepository: sl<CartRepository>()),
  );

  // 2. Features - Orders (NEW)
  sl.registerLazySingleton<OrderRepository>(
    () => OrderRepository(apiClient: sl<ApiClient>()),
  );
  sl.registerLazySingleton<OrderBloc>(
    () => OrderBloc(
      orderRepository: sl<OrderRepository>(),
      productRepository: sl<ProductRepository>(),
    ),
  );

  // 2. Features - Profile (NEW)
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepository(apiClient: sl<ApiClient>()),
  );
  sl.registerLazySingleton<ProfileBloc>(
    () => ProfileBloc(
      profileRepository: sl<ProfileRepository>(),
      authBloc: sl<AuthBloc>(),
    ),
  );

  // --- NEW: Features - Delivery ---
  sl.registerLazySingleton<DeliveryRepository>(
    () => DeliveryRepository(apiClient: sl<ApiClient>()),
  );
  sl.registerLazySingleton<DeliveryBloc>(
    () => DeliveryBloc(repository: sl<DeliveryRepository>()),
  );

  // 3. Router
  // We create a singleton instance of AuthBloc to pass to the router for redirect logic
  final authBlocForRouter = sl<AuthBloc>();
  sl.registerLazySingleton<GoRouter>(
    () => AppRouter.createRouter(authBlocForRouter),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(create: (_) => sl<AuthBloc>()),
        BlocProvider<ProductBloc>(create: (_) => sl<ProductBloc>()),
        BlocProvider<CartBloc>(create: (_) => sl<CartBloc>()),
        BlocProvider<OrderBloc>(create: (_) => sl<OrderBloc>()),
        BlocProvider<ProfileBloc>(create: (_) => sl<ProfileBloc>()),
        BlocProvider<DeliveryBloc>(create: (_) => sl<DeliveryBloc>()),
      ],
      // We wrap the MaterialApp in a BlocListener for AuthBloc
      // to automatically fetch the cart when authentication succeeds.
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            context.read<CartBloc>().add(const CartFetchRequested());
          } else if (state is AuthUnauthenticated) {
            context.read<CartBloc>().add(const CartResetLocal());
          }
        },
        child: MaterialApp.router(
          title: 'E-Commerce App',
          debugShowCheckedModeBanner: false,
          routerConfig: sl<GoRouter>(),
          theme: AppTheme.lightTheme,
        ),
      ),
    );
  }
}
