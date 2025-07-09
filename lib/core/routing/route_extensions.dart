import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

import '../services/service_locator.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../services/logger_service.dart';
import 'app_router.dart';

/// Extension methods on BuildContext for easier navigation
extension GoRouterContextExtension on BuildContext {
  /// Get the GoRouter instance
  GoRouter get router => GoRouter.of(this);
  
  /// Navigate to a named route
  void goNamed(
    String name, {
    Map<String, String> params = const <String, String>{},
    Map<String, String> queryParams = const <String, String>{},
    Object? extra,
  }) {
    router.goNamed(
      name,
      params: params,
      queryParams: queryParams,
      extra: extra,
    );
    
    // Log navigation if analytics service is available
    _logNavigation(name, params, queryParams);
  }
  
  /// Push a named route
  void pushNamed(
    String name, {
    Map<String, String> params = const <String, String>{},
    Map<String, String> queryParams = const <String, String>{},
    Object? extra,
  }) {
    router.pushNamed(
      name,
      params: params,
      queryParams: queryParams,
      extra: extra,
    );
    
    // Log navigation if analytics service is available
    _logNavigation(name, params, queryParams);
  }
  
  /// Replace current route with a named route
  void replaceNamed(
    String name, {
    Map<String, String> params = const <String, String>{},
    Map<String, String> queryParams = const <String, String>{},
    Object? extra,
  }) {
    router.replaceNamed(
      name,
      params: params,
      queryParams: queryParams,
      extra: extra,
    );
    
    // Log navigation if analytics service is available
    _logNavigation(name, params, queryParams);
  }
  
  /// Go to a location
  void go(
    String location, {
    Object? extra,
  }) {
    router.go(location, extra: extra);
    
    // Log navigation if analytics service is available
    _logNavigation(location, {}, {});
  }
  
  /// Push a location
  void push(
    String location, {
    Object? extra,
  }) {
    router.push(location, extra: extra);
    
    // Log navigation if analytics service is available
    _logNavigation(location, {}, {});
  }
  
  /// Replace current route with a location
  void replace(
    String location, {
    Object? extra,
  }) {
    router.replace(location, extra: extra);
    
    // Log navigation if analytics service is available
    _logNavigation(location, {}, {});
  }
  
  /// Pop the current route
  void pop<T extends Object?>([T? result]) {
    router.pop(result);
  }
  
  /// Check if can pop
  bool canPop() => router.canPop();
  
  /// Pop until a specific route
  void popUntil(String location) {
    while (router.canPop() && router.location != location) {
      router.pop();
    }
  }
  
  /// Get the current route location
  String get currentLocation => router.location;
  
  /// Get route state
  GoRouterState get routeState => GoRouterState.of(this);
  
  /// Log navigation event to analytics
  void _logNavigation(
    String route,
    Map<String, String> params,
    Map<String, String> queryParams,
  ) {
    try {
      if (sl.isRegistered<AnalyticsService>()) {
        final analyticsService = sl<AnalyticsService>();
        analyticsService.logScreenView(
          screenName: route,
          screenClass: route.split('/').last,
          parameters: {
            ...params,
            ...queryParams,
          },
        );
      }
    } catch (e) {
      if (sl.isRegistered<LoggerService>()) {
        final logger = sl<LoggerService>();
        logger.e('Failed to log navigation: $e');
      }
    }
  }
}

/// Extension methods for type-safe route navigation to specific pages
extension TypeSafeNavigation on BuildContext {
  /// Navigate to the dashboard
  void navigateToDashboard() {
    goNamed(AppRoutes.dashboard);
  }
  
  /// Navigate to the login page
  void navigateToLogin() {
    goNamed(AppRoutes.login);
  }
  
  /// Navigate to the lesson detail page
  void navigateToLessonDetail(String lessonId) {
    goNamed(
      AppRoutes.lessonDetail,
      params: {'lessonId': lessonId},
    );
  }
  
  /// Navigate to the video player page
  void navigateToVideoPlayer(String lessonId, String? videoUrl) {
    final queryParams = videoUrl != null ? {'videoUrl': videoUrl} : <String, String>{};
    
    goNamed(
      'video',
      params: {'lessonId': lessonId},
      queryParams: queryParams,
    );
  }
  
  /// Navigate to the quiz detail page
  void navigateToQuizDetail(String quizId) {
    goNamed(
      AppRoutes.quizDetail,
      params: {'quizId': quizId},
    );
  }
  
  /// Navigate to the quiz result page
  void navigateToQuizResult(String quizId, int score, int totalQuestions) {
    goNamed(
      AppRoutes.quizResult,
      params: {'quizId': quizId},
      queryParams: {
        'score': score.toString(),
        'totalQuestions': totalQuestions.toString(),
      },
    );
  }
  
  /// Navigate to the AI tutor chat page
  void navigateToAiTutorChat({
    String? subject,
    String? lessonId,
    String? quizId,
  }) {
    final queryParams = <String, String>{};
    
    if (subject != null) queryParams['subject'] = subject;
    if (lessonId != null) queryParams['lessonId'] = lessonId;
    if (quizId != null) queryParams['quizId'] = quizId;
    
    goNamed(
      AppRoutes.aiTutorChat,
      queryParams: queryParams,
    );
  }
  
  /// Navigate to the practice questions page
  void navigateToPracticeQuestions({
    String? subject,
    String? topic,
    String? difficulty,
  }) {
    final queryParams = <String, String>{};
    
    if (subject != null) queryParams['subject'] = subject;
    if (topic != null) queryParams['topic'] = topic;
    if (difficulty != null) queryParams['difficulty'] = difficulty;
    
    goNamed(
      AppRoutes.practiceQuestions,
      queryParams: queryParams,
    );
  }
  
  /// Navigate to the lesson list page
  void navigateToLessonList({
    String? subject,
    String? gradeLevel,
  }) {
    final queryParams = <String, String>{};
    
    if (subject != null) queryParams['subject'] = subject;
    if (gradeLevel != null) queryParams['gradeLevel'] = gradeLevel;
    
    goNamed(
      AppRoutes.lessonList,
      queryParams: queryParams,
    );
  }
  
  /// Navigate to the subscription pricing page
  void navigateToPricing() {
    goNamed(AppRoutes.pricing);
  }
  
  /// Navigate to the payment page
  void navigateToPayment(String planId) {
    goNamed(
      AppRoutes.payment,
      queryParams: {'planId': planId},
    );
  }
  
  /// Navigate to the profile page
  void navigateToProfile() {
    goNamed(AppRoutes.profile);
  }
  
  /// Navigate to the settings page
  void navigateToSettings() {
    goNamed(AppRoutes.settings);
  }
  
  /// Navigate to the business simulation page
  void navigateToBusinessSimulation() {
    goNamed(AppRoutes.businessSimulation);
  }
}

/// Extension for route parameter builders and validation
extension RouteParameterExtension on BuildContext {
  /// Get a required string parameter from the current route
  String getRequiredStringParam(String name) {
    final param = routeState.params[name];
    if (param == null) {
      throw Exception('Required parameter $name is missing');
    }
    return param;
  }
  
  /// Get an optional string parameter from the current route
  String? getOptionalStringParam(String name) {
    return routeState.params[name];
  }
  
  /// Get a required int parameter from the current route
  int getRequiredIntParam(String name) {
    final param = getRequiredStringParam(name);
    try {
      return int.parse(param);
    } catch (e) {
      throw Exception('Parameter $name is not a valid integer');
    }
  }
  
  /// Get an optional int parameter from the current route
  int? getOptionalIntParam(String name) {
    final param = getOptionalStringParam(name);
    if (param == null) return null;
    
    try {
      return int.parse(param);
    } catch (e) {
      return null;
    }
  }
  
  /// Get a required boolean parameter from the current route
  bool getRequiredBoolParam(String name) {
    final param = getRequiredStringParam(name).toLowerCase();
    return param == 'true' || param == '1' || param == 'yes';
  }
  
  /// Get an optional boolean parameter from the current route
  bool? getOptionalBoolParam(String name) {
    final param = getOptionalStringParam(name);
    if (param == null) return null;
    
    final lowerParam = param.toLowerCase();
    return lowerParam == 'true' || lowerParam == '1' || lowerParam == 'yes';
  }
  
  /// Get a required date parameter from the current route
  DateTime getRequiredDateParam(String name, {String format = 'yyyy-MM-dd'}) {
    final param = getRequiredStringParam(name);
    try {
      return DateFormat(format).parse(param);
    } catch (e) {
      throw Exception('Parameter $name is not a valid date in format $format');
    }
  }
  
  /// Get an optional date parameter from the current route
  DateTime? getOptionalDateParam(String name, {String format = 'yyyy-MM-dd'}) {
    final param = getOptionalStringParam(name);
    if (param == null) return null;
    
    try {
      return DateFormat(format).parse(param);
    } catch (e) {
      return null;
    }
  }
  
  /// Get a required query parameter from the current route
  String getRequiredQueryParam(String name) {
    final param = routeState.queryParams[name];
    if (param == null) {
      throw Exception('Required query parameter $name is missing');
    }
    return param;
  }
  
  /// Get an optional query parameter from the current route
  String? getOptionalQueryParam(String name) {
    return routeState.queryParams[name];
  }
  
  /// Build query parameters for a route
  Map<String, String> buildQueryParams({
    Map<String, String> stringParams = const {},
    Map<String, int> intParams = const {},
    Map<String, bool> boolParams = const {},
    Map<String, DateTime> dateParams = const {},
    String dateFormat = 'yyyy-MM-dd',
  }) {
    final result = <String, String>{};
    
    // Add string parameters
    result.addAll(stringParams);
    
    // Add int parameters
    intParams.forEach((key, value) {
      result[key] = value.toString();
    });
    
    // Add bool parameters
    boolParams.forEach((key, value) {
      result[key] = value.toString();
    });
    
    // Add date parameters
    dateParams.forEach((key, value) {
      result[key] = DateFormat(dateFormat).format(value);
    });
    
    return result;
  }
  
  /// Validate if all required parameters are present
  bool validateRequiredParams(List<String> paramNames) {
    for (final name in paramNames) {
      if (!routeState.params.containsKey(name) || routeState.params[name] == null) {
        return false;
      }
    }
    return true;
  }
  
  /// Validate if all required query parameters are present
  bool validateRequiredQueryParams(List<String> paramNames) {
    for (final name in paramNames) {
      if (!routeState.queryParams.containsKey(name) || routeState.queryParams[name] == null) {
        return false;
      }
    }
    return true;
  }
}

/// Extension for route transition helpers
extension RouteTransitionExtension on BuildContext {
  /// Create a custom page with fade transition
  CustomTransitionPage<T> createFadeTransitionPage<T>({
    required Widget child,
    required GoRouterState state,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: duration,
    );
  }
  
  /// Create a custom page with slide transition
  CustomTransitionPage<T> createSlideTransitionPage<T>({
    required Widget child,
    required GoRouterState state,
    Duration duration = const Duration(milliseconds: 300),
    Offset begin = const Offset(1.0, 0.0),
    Offset end = Offset.zero,
    Curve curve = Curves.easeInOut,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);
        
        return SlideTransition(position: offsetAnimation, child: child);
      },
      transitionDuration: duration,
    );
  }
  
  /// Create a custom page with scale transition
  CustomTransitionPage<T> createScaleTransitionPage<T>({
    required Widget child,
    required GoRouterState state,
    Duration duration = const Duration(milliseconds: 300),
    double begin = 0.0,
    double end = 1.0,
    Curve curve = Curves.easeInOut,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var scaleAnimation = animation.drive(tween);
        
        return ScaleTransition(scale: scaleAnimation, child: child);
      },
      transitionDuration: duration,
    );
  }
  
  /// Create a custom page with rotation transition
  CustomTransitionPage<T> createRotationTransitionPage<T>({
    required Widget child,
    required GoRouterState state,
    Duration duration = const Duration(milliseconds: 300),
    double begin = 0.0,
    double end = 1.0,
    Curve curve = Curves.easeInOut,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var rotationAnimation = animation.drive(tween);
        
        return RotationTransition(turns: rotationAnimation, child: child);
      },
      transitionDuration: duration,
    );
  }
  
  /// Create a custom page with size transition
  CustomTransitionPage<T> createSizeTransitionPage<T>({
    required Widget child,
    required GoRouterState state,
    Duration duration = const Duration(milliseconds: 300),
    Axis axis = Axis.vertical,
    Curve curve = Curves.easeInOut,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SizeTransition(
          sizeFactor: CurvedAnimation(
            parent: animation,
            curve: curve,
          ),
          axis: axis,
          child: child,
        );
      },
      transitionDuration: duration,
    );
  }
}

/// Extension for deep linking utilities
extension DeepLinkExtension on BuildContext {
  /// Build a deep link for the current app
  String buildDeepLink(
    String path, {
    Map<String, String> queryParams = const <String, String>{},
  }) {
    final uri = Uri(
      scheme: 'zimlearn',
      host: 'app',
      path: path,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    
    return uri.toString();
  }
  
  /// Build a web deep link for the current app
  String buildWebDeepLink(
    String path, {
    Map<String, String> queryParams = const <String, String>{},
    String domain = 'zimlearn.app',
  }) {
    final uri = Uri(
      scheme: 'https',
      host: domain,
      path: path,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    
    return uri.toString();
  }
  
  /// Parse a deep link and navigate to it
  void navigateToDeepLink(String deepLink) {
    try {
      final uri = Uri.parse(deepLink);
      
      // Handle app scheme
      if (uri.scheme == 'zimlearn' && uri.host == 'app') {
        go(uri.path);
        return;
      }
      
      // Handle web links
      if ((uri.scheme == 'http' || uri.scheme == 'https') && 
          (uri.host == 'zimlearn.app' || uri.host == 'www.zimlearn.app')) {
        go(uri.path);
        return;
      }
      
      // If we get here, the deep link wasn't recognized
      throw Exception('Unrecognized deep link format');
    } catch (e) {
      if (sl.isRegistered<LoggerService>()) {
        final logger = sl<LoggerService>();
        logger.e('Failed to parse deep link: $e');
      }
    }
  }
  
  /// Generate a shareable link for content
  String generateShareableLink(
    String contentType,
    String contentId, {
    Map<String, String> additionalParams = const <String, String>{},
    bool useWebLink = true,
  }) {
    final path = '/$contentType/$contentId';
    final queryParams = {
      'utm_source': 'share',
      'utm_medium': 'app',
      'utm_campaign': 'user_share',
      ...additionalParams,
    };
    
    return useWebLink
        ? buildWebDeepLink(path, queryParams: queryParams)
        : buildDeepLink(path, queryParams: queryParams);
  }
}

/// Extension for navigation analytics
extension NavigationAnalyticsExtension on BuildContext {
  /// Log a screen view to analytics
  void logScreenView(String screenName, {Map<String, dynamic>? parameters}) {
    try {
      if (sl.isRegistered<AnalyticsService>()) {
        final analyticsService = sl<AnalyticsService>();
        analyticsService.logScreenView(
          screenName: screenName,
          screenClass: screenName.split('/').last,
          parameters: parameters,
        );
      }
    } catch (e) {
      if (sl.isRegistered<LoggerService>()) {
        final logger = sl<LoggerService>();
        logger.e('Failed to log screen view: $e');
      }
    }
  }
  
  /// Log a navigation event to analytics
  void logNavigationEvent(
    String fromRoute,
    String toRoute, {
    Map<String, dynamic>? parameters,
  }) {
    try {
      if (sl.isRegistered<AnalyticsService>()) {
        final analyticsService = sl<AnalyticsService>();
        analyticsService.logEvent(
          name: 'navigation',
          parameters: {
            'from_route': fromRoute,
            'to_route': toRoute,
            'timestamp': DateTime.now().toIso8601String(),
            ...?parameters,
          },
        );
      }
    } catch (e) {
      if (sl.isRegistered<LoggerService>()) {
        final logger = sl<LoggerService>();
        logger.e('Failed to log navigation event: $e');
      }
    }
  }
  
  /// Start tracking navigation timing
  void startNavigationTiming(String routeName) {
    try {
      if (sl.isRegistered<AnalyticsService>()) {
        final analyticsService = sl<AnalyticsService>();
        analyticsService.startTrace('navigation_$routeName');
      }
    } catch (e) {
      if (sl.isRegistered<LoggerService>()) {
        final logger = sl<LoggerService>();
        logger.e('Failed to start navigation timing: $e');
      }
    }
  }
  
  /// Stop tracking navigation timing
  void stopNavigationTiming(String routeName) {
    try {
      if (sl.isRegistered<AnalyticsService>()) {
        final analyticsService = sl<AnalyticsService>();
        analyticsService.stopTrace('navigation_$routeName');
      }
    } catch (e) {
      if (sl.isRegistered<LoggerService>()) {
        final logger = sl<LoggerService>();
        logger.e('Failed to stop navigation timing: $e');
      }
    }
  }
}

/// Extension for route state management
extension RouteStateManagementExtension on BuildContext {
  /// Save the current route state
  void saveRouteState(Map<String, dynamic> state) {
    try {
      if (sl.isRegistered<StorageService>()) {
        final storageService = sl<StorageService>();
        final stateJson = jsonEncode(state);
        storageService.setString('route_state_${router.location}', stateJson);
      }
    } catch (e) {
      if (sl.isRegistered<LoggerService>()) {
        final logger = sl<LoggerService>();
        logger.e('Failed to save route state: $e');
      }
    }
  }
  
  /// Restore the route state
  Map<String, dynamic>? restoreRouteState() {
    try {
      if (sl.isRegistered<StorageService>()) {
        final storageService = sl<StorageService>();
        final stateJson = storageService.getString('route_state_${router.location}');
        
        if (stateJson != null) {
          return jsonDecode(stateJson) as Map<String, dynamic>;
        }
      }
    } catch (e) {
      if (sl.isRegistered<LoggerService>()) {
        final logger = sl<LoggerService>();
        logger.e('Failed to restore route state: $e');
      }
    }
    
    return null;
  }
  
  /// Clear the route state
  void clearRouteState() {
    try {
      if (sl.isRegistered<StorageService>()) {
        final storageService = sl<StorageService>();
        storageService.remove('route_state_${router.location}');
      }
    } catch (e) {
      if (sl.isRegistered<LoggerService>()) {
        final logger = sl<LoggerService>();
        logger.e('Failed to clear route state: $e');
      }
    }
  }
  
  /// Check if a route has saved state
  bool hasRouteState() {
    try {
      if (sl.isRegistered<StorageService>()) {
        final storageService = sl<StorageService>();
        return storageService.containsKey('route_state_${router.location}');
      }
    } catch (e) {
      if (sl.isRegistered<LoggerService>()) {
        final logger = sl<LoggerService>();
        logger.e('Failed to check route state: $e');
      }
    }
    
    return false;
  }
}

/// Extension for breadcrumb generation
extension BreadcrumbExtension on BuildContext {
  /// Generate breadcrumbs from the current route
  List<Map<String, String>> generateBreadcrumbs() {
    final path = router.location;
    final segments = path.split('/')
      ..removeWhere((segment) => segment.isEmpty);
    
    final breadcrumbs = <Map<String, String>>[];
    String currentPath = '';
    
    // Add home breadcrumb
    breadcrumbs.add({
      'label': 'Home',
      'path': '/',
    });
    
    // Add breadcrumbs for each segment
    for (int i = 0; i < segments.length; i++) {
      final segment = segments[i];
      
      // Skip segments that are IDs (parameters)
      if (segment.startsWith(':')) continue;
      
      // Build the current path
      currentPath += '/$segment';
      
      // Add breadcrumb
      breadcrumbs.add({
        'label': _formatBreadcrumbLabel(segment),
        'path': currentPath,
      });
    }
    
    return breadcrumbs;
  }
  
  /// Format a breadcrumb label from a route segment
  String _formatBreadcrumbLabel(String segment) {
    // Replace hyphens with spaces
    final withSpaces = segment.replaceAll('-', ' ');
    
    // Capitalize each word
    final words = withSpaces.split(' ');
    final capitalizedWords = words.map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1);
    });
    
    return capitalizedWords.join(' ');
  }
  
  /// Get the current page title based on the route
  String getCurrentPageTitle() {
    final path = router.location;
    final segments = path.split('/')
      ..removeWhere((segment) => segment.isEmpty);
    
    if (segments.isEmpty) {
      return 'Home';
    }
    
    final lastSegment = segments.last;
    
    // If the last segment is an ID, use the second-to-last segment
    if (lastSegment.contains(RegExp(r'[0-9a-fA-F-]+'))) {
      if (segments.length >= 2) {
        return _formatBreadcrumbLabel(segments[segments.length - 2]);
      }
    }
    
    return _formatBreadcrumbLabel(lastSegment);
  }
}

/// Extension for route validation helpers
extension RouteValidationExtension on BuildContext {
  /// Check if a route requires authentication
  bool routeRequiresAuth(String path) {
    // Get the list of public routes
    final publicRoutes = [
      AppRoutes.splash,
      AppRoutes.login,
      AppRoutes.register,
      AppRoutes.forgotPassword,
      AppRoutes.verifyEmail,
    ];
    
    // Check if the path is in the public routes list
    return !publicRoutes.any((route) => path.startsWith(route));
  }
  
  /// Check if the current user has permission to access a route
  Future<bool> hasRoutePermission(String path) async {
    try {
      // Admin routes check
      if (path.startsWith('/admin')) {
        if (sl.isRegistered<AuthService>()) {
          final authService = sl<AuthService>();
          final user = await authService.getCurrentUser();
          return user?.role == 'admin';
        }
        return false;
      }
      
      // Premium routes check
      if (_isPremiumRoute(path)) {
        if (sl.isRegistered<AuthService>()) {
          final authService = sl<AuthService>();
          final user = await authService.getCurrentUser();
          return user?.hasActiveSubscription ?? false;
        }
        return false;
      }
      
      // Default to allowing access
      return true;
    } catch (e) {
      if (sl.isRegistered<LoggerService>()) {
        final logger = sl<LoggerService>();
        logger.e('Failed to check route permission: $e');
      }
      return false;
    }
  }
  
  /// Check if a route is accessible in offline mode
  bool isRouteOfflineAccessible(String path) {
    // Define routes that are accessible offline
    final offlineRoutes = [
      AppRoutes.dashboard,
      '/lessons',
      '/quizzes',
      '/profile',
      '/settings',
    ];
    
    return offlineRoutes.any((route) => path.startsWith(route));
  }
  
  /// Check if a route is a premium route
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
  
  /// Validate a route before navigation
  Future<bool> validateRoute(String path) async {
    try {
      // Check if route requires authentication
      if (routeRequiresAuth(path)) {
        if (sl.isRegistered<AuthService>()) {
          final authService = sl<AuthService>();
          final isAuthenticated = await authService.isAuthenticated();
          
          if (!isAuthenticated) {
            return false;
          }
        } else {
          return false;
        }
      }
      
      // Check if user has permission to access the route
      final hasPermission = await hasRoutePermission(path);
      if (!hasPermission) {
        return false;
      }
      
      // All checks passed
      return true;
    } catch (e) {
      if (sl.isRegistered<LoggerService>()) {
        final logger = sl<LoggerService>();
        logger.e('Failed to validate route: $e');
      }
      return false;
    }
  }
}
