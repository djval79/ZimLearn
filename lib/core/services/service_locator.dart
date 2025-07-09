import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'storage_service.dart';
import 'auth_service.dart';
import '../constants.dart';

/// ServiceLocator provides centralized dependency injection for the ZimLearn app.
/// It registers and initializes all services and provides them throughout the app.
class ServiceLocator {
  // Singleton instance of GetIt
  static final GetIt instance = GetIt.instance;
  
  // Logger for debugging
  static final Logger _logger = Logger();
  
  // Flag to prevent multiple initializations
  static bool _isInitialized = false;
  
  /// Initializes all services in the correct order.
  /// Must be called before accessing any services.
  static Future<void> init() async {
    if (_isInitialized) {
      _logger.w('ServiceLocator already initialized');
      return;
    }
    
    try {
      _logger.i('Initializing ServiceLocator...');
      
      // Register core utilities
      instance.registerSingleton<Logger>(Logger());
      instance.registerSingleton<Connectivity>(Connectivity());
      
      // Register services
      _registerServices();
      
      // Initialize services in order
      await _initializeServices();
      
      _isInitialized = true;
      _logger.i('ServiceLocator initialized successfully');
    } catch (e, stackTrace) {
      _logger.e('Error initializing ServiceLocator', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  /// Registers all services as singletons.
  static void _registerServices() {
    // Core services
    instance.registerSingleton<StorageService>(StorageService());
    instance.registerSingleton<AuthService>(AuthService());
    
    // Network service - will be implemented later
    // instance.registerSingleton<NetworkService>(NetworkService());
    
    // Analytics service - will be implemented later
    // instance.registerSingleton<AnalyticsService>(AnalyticsService());
    
    // Download service - will be implemented later
    // instance.registerSingleton<DownloadService>(DownloadService());
    
    // Notification service - will be implemented later
    // instance.registerSingleton<NotificationService>(NotificationService());
    
    // Localization service - will be implemented later
    // instance.registerSingleton<LocalizationService>(LocalizationService());
    
    // AI Tutor service - will be implemented later
    // instance.registerSingleton<AITutorService>(AITutorService());
    
    // Business Simulation service - will be implemented later
    // instance.registerSingleton<BusinessSimulationService>(BusinessSimulationService());
    
    _logger.i('Services registered successfully');
  }
  
  /// Initializes all services in the correct order.
  static Future<void> _initializeServices() async {
    _logger.i('Initializing services...');
    
    // Initialize storage service first as other services depend on it
    await instance<StorageService>().initialize();
    
    // Initialize auth service after storage
    await instance<AuthService>().initialize();
    
    // Initialize other services
    // await instance<NetworkService>().initialize();
    // await instance<AnalyticsService>().initialize();
    // await instance<DownloadService>().initialize();
    // await instance<NotificationService>().initialize();
    // await instance<LocalizationService>().initialize();
    // await instance<AITutorService>().initialize();
    // await instance<BusinessSimulationService>().initialize();
    
    _logger.i('All services initialized successfully');
  }
  
  /// Resets all services (useful for testing or user logout).
  static Future<void> reset() async {
    if (!_isInitialized) return;
    
    try {
      _logger.i('Resetting ServiceLocator...');
      
      // Dispose services in reverse order
      // await instance<BusinessSimulationService>().dispose();
      // await instance<AITutorService>().dispose();
      // await instance<LocalizationService>().dispose();
      // await instance<NotificationService>().dispose();
      // await instance<DownloadService>().dispose();
      // await instance<AnalyticsService>().dispose();
      // await instance<NetworkService>().dispose();
      await instance<AuthService>().dispose();
      await instance<StorageService>().dispose();
      
      // Reset GetIt
      instance.reset();
      
      _isInitialized = false;
      _logger.i('ServiceLocator reset successfully');
    } catch (e, stackTrace) {
      _logger.e('Error resetting ServiceLocator', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  /// Checks if a specific service is registered.
  static bool isRegistered<T extends Object>() {
    return instance.isRegistered<T>();
  }
  
  /// Gets the initialization status.
  static bool get isInitialized => _isInitialized;
  
  /// Gets the app environment (development, staging, production).
  static String get environment => Environment.current;
  
  /// Checks if the app is running in development mode.
  static bool get isDevelopment => Environment.isDevelopment;
  
  /// Checks if the app is running in production mode.
  static bool get isProduction => Environment.isProduction;
}

/// Shorthand for accessing services through the service locator.
/// Example: sl<AuthService>() instead of ServiceLocator.instance<AuthService>()
T sl<T extends Object>() => ServiceLocator.instance<T>();
