import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'dart:convert';

import '../services/service_locator.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/analytics_service.dart';
import '../services/logger_service.dart';
import '../services/connectivity_service.dart';
import 'app_router.dart';
import 'route_extensions.dart';

import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/subscription/bloc/subscription_bloc.dart';
import '../../features/onboarding/bloc/onboarding_bloc.dart';
import '../../features/settings/bloc/settings_bloc.dart';

/// Base navigation middleware class that all middleware extends
abstract class NavigationMiddleware {
  /// Priority of the middleware (lower runs first)
  final int priority;
  
  /// Name of the middleware for identification
  final String name;
  
  const NavigationMiddleware({
    required this.name,
    this.priority = 100,
  });
  
  /// Process the navigation request
  /// Return null to continue or a String to redirect
  FutureOr<String?> processNavigation(
    BuildContext context,
    GoRouterState state,
    String path,
  );
  
  /// Compare middleware for sorting by priority
  int compareTo(NavigationMiddleware other) {
    return priority.compareTo(other.priority);
  }
}

/// Middleware for authentication checks
class AuthenticationMiddleware extends NavigationMiddleware {
  final AuthService _authService;
  
  AuthenticationMiddleware({
    AuthService? authService,
  }) : 
    _authService = authService ?? sl<AuthService>(),
    super(name: 'Authentication', priority: 10);
  
  @override
  Future<String?> processNavigation(
    BuildContext context,
    GoRouterState state,
    String path,
  ) async {
    // Skip public routes
    if (!context.routeRequiresAuth(path)) {
      return null;
    }
    
    try {
      // Check if user is authenticated
      final isAuthenticated = await _authService.isAuthenticated();
      
      if (!isAuthenticated) {
        // Log the redirect
        if (sl.isRegistered<LoggerService>()) {
          final logger = sl<LoggerService>();
          logger.i('Authentication middleware redirecting to login');
        }
        
        // Store the original path for redirect after login
        if (sl.isRegistered<StorageService>()) {
          final storageService = sl<StorageService>();
          storageService.setString('auth_redirect_path', path);
        }
        
        // Redirect to login
        return AppRoutes.login;
      }
    } catch (e) {
      // Log the error
      if (sl.isRegistered<LoggerService>()) {
        final logger = sl<LoggerService>();
        logger.e('Authentication middleware error: $e');
      }
      
      // Redirect to login on error
      return AppRoutes.login;
    }
    
    // Continue with navigation
    return null;
  }
}

/// Middleware for subscription checks
class SubscriptionMiddleware extends NavigationMiddleware {
  SubscriptionMiddleware() : super(name: 'Subscription', priority: 20);
  
  @override
  FutureOr<String?> processNavigation(
    BuildContext context,
    GoRouterState state,
    String path,
  ) {
    // Skip non-premium routes
    if (!_isPremiumRoute(path)) {
      return null;
    }
    
    try {
      // Check if user has an active subscription from the bloc
      final subscriptionBloc = context.read<SubscriptionBloc>();
      final subscriptionState = subscriptionBloc.state;
      
      final hasActiveSubscription = subscriptionState is SubscriptionActive;
      
      if (!hasActiveSubscription) {
        // Log the redirect
        if (sl.isRegistered<LoggerService>()) {
          final logger = sl<LoggerService>();
          logger.i('Subscription middleware redirecting to pricing');
        }
        
        // Store the original path for redirect after subscription
        if (sl.isRegistered<StorageService>()) {
          final storageService = sl<StorageService>();
          storageService.setString('subscription_redirect_path', path);
        }
        
        // Redirect to pricing page
        return AppRoutes.pricing;
      }
    } catch (e) {
      // Log the error
      if (sl.isRegistered<LoggerService>()) {
        final logger = sl<LoggerService>();
        logger.e('Subscription middleware error: $e');
      }
      
      // Redirect to pricing on error
      return AppRoutes.pricing;
    }
    
    // Continue with navigation
    return null;
  }
  
  /// Check if a route requires premium subscription
  bool _isPremiumRoute(String path) {
    // Define routes that require premium subscription
    final premiumRoutes = [
      '/ai-tutor/study-plan',
      '/business',
      '/quizzes/advanced',
      '/downloads',
    ];
    
    return premiumRoutes.any((route) => path.startsWith(route));
  }
}

/// Middleware for onboarding checks
class OnboardingMiddleware extends NavigationMiddleware {
  final StorageService _storageService;
  
  OnboardingMiddleware({
    StorageService? storageService,
  }) : 
    _storageService = storageService ?? sl<StorageService>(),
    super(name: 'Onboarding', priority: 30);
  
  @override
  FutureOr<String?> processNavigation(
    BuildContext context,
    GoRouterState state,
    String path,
  ) {
    // Skip onboarding routes and public routes
    if (_isOnboardingRoute(path) || !context.routeRequiresAuth(path)) {
      return null;
    }
    
    try {
      // Check if user has completed onboarding
      final hasCompletedOnboarding = _storageService.getBool('has_completed_onboarding') ?? false;
      
      if (!hasCompletedOnboarding) {
        // Check if we have an onboarding bloc
        if (context.read<OnboardingBloc>().state is OnboardingCompleted) {
          // Onboarding is completed in the bloc but not saved, save it
          _storageService.setBool('has_completed_onboarding', true);
          return null;
        }
        
        // Log the redirect
        if (sl.isRegistered<LoggerService>()) {
          final logger = sl<LoggerService>();
          logger.i('Onboarding middleware redirecting to onboarding');
        }
        
        // Store the original path for redirect after onboarding
        _storageService.setString('onboarding_redirect_path', path);
        
        // Redirect to onboarding
        return AppRoutes.onboarding;
      }
    } catch (e) {
      // Log the error
      if (sl.isRegistered<LoggerService>()) {
        final logger = sl<LoggerService>();
        logger.e('Onboarding middleware error: $e');
      }
    }
    
    // Continue with navigation
    return null;
  }
  
  /// Check if a route is part of onboarding
  bool _isOnboardingRoute(String path) {
    final onboardingRoutes = [
      AppRoutes.onboarding,
      AppRoutes.welcome,
      AppRoutes.gradeSelection,
      AppRoutes.subjectSelection,
      AppRoutes.learningStyleQuiz,
    ];
    
    return onboardingRoutes.any((route) => path.startsWith(route));
  }
}

/// Middleware for permission checks
class PermissionMiddleware extends NavigationMiddleware {
  final AuthService _authService;
  
  PermissionMiddleware({
    AuthService? authService,
  }) : 
    _authService = authService ?? sl<AuthService>(),
    super(name: 'Permission', priority: 40);
  
  @override
  Future<String?> processNavigation(
    BuildContext context,
    GoRouterState state,
    String path,
  ) async {
    // Check for admin routes
    if (path.startsWith('/admin')) {
      try {
        // Get current user
        final user = await _authService.getCurrentUser();
        
        // Check if user is admin
        if (user?.role != 'admin') {
          // Log the redirect
          if (sl.isRegistered<LoggerService>()) {
            final logger = sl<LoggerService>();
            logger.i('Permission middleware redirecting to dashboard (not admin)');
          }
          
          // Redirect to dashboard
          return AppRoutes.dashboard;
        }
      } catch (e) {
        // Log the error
        if (sl.isRegistered<LoggerService>()) {
          final logger = sl<LoggerService>();
          logger.e('Permission middleware error: $e');
        }
        
        // Redirect to dashboard on error
        return AppRoutes.dashboard;
      }
    }
    
    // Check for parental control restrictions
    if (sl.isRegistered<SettingsBloc>()) {
      try {
        final settingsBloc = context.read<SettingsBloc>();
        final settings = settingsBloc.state;
        
        // Check if parental controls are enabled
        if (settings.parentalControlsEnabled) {
          // Check if the route is restricted
          if (_isRestrictedRoute(path, settings.restrictedContent)) {
            // Log the redirect
            if (sl.isRegistered<LoggerService>()) {
              final logger = sl<LoggerService>();
              logger.i('Permission middleware redirecting due to parental controls');
            }
            
            // Redirect to dashboard
            return AppRoutes.dashboard;
          }
        }
      } catch (e) {
        // Log the error
        if (sl.isRegistered<LoggerService>()) {
          final logger = sl<LoggerService>();
          logger.e('Permission middleware error (parental controls): $e');
        }
      }
    }
    
    // Continue with navigation
    return null;
  }
  
  /// Check if a route is restricted by parental controls
  bool _isRestrictedRoute(String path, List<String> restrictedContent) {
    // Check for restricted subjects
    for (final subject in restrictedContent) {
      if (path.contains('/$subject/') || path.endsWith('/$subject')) {
        return true;
      }
    }
    
    // Check for specific restricted routes
    final restrictedRoutes = [
      '/social',
      '/chat',
      '/forum',
    ];
    
    return restrictedRoutes.any((route) => path.startsWith(route));
  }
}

/// Middleware for offline mode
class OfflineModeMiddleware extends NavigationMiddleware {
  final ConnectivityService _connectivityService;
  
  OfflineModeMiddleware({
    ConnectivityService? connectivityService,
  }) : 
    _connectivityService = connectivityService ?? sl<ConnectivityService>(),
    super(name: 'OfflineMode', priority: 50);
  
  @override
  Future<String?> processNavigation(
    BuildContext context,
    GoRouterState state,
    String path,
  ) async {
    try {
      // Check connectivity
      final isConnected = await _connectivityService.isConnected();
      
      if (!isConnected) {
        // Skip if the route is accessible offline
        if (context.isRouteOfflineAccessible(path)) {
          // Log offline navigation
          if (sl.isRegistered<LoggerService>()) {
            final logger = sl<LoggerService>();
            logger.i('Navigating to offline-accessible route: $path');
          }
          
          return null;
        }
        
        // Log the redirect
        if (sl.isRegistered<LoggerService>()) {
          final logger = sl<LoggerService>();
          logger.i('Offline middleware redirecting to offline page');
        }
        
        // Store the original path for redirect when online
        if (sl.isRegistered<StorageService>()) {
          final storageService = sl<StorageService>();
          storageService.setString('offline_redirect_path', path);
        }
        
        // Redirect to offline page or dashboard
        // For now, redirect to dashboard as we don't have a dedicated offline page
        return AppRoutes.dashboard;
      }
    } catch (e) {
      // Log the error
      if (sl.isRegistered<LoggerService>()) {
        final logger = sl<LoggerService>();
        logger.e('Offline middleware error: $e');
      }
    }
    
    // Continue with navigation
    return null;
  }
}

/// Middleware for analytics tracking
class AnalyticsMiddleware extends NavigationMiddleware {
  final AnalyticsService? _analyticsService;
  
  AnalyticsMiddleware({
    AnalyticsService? analyticsService,
  }) : 
    _analyticsService = analyticsService ?? (sl.isRegistered<AnalyticsService>() ? sl<AnalyticsService>() : null),
    super(name: 'Analytics', priority: 200);
  
  @override
  FutureOr<String?> processNavigation(
    BuildContext context,
    GoRouterState state,
    String path,
  ) {
    // Skip if analytics service is not available
    if (_analyticsService == null) {
      return null;
    }
    
    try {
      // Log screen view
      _analyticsService!.logScreenView(
        screenName: path,
        screenClass: path.split('/').last,
        parameters: {
          ...state.params,
          ...state.queryParams,
        },
      );
      
      // Log navigation event
      _analyticsService!.logEvent(
        name: 'navigation',
        parameters: {
          'path': path,
          'timestamp': DateTime.now().toIso8601String(),
          'params': jsonEncode(state.params),
          'query_params': jsonEncode(state.queryParams),
        },
      );
    } catch (e) {
      // Log the error
      if (sl.isRegistered<LoggerService>()) {
        final logger = sl<LoggerService>();
        logger.e('Analytics middleware error: $e');
      }
    }
    
    // Continue with navigation
    return null;
  }
}

/// Middleware for route validation
class RouteValidationMiddleware extends NavigationMiddleware {
  RouteValidationMiddleware() : super(name: 'RouteValidation', priority: 60);
  
  @override
  FutureOr<String?> processNavigation(
    BuildContext context,
    GoRouterState state,
    String path,
  ) {
    try {
      // Validate route parameters
      if (!_validateRouteParameters(state)) {
        // Log the redirect
        if (sl.isRegistered<LoggerService>()) {
          final logger = sl<LoggerService>();
          logger.i('Route validation middleware redirecting to error page');
        }
        
        // Redirect to error page
        return AppRoutes.error;
      }
      
      // Validate route query parameters
      if (!_validateQueryParameters(state)) {
        // Log the redirect
        if (sl.isRegistered<LoggerService>()) {
          final logger = sl<LoggerService>();
          logger.i('Route validation middleware redirecting to error page');
        }
        
        // Redirect to error page
        return AppRoutes.error;
      }
    } catch (e) {
      // Log the error
      if (sl.isRegistered<LoggerService>()) {
        final logger = sl<LoggerService>();
        logger.e('Route validation middleware error: $e');
      }
      
      // Redirect to error page on error
      return AppRoutes.error;
    }
    
    // Continue with navigation
    return null;
  }
  
  /// Validate route parameters
  bool _validateRouteParameters(GoRouterState state) {
    final path = state.location;
    
    // Lesson detail validation
    if (path.startsWith('/lessons/') && path.split('/').length >= 3) {
      final lessonId = state.params['lessonId'];
      if (lessonId == null || lessonId.isEmpty) {
        return false;
      }
    }
    
    // Quiz detail validation
    if (path.startsWith('/quizzes/') && path.split('/').length >= 3) {
      final quizId = state.params['quizId'];
      if (quizId == null || quizId.isEmpty) {
        return false;
      }
    }
    
    // Add more route parameter validations as needed
    
    return true;
  }
  
  /// Validate query parameters
  bool _validateQueryParameters(GoRouterState state) {
    final path = state.location;
    
    // Lesson list validation
    if (path == '/lessons') {
      final subject = state.queryParams['subject'];
      final gradeLevel = state.queryParams['gradeLevel'];
      
      // Either both should be present or both should be absent
      if ((subject == null && gradeLevel != null) || (subject != null && gradeLevel == null)) {
        return false;
      }
    }
    
    // Quiz list validation
    if (path == '/quizzes') {
      final subject = state.queryParams['subject'];
      final gradeLevel = state.queryParams['gradeLevel'];
      
      // Either both should be present or both should be absent
      if ((subject == null && gradeLevel != null) || (subject != null && gradeLevel == null)) {
        return false;
      }
    }
    
    // Add more query parameter validations as needed
    
    return true;
  }
}

/// Middleware for error handling
class ErrorHandlingMiddleware extends NavigationMiddleware {
  final LoggerService? _loggerService;
  
  ErrorHandlingMiddleware({
    LoggerService? loggerService,
  }) : 
    _loggerService = loggerService ?? (sl.isRegistered<LoggerService>() ? sl<LoggerService>() : null),
    super(name: 'ErrorHandling', priority: 0);
  
  @override
  FutureOr<String?> processNavigation(
    BuildContext context,
    GoRouterState state,
    String path,
  ) {
    try {
      // This middleware wraps all other middleware in a try-catch
      // It should be the first to run (priority 0)
      return null;
    } catch (e, stackTrace) {
      // Log the error
      if (_loggerService != null) {
        _loggerService!.e(
          'Navigation error',
          error: e,
          stackTrace: stackTrace,
        );
      }
      
      // Store error information for the error page
      if (sl.isRegistered<StorageService>()) {
        final storageService = sl<StorageService>();
        storageService.setString('navigation_error', e.toString());
        storageService.setString('navigation_error_path', path);
      }
      
      // Redirect to error page
      return AppRoutes.error;
    }
  }
}

/// Middleware for navigation logging
class NavigationLoggingMiddleware extends NavigationMiddleware {
  final LoggerService? _loggerService;
  
  NavigationLoggingMiddleware({
    LoggerService? loggerService,
  }) : 
    _loggerService = loggerService ?? (sl.isRegistered<LoggerService>() ? sl<LoggerService>() : null),
    super(name: 'NavigationLogging', priority: 210);
  
  @override
  FutureOr<String?> processNavigation(
    BuildContext context,
    GoRouterState state,
    String path,
  ) {
    // Skip if logger service is not available
    if (_loggerService == null) {
      return null;
    }
    
    try {
      // Log navigation
      _loggerService!.i(
        'Navigation',
        error: {
          'path': path,
          'params': state.params,
          'queryParams': state.queryParams,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      // Ignore logging errors
    }
    
    // Continue with navigation
    return null;
  }
}

/// Middleware for route caching and optimization
class RouteCachingMiddleware extends NavigationMiddleware {
  final StorageService _storageService;
  
  // Cache of recently visited routes
  final Map<String, DateTime> _recentRoutes = {};
  
  // Maximum number of routes to cache
  final int _maxCacheSize = 20;
  
  RouteCachingMiddleware({
    StorageService? storageService,
  }) : 
    _storageService = storageService ?? sl<StorageService>(),
    super(name: 'RouteCaching', priority: 220);
  
  @override
  FutureOr<String?> processNavigation(
    BuildContext context,
    GoRouterState state,
    String path,
  ) {
    try {
      // Add route to recent routes cache
      _recentRoutes[path] = DateTime.now();
      
      // Trim cache if it exceeds maximum size
      if (_recentRoutes.length > _maxCacheSize) {
        final sortedEntries = _recentRoutes.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        
        final routesToKeep = sortedEntries.take(_maxCacheSize).map((e) => e.key).toSet();
        _recentRoutes.removeWhere((key, _) => !routesToKeep.contains(key));
      }
      
      // Save recent routes to storage
      _storageService.setString(
        'recent_routes',
        jsonEncode(_recentRoutes.map((key, value) => MapEntry(key, value.toIso8601String()))),
      );
      
      // Preload data for frequently accessed routes
      _preloadRouteData(context, path);
    } catch (e) {
      // Log the error
      if (sl.isRegistered<LoggerService>()) {
        final logger = sl<LoggerService>();
        logger.e('Route caching middleware error: $e');
      }
    }
    
    // Continue with navigation
    return null;
  }
  
  /// Preload data for frequently accessed routes
  void _preloadRouteData(BuildContext context, String path) {
    // Implement route-specific preloading logic
    if (path.startsWith('/dashboard')) {
      // Preload dashboard data
      // Example: dashboardRepository.preloadDashboardData();
    } else if (path.startsWith('/lessons')) {
      // Preload lessons data
      // Example: lessonRepository.preloadRecentLessons();
    } else if (path.startsWith('/quizzes')) {
      // Preload quizzes data
      // Example: quizRepository.preloadRecentQuizzes();
    }
    
    // Add more preloading logic as needed
  }
  
  /// Load recent routes from storage
  void loadRecentRoutes() {
    try {
      final recentRoutesJson = _storageService.getString('recent_routes');
      
      if (recentRoutesJson != null) {
        final Map<String, dynamic> data = jsonDecode(recentRoutesJson);
        
        data.forEach((key, value) {
          _recentRoutes[key] = DateTime.parse(value);
        });
      }
    } catch (e) {
      // Log the error
      if (sl.isRegistered<LoggerService>()) {
        final logger = sl<LoggerService>();
        logger.e('Error loading recent routes: $e');
      }
      
      // Clear recent routes on error
      _recentRoutes.clear();
    }
  }
  
  /// Get frequently visited routes
  List<String> getFrequentRoutes({int limit = 5}) {
    final routeFrequency = <String, int>{};
    
    // Count route frequencies
    _recentRoutes.keys.forEach((route) {
      routeFrequency[route] = (routeFrequency[route] ?? 0) + 1;
    });
    
    // Sort by frequency
    final sortedRoutes = routeFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Return top routes
    return sortedRoutes.take(limit).map((e) => e.key).toList();
  }
}

/// Registry for all navigation middleware
class NavigationMiddlewareRegistry {
  final List<NavigationMiddleware> _middleware = [];
  
  /// Register a middleware
  void register(NavigationMiddleware middleware) {
    _middleware.add(middleware);
    _sortMiddleware();
  }
  
  /// Register multiple middleware
  void registerAll(List<NavigationMiddleware> middleware) {
    _middleware.addAll(middleware);
    _sortMiddleware();
  }
  
  /// Unregister a middleware by name
  void unregister(String name) {
    _middleware.removeWhere((middleware) => middleware.name == name);
  }
  
  /// Get all registered middleware
  List<NavigationMiddleware> getAll() {
    return List.unmodifiable(_middleware);
  }
  
  /// Process navigation through all middleware
  Future<String?> processNavigation(
    BuildContext context,
    GoRouterState state,
    String path,
  ) async {
    // Process each middleware in order of priority
    for (final middleware in _middleware) {
      final result = await middleware.processNavigation(context, state, path);
      
      // If middleware returns a redirect, stop processing and return it
      if (result != null) {
        return result;
      }
    }
    
    // No redirects, continue with navigation
    return null;
  }
  
  /// Sort middleware by priority
  void _sortMiddleware() {
    _middleware.sort((a, b) => a.compareTo(b));
  }
}

/// Create and configure the default middleware registry
NavigationMiddlewareRegistry createDefaultMiddlewareRegistry() {
  final registry = NavigationMiddlewareRegistry();
  
  // Register middleware in order of priority
  registry.registerAll([
    ErrorHandlingMiddleware(),
    AuthenticationMiddleware(),
    SubscriptionMiddleware(),
    OnboardingMiddleware(),
    PermissionMiddleware(),
    OfflineModeMiddleware(),
    RouteValidationMiddleware(),
    AnalyticsMiddleware(),
    NavigationLoggingMiddleware(),
    RouteCachingMiddleware(),
  ]);
  
  return registry;
}

/// Extension method for BuildContext to access middleware registry
extension MiddlewareRegistryExtension on BuildContext {
  /// Get the middleware registry
  NavigationMiddlewareRegistry get middlewareRegistry {
    return Provider.of<NavigationMiddlewareRegistry>(this, listen: false);
  }
  
  /// Process navigation through middleware
  Future<String?> processNavigationMiddleware(
    GoRouterState state,
    String path,
  ) async {
    return middlewareRegistry.processNavigation(this, state, path);
  }
}

/// GoRouter observer that applies middleware
class MiddlewareRouteObserver extends NavigatorObserver {
  final NavigationMiddlewareRegistry _registry;
  
  MiddlewareRouteObserver(this._registry);
  
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    
    // Process middleware for the new route
    if (route.settings.name != null) {
      final context = route.navigator?.context;
      
      if (context != null) {
        final state = GoRouterState.of(context);
        _registry.processNavigation(context, state, route.settings.name!);
      }
    }
  }
}
