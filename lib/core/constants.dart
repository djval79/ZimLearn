// App Constants for ZimLearn
class AppConstants {
  // App Information
  static const String appName = 'ZimLearn';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Educational platform for Zimbabwean children';
  
  // Colors - Zimbabwean Flag Theme
  static const int primaryColorValue = 0xFF008751; // Green
  static const int secondaryColorValue = 0xFFFFD700; // Yellow/Gold
  static const int accentColorValue = 0xFFCE1126; // Red
  static const int neutralColorValue = 0xFF000000; // Black
  static const int whiteColorValue = 0xFFFFFFFF; // White
  
  // API Configuration
  static const String apiBaseUrl = 'https://api.zimlearn.dev';
  static const String graphqlEndpoint = '/graphql';
  static const Duration defaultTimeout = Duration(seconds: 30);
  
  // Storage Keys
  static const String userTokenKey = 'user_token';
  static const String userIdKey = 'user_id';
  static const String onboardingCompleteKey = 'onboarding_complete';
  static const String selectedLanguageKey = 'selected_language';
  static const String selectedGradeLevelKey = 'selected_grade_level';
  static const String offlineContentKey = 'offline_content';
  static const String userProgressKey = 'user_progress';
  
  // Hive Box Names
  static const String userBox = 'user_box';
  static const String lessonsBox = 'lessons_box';
  static const String quizzesBox = 'quizzes_box';
  static const String progressBox = 'progress_box';
  static const String downloadsBox = 'downloads_box';
  static const String settingsBox = 'settings_box';
  
  // Supported Languages
  static const Map<String, String> supportedLanguages = {
    'en': 'English',
    'sn': 'Shona',
    'nd': 'Ndebele',
  };
  
  // Grade Levels
  static const Map<String, String> gradeLevels = {
    'ecd': 'Early Childhood Development (3-5 years)',
    'primary_1_3': 'Primary Grade 1-3 (6-8 years)',
    'primary_4_7': 'Primary Grade 4-7 (9-12 years)',
    'secondary_form_1_2': 'Secondary Form 1-2 (13-14 years)',
    'secondary_form_3_4': 'Secondary Form 3-4 (15-16 years)',
  };
  
  // Subjects
  static const Map<String, String> subjects = {
    'mathematics': 'Mathematics',
    'english': 'English',
    'shona': 'Shona',
    'ndebele': 'Ndebele',
    'science': 'Science',
    'geography': 'Geography',
    'history': 'History',
    'agriculture': 'Agriculture',
    'computer_studies': 'Computer Studies',
    'technical_graphics': 'Technical Graphics',
    'art': 'Art',
    'music': 'Music',
    'physical_education': 'Physical Education',
  };
  
  // Business Types for Entrepreneurship Module
  static const Map<String, String> businessTypes = {
    'farming': 'Agriculture & Farming',
    'mining': 'Mining & Natural Resources',
    'tourism': 'Tourism & Hospitality',
    'crafts': 'Arts & Crafts',
    'retail': 'Retail & Trade',
    'technology': 'Technology & Innovation',
  };
  
  // Zimbabwe Regions
  static const Map<String, String> zimbabweRegions = {
    'harare': 'Harare',
    'bulawayo': 'Bulawayo',
    'manicaland': 'Manicaland',
    'mashonaland': 'Mashonaland',
    'masvingo': 'Masvingo',
    'matabeleland': 'Matabeleland',
    'midlands': 'Midlands',
  };
  
  // File Paths
  static const String imagesPath = 'assets/images/';
  static const String audioPath = 'assets/audio/';
  static const String videosPath = 'assets/videos/';
  static const String curriculumPath = 'assets/curriculum/';
  static const String fontsPath = 'assets/fonts/';
  
  // Image Assets
  static const String logoPath = 'logo.png';
  static const String zimbabweFlagPath = 'zimbabwe_flag.png';
  static const String defaultAvatarPath = 'default_avatar.png';
  static const String emptyStatePath = 'empty_state.png';
  static const String errorStatePath = 'error_state.png';
  static const String offlineStatePath = 'offline_state.png';
  
  // Business Simulation Assets
  static const String farmingIconPath = 'business/farming.png';
  static const String miningIconPath = 'business/mining.png';
  static const String tourismIconPath = 'business/tourism.png';
  static const String craftsIconPath = 'business/crafts.png';
  
  // Subject Icons
  static const String mathIconPath = 'subjects/math.png';
  static const String englishIconPath = 'subjects/english.png';
  static const String shonaIconPath = 'subjects/shona.png';
  static const String scienceIconPath = 'subjects/science.png';
  static const String geographyIconPath = 'subjects/geography.png';
  static const String historyIconPath = 'subjects/history.png';
  
  // Audio Assets
  static const String welcomeSoundPath = 'welcome.mp3';
  static const String successSoundPath = 'success.mp3';
  static const String errorSoundPath = 'error.mp3';
  static const String clickSoundPath = 'click.mp3';
  
  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 500);
  static const Duration longAnimationDuration = Duration(milliseconds: 1000);
  
  // Offline Settings
  static const int maxOfflineContentSizeMB = 500;
  static const int syncRetryAttempts = 3;
  static const Duration syncInterval = Duration(minutes: 15);
  
  // Payment Settings
  static const Map<String, String> subscriptionTiers = {
    'basic': 'Basic (Free)',
    'standard': 'Standard',
    'premium': 'Premium',
    'family': 'Family Plan',
  };
  
  // Error Messages
  static const String networkErrorMessage = 'Please check your internet connection and try again.';
  static const String genericErrorMessage = 'Something went wrong. Please try again.';
  static const String offlineMessage = 'You are currently offline. Some features may be limited.';
  static const String contentNotAvailableMessage = 'This content is not available offline.';
  
  // Success Messages
  static const String loginSuccessMessage = 'Welcome back!';
  static const String signupSuccessMessage = 'Account created successfully!';
  static const String progressSavedMessage = 'Progress saved!';
  static const String offlineContentDownloadedMessage = 'Content downloaded for offline use.';
  
  // Validation
  static const int minPasswordLength = 6;
  static const int maxUsernameLength = 20;
  static const int minUsernameLength = 3;
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // Achievement Thresholds
  static const int firstQuizCompletionPoints = 10;
  static const int weeklyStreakPoints = 50;
  static const int monthlyStreakPoints = 200;
  static const int perfectScorePoints = 100;
  static const int businessSimulationCompletionPoints = 500;
  
  // Educational Metrics
  static const double passingGrade = 0.6; // 60%
  static const double excellentGrade = 0.8; // 80%
  static const int maxQuizAttempts = 3;
  static const Duration lessonTimeThreshold = Duration(minutes: 5);
  
  // Social Features
  static const int maxMessageLength = 500;
  static const int maxUsernameDisplayLength = 15;
  
  // File Size Limits
  static const int maxImageSizeKB = 2048; // 2MB
  static const int maxVideoSizeMB = 50; // 50MB
  static const int maxAudioSizeMB = 10; // 10MB
  
  // Device Support
  static const double minSupportedVersion = 21.0; // Android API 21
  static const String minIOSVersion = '12.0';
  
  // Feature Flags
  static const bool enableDebugMode = false;
  static const bool enableAnalytics = true;
  static const bool enableCrashReporting = true;
  static const bool enableOfflineMode = true;
  static const bool enableAITutor = true;
  static const bool enableGameification = true;
  
  // External Links
  static const String supportEmail = 'support@zimlearn.org';
  static const String websiteUrl = 'https://zimlearn.org';
  static const String privacyPolicyUrl = 'https://zimlearn.org/privacy';
  static const String termsOfServiceUrl = 'https://zimlearn.org/terms';
  static const String helpCenterUrl = 'https://help.zimlearn.org';
  
  // Social Media
  static const String twitterUrl = 'https://twitter.com/ZimLearnApp';
  static const String facebookUrl = 'https://facebook.com/ZimLearnApp';
  static const String instagramUrl = 'https://instagram.com/ZimLearnApp';
  
  // Regional Settings
  static const String defaultCurrency = 'USD';
  static const String localCurrency = 'ZWL';
  static const String timeZone = 'Africa/Harare';
  static const String countryCode = 'ZW';
  
  // Contact Information
  static const String emergencyHelpline = '+263-4-123456';
  static const String technicalSupportNumber = '+263-4-789012';
}

// Environment-specific constants
class Environment {
  static const String development = 'development';
  static const String staging = 'staging';
  static const String production = 'production';
  
  static const String current = String.fromEnvironment('ENVIRONMENT', defaultValue: development);
  
  static bool get isDevelopment => current == development;
  static bool get isStaging => current == staging;
  static bool get isProduction => current == production;
}

// API Endpoints
class ApiEndpoints {
  static const String auth = '/auth';
  static const String user = '/user';
  static const String curriculum = '/curriculum';
  static const String lessons = '/lessons';
  static const String quizzes = '/quizzes';
  static const String progress = '/progress';
  static const String downloads = '/downloads';
  static const String sync = '/sync';
  static const String ai = '/ai';
  static const String entrepreneurship = '/entrepreneurship';
  static const String analytics = '/analytics';
  static const String payments = '/payments';
  static const String notifications = '/notifications';
}
