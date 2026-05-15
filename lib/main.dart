import 'dart:async';
import 'dart:developer' as developer;
import 'dart:ui';

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
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/cart/data/repositories/cart_repository.dart';
import 'features/cart/presentation/bloc/cart_bloc.dart';
import 'features/cart/presentation/bloc/cart_event.dart';
import 'features/delivery/data/repositories/delivery_repository.dart';
import 'features/delivery/presentation/bloc/delivery_bloc.dart';
import 'features/orders/data/repositories/order_repository.dart';
import 'features/orders/presentation/bloc/order_bloc.dart';
import 'features/profile/data/repositories/profile_repository.dart';
import 'features/profile/presentation/bloc/profile_bloc.dart';
import 'features/shop/data/repositories/product_repository.dart';
import 'features/shop/presentation/bloc/product_bloc.dart';
import 'shared/services/storage_service.dart';

final sl = GetIt.instance;

void main() async {
  // Ensure framework is initialized before executing asynchronous code
  WidgetsFlutterBinding.ensureInitialized();

  // Global synchronous error handler (UI rendering errors)
  FlutterError.onError = (FlutterErrorDetails details) {
    developer.log(
      'Flutter UI Error',
      error: details.exception,
      stackTrace: details.stack,
      name: 'Main',
    );
    // TODO: Integrate Crashlytics/Sentry reporting here
  };

  // Global asynchronous error handler (Network, isolates, etc.)
  PlatformDispatcher.instance.onError = (error, stack) {
    developer.log('Async Error', error: error, stackTrace: stack, name: 'Main');
    // TODO: Integrate Crashlytics/Sentry reporting here
    return true;
  };

  try {
    await dotenv.load(fileName: ".env");
  } catch (e, stack) {
    developer.log(
      'Environment variables failed to load. Ensure .env exists.',
      error: e,
      stackTrace: stack,
      name: 'Bootstrap',
    );
  }

  try {
    await initDependencies();
    runApp(const MyApp());
  } catch (e, stack) {
    developer.log(
      'Failed to initialize app dependencies.',
      error: e,
      stackTrace: stack,
      name: 'Bootstrap',
    );
    // Consider running a fallback "ErrorApp" widget here if critical services fail
  }
}

Future<void> initDependencies() async {
  // Core Services
  final sharedPrefs = await SharedPreferences.getInstance();
  const secureStorage = FlutterSecureStorage();

  sl.registerLazySingleton<StorageService>(
    () => StorageService(secureStorage, sharedPrefs),
  );

  final apiClient = ApiClient();
  await apiClient.init();
  sl.registerSingleton<ApiClient>(apiClient);

  // Auth Feature
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepository(sl<ApiClient>(), sl<StorageService>()),
  );
  sl.registerLazySingleton<AuthBloc>(
    () => AuthBloc(
      authRepository: sl<AuthRepository>(),
      storageService: sl<StorageService>(),
    ),
  );

  // Shop Feature
  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepository(sl<ApiClient>()),
  );
  sl.registerLazySingleton<ProductBloc>(
    () => ProductBloc(productRepository: sl<ProductRepository>()),
  );

  // Cart Feature
  sl.registerLazySingleton<CartRepository>(
    () => CartRepository(
      apiClient: sl<ApiClient>(),
      storageService: sl<StorageService>(),
    ),
  );
  sl.registerLazySingleton<CartBloc>(
    () => CartBloc(cartRepository: sl<CartRepository>()),
  );

  // Orders Feature
  sl.registerLazySingleton<OrderRepository>(
    () => OrderRepository(apiClient: sl<ApiClient>()),
  );
  sl.registerLazySingleton<OrderBloc>(
    () => OrderBloc(
      orderRepository: sl<OrderRepository>(),
      productRepository: sl<ProductRepository>(),
    ),
  );

  // Profile Feature
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepository(apiClient: sl<ApiClient>()),
  );
  sl.registerLazySingleton<ProfileBloc>(
    () => ProfileBloc(
      profileRepository: sl<ProfileRepository>(),
      authBloc: sl<AuthBloc>(),
    ),
  );

  // Delivery Feature
  sl.registerLazySingleton<DeliveryRepository>(
    () => DeliveryRepository(apiClient: sl<ApiClient>()),
  );
  sl.registerLazySingleton<DeliveryBloc>(
    () => DeliveryBloc(repository: sl<DeliveryRepository>()),
  );

  // Router
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
