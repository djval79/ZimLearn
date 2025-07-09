import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Services
import '../services/auth_service.dart';
import '../services/service_locator.dart';
import '../services/storage_service.dart';
import '../services/analytics_service.dart';

// Models
import '../../data/models/user.dart';
import '../../data/models/subscription.dart';

// Authentication Pages
import '../../features/auth/pages/login_page.dart';
import '../../features/auth/pages/register_page.dart';
import '../../features/auth/pages/forgot_password_page.dart';
import '../../features/auth/pages/verify_email_page.dart';
import '../../features/auth/pages/biometric_setup_page.dart';

// Onboarding Pages
import '../../features/onboarding/pages/onboarding_page.dart';
import '../../features/onboarding/pages/welcome_page.dart';
import '../../features/onboarding/pages/grade_selection_page.dart';
import '../../features/onboarding/pages/subject_selection_page.dart';
import '../../features/onboarding/pages/learning_style_quiz_page.dart';

// Main App Pages
import '../../features/dashboard/pages/dashboard_page.dart';
import '../../features/splash/splash_page.dart';
import '../../features/error/error_page.dart';

// Lesson Pages
import '../../features/lessons/pages/lesson_list_page.dart';
import '../../features/lessons/pages/lesson_detail_page.dart';
import '../../features/lessons/pages/video_player_page.dart';
import '../../features/lessons/pages/interactive_content_page.dart';
import '../../features/lessons/pages/lesson_notes_page.dart';

// Quiz Pages
import '../../features/quiz/pages/quiz_list_page.dart';
import '../../features/quiz/pages/quiz_detail_page.dart';
import '../../features/quiz/pages/quiz_result_page.dart';

// AI Tutor Pages
import '../../features/ai_tutor/pages/ai_tutor_chat_page.dart';
import '../../features/ai_tutor/pages/practice_questions_page.dart';
import '../../features/ai_tutor/pages/study_plan_page.dart';

// Subscription Pages
import '../../features/subscription/pages/pricing_page.dart';
import '../../features/subscription/pages/payment_page.dart';
import '../../features/subscription/pages/subscription_details_page.dart';

// Profile and Settings Pages
import '../../features/profile/pages/profile_page.dart';
import '../../features/profile/pages/edit_profile_page.dart';
import '../../features/settings/pages/settings_page.dart';
import '../../features/settings/pages/language_settings_page.dart';
import '../../features/settings/pages/notification_settings_page.dart';
import '../../features/settings/pages/appearance_settings_page.dart';
import '../../features/settings/pages/data_usage_settings_page.dart';
import '../../features/settings/pages/parental_controls_page.dart';

// Admin Pages
import '../../features/admin/pages/admin_dashboard_page.dart';
import '../../features/admin/pages/content_management_page.dart';
import '../../features/admin/pages/user_management_page.dart';
import '../../features/admin/pages/analytics_dashboard_page.dart';

// Business Simulation Pages
import '../../features/business/pages/business_simulation_page.dart';
import '../../features/business/pages/market_simulation_page.dart';

// Blocs
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/subscription/bloc/subscription_bloc.dart';

/// Route names as constants for better maintainability
class AppRoutes {
  // Core routes
  static const String splash = '/';
  static const String error = '/error';
  
  // Auth routes
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String verifyEmail = '/verify-email';
  static const String biometricSetup = '/biometric-setup';
  
  // Onboarding routes
  static const String onboarding = '/onboarding';
  static const String welcome = '/welcome';
  static const String gradeSelection = '/grade-selection';
  static const String subjectSelection = '/subject-selection';
  static const String learningStyleQuiz = '/learning-style-quiz';
  
  // Main app routes
  static const String dashboard = '/dashboard';
  
  // Lesson routes
  static const String lessonList = '/lessons';
  static const String lessonDetail = '/lessons/:lessonId';
  static const String videoPlayer = '/lessons/:lessonId/video';
  static const String interactiveContent = '/lessons/:lessonId/interactive';
  static const String lessonNotes = '/lessons/:lessonId/notes';
  
  // Quiz routes
  static const String quizList = '/quizzes';
  static const String quizDetail = '/quizzes/:quizId';
  static const String quizResult = '/quizzes/:quizId/result';
  
  // AI Tutor routes
  static const String aiTutorChat = '/ai-tutor';
  static const String practiceQuestions = '/ai-tutor/practice';
  static const String studyPlan = '/ai-tutor/study-plan';
  
  // Subscription routes
  static const String pricing = '/subscription/pricing';
  static const String payment = '/subscription/payment';
  static const String subscriptionDetails = '/subscription/details';
  
  // Profile and Settings routes
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String settings = '/settings';
  static const String languageSettings = '/settings/language';
  static const String notificationSettings = '/settings/notifications';
  static const String appearanceSettings = '/settings/appearance';
  static const String dataUsageSettings = '/settings/data-usage';
  static const String parentalControls = '/settings/parental-controls';
  
  // Admin routes
  static const String adminDashboard = '/admin';
  static const String contentManagement = '/admin/content';
  static const String userManagement = '/admin/users';
  static const String analyticsDashboard = '/admin/analytics';
  
  // Business Simulation routes
  static const String businessSimulation = '/business';
  static const String marketSimulation = '/business/market';
}

/// Custom page transitions
CustomTransitionPage<T> buildPageWithDefaultTransition<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.easeInOut;
      
      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      var offsetAnimation = animation.drive(tween);
      
      return SlideTransition(position: offsetAnimation, child: child);
    },
  );
}

/// Fade transition for modal-like pages
CustomTransitionPage<T> buildPageWithFadeTransition<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

/// Main router class
class AppRouter {
  final AuthService _authService;
  final StorageService _storageService;
  final AnalyticsService? _analyticsService;
  
  AppRouter({
    AuthService? authService,
    StorageService? storageService,
    AnalyticsService? analyticsService,
  }) : 
    _authService = authService ?? sl<AuthService>(),
    _storageService = storageService ?? sl<StorageService>(),
    _analyticsService = analyticsService ?? (sl.isRegistered<AnalyticsService>() ? sl<AnalyticsService>() : null);
  
  late final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    
    // Route observers for analytics
    observers: _analyticsService != null ? [
      _analyticsService!.getNavigatorObserver(),
    ] : [],
    
    // Error handling for unknown routes
    errorBuilder: (context, state) => ErrorPage(
      error: state.error,
      location: state.location,
    ),
    
    // Global redirect function for auth checks
    redirect: (BuildContext context, GoRouterState state) {
      // Get the current auth state from the bloc
      final authBloc = context.read<AuthBloc>();
      final authState = authBloc.state;
      
      // Get the current path
      final path = state.location;
      
      // Check if the path is in the public routes list
      final isPublicRoute = _isPublicRoute(path);
      
      // Check if the path is in the onboarding routes list
      final isOnboardingRoute = _isOnboardingRoute(path);
      
      // Check if user is authenticated
      final isAuthenticated = authState is AuthAuthenticated;
      
      // Check if user has completed onboarding
      final hasCompletedOnboarding = _hasCompletedOnboarding();
      
      // Handle authentication redirects
      if (!isAuthenticated && !isPublicRoute) {
        // Redirect unauthenticated users to login
        return AppRoutes.login;
      }
      
      // Handle onboarding redirects
      if (isAuthenticated && !hasCompletedOnboarding && !isOnboardingRoute && path != AppRoutes.dashboard) {
        // Redirect users who haven't completed onboarding
        return AppRoutes.onboarding;
      }
      
      // Handle admin routes
      if (isAuthenticated && path.startsWith('/admin')) {
        final user = authState.user;
        if (user.role != 'admin') {
          // Redirect non-admin users away from admin routes
          return AppRoutes.dashboard;
        }
      }
      
      // Handle subscription redirects for premium features
      if (isAuthenticated && _isPremiumRoute(path)) {
        final subscriptionBloc = context.read<SubscriptionBloc>();
        final subscriptionState = subscriptionBloc.state;
        
        // Check if user has an active subscription
        final hasActiveSubscription = subscriptionState is SubscriptionActive;
        
        if (!hasActiveSubscription) {
          // Redirect users without subscription to pricing page
          return AppRoutes.pricing;
        }
      }
      
      // No redirect needed
      return null;
    },
    
    // Define all routes
    routes: [
      // Splash screen
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      
      // Error page
      GoRoute(
        path: AppRoutes.error,
        builder: (context, state) {
          final error = state.extra as Exception?;
          return ErrorPage(error: error);
        },
      ),
      
      // Auth routes
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: AppRoutes.verifyEmail,
        builder: (context, state) {
          final email = state.queryParams['email'];
          return VerifyEmailPage(email: email);
        },
      ),
      GoRoute(
        path: AppRoutes.biometricSetup,
        builder: (context, state) => const BiometricSetupPage(),
      ),
      
      // Onboarding routes
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomePage(),
      ),
      GoRoute(
        path: AppRoutes.gradeSelection,
        builder: (context, state) => const GradeSelectionPage(),
      ),
      GoRoute(
        path: AppRoutes.subjectSelection,
        builder: (context, state) => const SubjectSelectionPage(),
      ),
      GoRoute(
        path: AppRoutes.learningStyleQuiz,
        builder: (context, state) => const LearningStyleQuizPage(),
      ),
      
      // Dashboard - main app entry point
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const DashboardPage(),
      ),
      
      // Lesson routes
      GoRoute(
        path: AppRoutes.lessonList,
        builder: (context, state) {
          final subject = state.queryParams['subject'];
          final gradeLevel = state.queryParams['gradeLevel'];
          return LessonListPage(
            subject: subject,
            gradeLevel: gradeLevel,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.lessonDetail,
        pageBuilder: (context, state) {
          final lessonId = state.params['lessonId']!;
          return buildPageWithDefaultTransition(
            context: context,
            state: state,
            child: LessonDetailPage(lessonId: lessonId),
          );
        },
        routes: [
          // Nested routes for lesson content
          GoRoute(
            path: 'video',
            pageBuilder: (context, state) {
              final lessonId = state.params['lessonId']!;
              final videoUrl = state.queryParams['videoUrl'];
              return buildPageWithFadeTransition(
                context: context,
                state: state,
                child: VideoPlayerPage(
                  lessonId: lessonId,
                  videoUrl: videoUrl,
                ),
              );
            },
          ),
          GoRoute(
            path: 'interactive',
            pageBuilder: (context, state) {
              final lessonId = state.params['lessonId']!;
              final activityId = state.queryParams['activityId'];
              return buildPageWithDefaultTransition(
                context: context,
                state: state,
                child: InteractiveContentPage(
                  lessonId: lessonId,
                  activityId: activityId,
                ),
              );
            },
          ),
          GoRoute(
            path: 'notes',
            pageBuilder: (context, state) {
              final lessonId = state.params['lessonId']!;
              return buildPageWithDefaultTransition(
                context: context,
                state: state,
                child: LessonNotesPage(lessonId: lessonId),
              );
            },
          ),
        ],
      ),
      
      // Quiz routes
      GoRoute(
        path: AppRoutes.quizList,
        builder: (context, state) {
          final subject = state.queryParams['subject'];
          final gradeLevel = state.queryParams['gradeLevel'];
          return QuizListPage(
            subject: subject,
            gradeLevel: gradeLevel,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.quizDetail,
        pageBuilder: (context, state) {
          final quizId = state.params['quizId']!;
          return buildPageWithDefaultTransition(
            context: context,
            state: state,
            child: QuizDetailPage(quizId: quizId),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.quizResult,
        pageBuilder: (context, state) {
          final quizId = state.params['quizId']!;
          final score = state.queryParams['score'];
          final totalQuestions = state.queryParams['totalQuestions'];
          return buildPageWithFadeTransition(
            context: context,
            state: state,
            child: QuizResultPage(
              quizId: quizId,
              score: score != null ? int.parse(score) : null,
              totalQuestions: totalQuestions != null ? int.parse(totalQuestions) : null,
            ),
          );
        },
      ),
      
      // AI Tutor routes
      GoRoute(
        path: AppRoutes.aiTutorChat,
        builder: (context, state) {
          final subject = state.queryParams['subject'];
          final lessonId = state.queryParams['lessonId'];
          final quizId = state.queryParams['quizId'];
          return AiTutorChatPage(
            subject: subject,
            lessonId: lessonId,
            quizId: quizId,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.practiceQuestions,
        builder: (context, state) {
          final subject = state.queryParams['subject'];
          final topic = state.queryParams['topic'];
          final difficulty = state.queryParams['difficulty'];
          return PracticeQuestionsPage(
            subject: subject,
            topic: topic,
            difficulty: difficulty,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.studyPlan,
        builder: (context, state) => const StudyPlanPage(),
      ),
      
      // Subscription routes
      GoRoute(
        path: AppRoutes.pricing,
        builder: (context, state) => const PricingPage(),
      ),
      GoRoute(
        path: AppRoutes.payment,
        pageBuilder: (context, state) {
          final planId = state.queryParams['planId'];
          return buildPageWithFadeTransition(
            context: context,
            state: state,
            child: PaymentPage(planId: planId),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.subscriptionDetails,
        builder: (context, state) => const SubscriptionDetailsPage(),
      ),
      
      // Profile and Settings routes
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        pageBuilder: (context, state) {
          return buildPageWithDefaultTransition(
            context: context,
            state: state,
            child: const EditProfilePage(),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsPage(),
        routes: [
          // Nested routes for settings
          GoRoute(
            path: 'language',
            builder: (context, state) => const LanguageSettingsPage(),
          ),
          GoRoute(
            path: 'notifications',
            builder: (context, state) => const NotificationSettingsPage(),
          ),
          GoRoute(
            path: 'appearance',
            builder: (context, state) => const AppearanceSettingsPage(),
          ),
          GoRoute(
            path: 'data-usage',
            builder: (context, state) => const DataUsageSettingsPage(),
          ),
          GoRoute(
            path: 'parental-controls',
            builder: (context, state) => const ParentalControlsPage(),
          ),
        ],
      ),
      
      // Admin routes
      GoRoute(
        path: AppRoutes.adminDashboard,
        builder: (context, state) => const AdminDashboardPage(),
      ),
      GoRoute(
        path: AppRoutes.contentManagement,
        builder: (context, state) => const ContentManagementPage(),
      ),
      GoRoute(
        path: AppRoutes.userManagement,
        builder: (context, state) => const UserManagementPage(),
      ),
      GoRoute(
        path: AppRoutes.analyticsDashboard,
        builder: (context, state) => const AnalyticsDashboardPage(),
      ),
      
      // Business Simulation routes
      GoRoute(
        path: AppRoutes.businessSimulation,
        builder: (context, state) => const BusinessSimulationPage(),
      ),
      GoRoute(
        path: AppRoutes.marketSimulation,
        builder: (context, state) => const MarketSimulationPage(),
      ),
    ],
  );
  
  // Helper method to check if a route is public (accessible without auth)
  bool _isPublicRoute(String path) {
    final publicRoutes = [
      AppRoutes.splash,
      AppRoutes.login,
      AppRoutes.register,
      AppRoutes.forgotPassword,
      AppRoutes.verifyEmail,
    ];
    
    return publicRoutes.any((route) => path.startsWith(route));
  }
  
  // Helper method to check if a route is part of onboarding
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
  
  // Helper method to check if user has completed onboarding
  bool _hasCompletedOnboarding() {
    return _storageService.getBool('has_completed_onboarding') ?? false;
  }
  
  // Helper method to check if a route requires premium subscription
  bool _isPremiumRoute(String path) {
    // Define routes that require premium subscription
    final premiumRoutes = [
      // Advanced AI tutor features
      '/ai-tutor/study-plan',
      // Business simulation
      '/business',
      // Advanced quiz features
      '/quizzes/advanced',
      // Offline content download
      '/downloads',
    ];
    
    return premiumRoutes.any((route) => path.startsWith(route));
  }
}
