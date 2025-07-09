import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:logger/logger.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

// Routing
import 'core/routing/app_router.dart';
import 'core/routing/navigation_middleware.dart';
// Blocs
import 'features/auth/bloc/auth_bloc.dart';
import 'features/subscription/bloc/subscription_bloc.dart';
import 'features/onboarding/bloc/onboarding_bloc.dart';
import 'features/settings/bloc/settings_bloc.dart';
// Service locator & app services
import 'core/services/service_locator.dart';
// Pages
import 'features/dashboard/pages/dashboard_page.dart';

// Initialize service locator
final Logger logger = Logger();

// BLoC observer for debugging
class AppBlocObserver extends BlocObserver {
  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    logger.d(' ');
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    logger.e('', error: error, stackTrace: stackTrace);
    super.onError(bloc, error, stackTrace);
  }
}

Future<void> main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Set up error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    logger.e('Flutter error', error: details.exception, stackTrace: details.stack);
    // FirebaseCrashlytics.instance.recordFlutterError(details);
  };

  // Handle uncaught async errors
  PlatformDispatcher.instance.onError = (error, stack) {
    logger.e('Uncaught platform error', error: error, stackTrace: stack);
    // FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  try {
    // Load environment variables
    await dotenv.load(fileName: 'assets/.env');
    
    // Initialize Firebase
    // await Firebase.initializeApp();
    
    // Initialize all application services via service locator
    await ServiceLocator.init();
    
    // Set up BLoC observer
    Bloc.observer = AppBlocObserver();
    
    // Create navigation middleware registry & router
    final middlewareRegistry = createDefaultMiddlewareRegistry();
    final appRouter = AppRouter();

    // Set preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    // Run the app
    runApp(
      AppWidget(
        appRouter: appRouter,
        middlewareRegistry: middlewareRegistry,
      ),
    );
  } catch (e, stackTrace) {
    logger.e('Initialization error', error: e, stackTrace: stackTrace);
    // FirebaseCrashlytics.instance.recordError(e, stackTrace, fatal: true);
    runApp(const ErrorApp());
  }
}

// Hive adapter registration now handled inside StorageService via ServiceLocator
class AppWidget extends StatelessWidget {
  final AppRouter appRouter;
  final NavigationMiddlewareRegistry middlewareRegistry;

  const AppWidget({
    Key? key,
    required this.appRouter,
    required this.middlewareRegistry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Provider<NavigationMiddlewareRegistry>.value(
      value: middlewareRegistry,
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (_) => sl<AuthBloc>()..add(AuthStarted()),
          ),
          BlocProvider<SubscriptionBloc>(
            create: (_) => sl<SubscriptionBloc>()..add(LoadSubscriptionStatus()),
          ),
          BlocProvider<OnboardingBloc>(
            create: (_) => sl<OnboardingBloc>(),
          ),
          BlocProvider<SettingsBloc>(
            create: (_) => sl<SettingsBloc>()..add(LoadSettingsEvent()),
          ),
        ],
        child: ZimLearnApp(appRouter: appRouter),
      ),
    );
  }
}

class ZimLearnApp extends StatelessWidget {
  final AppRouter appRouter;
  const ZimLearnApp({Key? key, required this.appRouter}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ZimLearn',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: ThemeMode.system,
      routerConfig: appRouter.router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), // English
        Locale('sn', ''), // Shona
        Locale('nd', ''), // Ndebele
      ],
    );
  }

  ThemeData _buildTheme() {
    // Zimbabwean flag colors
    const primaryColor = Color(0xFF008751); // Green
    const secondaryColor = Color(0xFFFFD700); // Yellow/Gold
    const accentColor = Color(0xFFCE1126); // Red
    const neutralColor = Color(0xFF000000); // Black
    
    return ThemeData(
      primaryColor: primaryColor,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        background: Colors.white,
        onBackground: neutralColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(88, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: neutralColor,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: neutralColor,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: neutralColor,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: neutralColor,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: neutralColor,
        ),
      ),
      cardTheme: CardTheme(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      fontFamily: 'Roboto',
    );
  }

  ThemeData _buildDarkTheme() {
    // Darker versions of Zimbabwean flag colors for dark mode
    const primaryColor = Color(0xFF006B40); // Darker Green
    const secondaryColor = Color(0xFFE6C200); // Darker Yellow/Gold
    const accentColor = Color(0xFFB30D21); // Darker Red
    const neutralColor = Color(0xFFE0E0E0); // Light Grey (for text)
    
    return ThemeData.dark().copyWith(
      primaryColor: primaryColor,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        background: const Color(0xFF121212),
        onBackground: neutralColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(88, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: neutralColor,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: neutralColor,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: neutralColor,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: neutralColor,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: neutralColor,
        ),
      ),
      cardTheme: CardTheme(
        elevation: 4,
        color: const Color(0xFF2C2C2C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      fontFamily: 'Roboto',
    );
  }
}

// Temporary Welcome Page
class WelcomePage extends StatelessWidget {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.school,
                  size: 60,
                  color: Color(0xFF008751),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // App Title
              const Text(
                'ZimLearn',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Subtitle
              const Text(
                'Empowering Young Zimbabweans',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              const Text(
                'Learn • Grow • Lead',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 48),
              
              // Get Started Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Navigate to onboarding
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Welcome to ZimLearn! 🇿🇼'),
                        backgroundColor: Color(0xFFFFD700),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF008751),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Get Started',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Version Info
              const Text(
                'Version 1.0.0',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white60,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ErrorApp extends StatelessWidget {
  const ErrorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZimLearn Error',
      theme: ThemeData(
        primaryColor: Colors.red,
        colorScheme: ColorScheme.light(
          primary: Colors.red,
          secondary: Colors.redAccent,
          background: Colors.white,
          error: Colors.red,
        ),
      ),
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 80,
              ),
              const SizedBox(height: 16),
              const Text(
                'Oops! Something went wrong.',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please restart the app or contact support.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (Platform.isAndroid) {
                    SystemNavigator.pop();
                  } else if (Platform.isIOS) {
                    exit(0);
                  }
                },
                child: const Text('Close App'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
