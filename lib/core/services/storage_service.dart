import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import '../constants.dart';
import '../../data/models/user.dart';
import '../../data/models/lesson.dart';
import '../../data/models/quiz.dart';

/// A service that handles all local storage operations using Hive.
/// Provides methods for storing and retrieving data, managing offline content,
/// and synchronizing with remote servers.
class StorageService {
  static const String _encryptionKeyKey = 'hive_encryption_key';
  
  final Logger _logger = Logger();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final Connectivity _connectivity = Connectivity();
  final Uuid _uuid = const Uuid();
  
  // Hive boxes
  late Box<User> _userBox;
  late Box<Lesson> _lessonsBox;
  late Box<Quiz> _quizzesBox;
  late Box<QuizAttempt> _quizAttemptsBox;
  late Box<Map<dynamic, dynamic>> _progressBox;
  late Box<Map<dynamic, dynamic>> _settingsBox;
  late Box<Map<dynamic, dynamic>> _offlineContentBox;
  late Box<Map<dynamic, dynamic>> _syncQueueBox;
  
  // Stream controllers for data changes
  final _userStreamController = StreamController<User?>.broadcast();
  final _lessonsStreamController = StreamController<List<Lesson>>.broadcast();
  final _quizzesStreamController = StreamController<List<Quiz>>.broadcast();
  final _progressStreamController = StreamController<Map<String, dynamic>>.broadcast();
  final _settingsStreamController = StreamController<Map<String, dynamic>>.broadcast();
  
  // Getters for streams
  Stream<User?> get userStream => _userStreamController.stream;
  Stream<List<Lesson>> get lessonsStream => _lessonsStreamController.stream;
  Stream<List<Quiz>> get quizzesStream => _quizzesStreamController.stream;
  Stream<Map<String, dynamic>> get progressStream => _progressStreamController.stream;
  Stream<Map<String, dynamic>> get settingsStream => _settingsStreamController.stream;
  
  // Singleton instance
  static final StorageService _instance = StorageService._internal();
  
  factory StorageService() => _instance;
  
  StorageService._internal();
  
  /// Initializes the storage service and opens all Hive boxes.
  /// Must be called before using any other methods.
  Future<void> initialize() async {
    try {
      _logger.i('Initializing StorageService...');
      
      // Initialize Hive
      await Hive.initFlutter();
      
      // Register adapters if not already registered
      _registerAdapters();
      
      // Get encryption key from secure storage or generate a new one
      final encryptionKey = await _getEncryptionKey();
      
      // Open boxes with encryption for sensitive data
      _userBox = await Hive.openBox<User>(
        AppConstants.userBox,
        encryptionCipher: HiveAesCipher(encryptionKey),
      );
      
      // Open other boxes
      _lessonsBox = await Hive.openBox<Lesson>(AppConstants.lessonsBox);
      _quizzesBox = await Hive.openBox<Quiz>(AppConstants.quizzesBox);
      _quizAttemptsBox = await Hive.openBox<QuizAttempt>('quiz_attempts_box');
      _progressBox = await Hive.openBox<Map<dynamic, dynamic>>(AppConstants.progressBox);
      _settingsBox = await Hive.openBox<Map<dynamic, dynamic>>(AppConstants.settingsBox);
      _offlineContentBox = await Hive.openBox<Map<dynamic, dynamic>>(AppConstants.downloadsBox);
      _syncQueueBox = await Hive.openBox<Map<dynamic, dynamic>>('sync_queue_box');
      
      // Set up box listeners to update streams
      _setupBoxListeners();
      
      // Initial stream values
      _emitCurrentValues();
      
      _logger.i('StorageService initialized successfully');
    } catch (e, stackTrace) {
      _logger.e('Error initializing StorageService', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  /// Registers all Hive adapters if they haven't been registered yet.
  void _registerAdapters() {
    try {
      // Check if adapters are already registered to avoid errors
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(UserAdapter());
        Hive.registerAdapter(UserSubscriptionAdapter());
        Hive.registerAdapter(UserPreferencesAdapter());
        
        Hive.registerAdapter(LessonAdapter());
        Hive.registerAdapter(LessonTypeAdapter());
        Hive.registerAdapter(LessonContentAdapter());
        Hive.registerAdapter(ContentTypeAdapter());
        
        Hive.registerAdapter(QuizAdapter());
        Hive.registerAdapter(QuizTypeAdapter());
        Hive.registerAdapter(QuizQuestionAdapter());
        Hive.registerAdapter(QuestionTypeAdapter());
        Hive.registerAdapter(QuizOptionAdapter());
        Hive.registerAdapter(QuizAttemptAdapter());
        Hive.registerAdapter(QuizAnswerAdapter());
      }
    } catch (e, stackTrace) {
      _logger.e('Error registering Hive adapters', error: e, stackTrace: stackTrace);
    }
  }
  
  /// Gets the encryption key from secure storage or generates a new one.
  Future<List<int>> _getEncryptionKey() async {
    try {
      // Try to get existing key
      final existingKey = await _secureStorage.read(key: _encryptionKeyKey);
      
      if (existingKey != null) {
        return base64Url.decode(existingKey);
      }
      
      // Generate a new key if none exists
      final key = Hive.generateSecureKey();
      await _secureStorage.write(
        key: _encryptionKeyKey,
        value: base64Url.encode(key),
      );
      
      return key;
    } catch (e, stackTrace) {
      _logger.e('Error getting encryption key', error: e, stackTrace: stackTrace);
      // Fallback to a default key in case of error (not secure but prevents crashes)
      return List.generate(32, (index) => index);
    }
  }
  
  /// Sets up listeners for box changes to update streams.
  void _setupBoxListeners() {
    // User box listener
    _userBox.listenable().addListener(() {
      _userStreamController.add(getCurrentUser());
    });
    
    // Lessons box listener
    _lessonsBox.listenable().addListener(() {
      _lessonsStreamController.add(getAllLessons());
    });
    
    // Quizzes box listener
    _quizzesBox.listenable().addListener(() {
      _quizzesStreamController.add(getAllQuizzes());
    });
    
    // Progress box listener
    _progressBox.listenable().addListener(() {
      _progressStreamController.add(getUserProgress());
    });
    
    // Settings box listener
    _settingsBox.listenable().addListener(() {
      _settingsStreamController.add(getSettings());
    });
  }
  
  /// Emits current values to all streams.
  void _emitCurrentValues() {
    _userStreamController.add(getCurrentUser());
    _lessonsStreamController.add(getAllLessons());
    _quizzesStreamController.add(getAllQuizzes());
    _progressStreamController.add(getUserProgress());
    _settingsStreamController.add(getSettings());
  }
  
  /// Closes all streams and boxes.
  Future<void> dispose() async {
    await _userStreamController.close();
    await _lessonsStreamController.close();
    await _quizzesStreamController.close();
    await _progressStreamController.close();
    await _settingsStreamController.close();
    
    await Hive.close();
  }
  
  // User related methods
  
  /// Saves the current user to storage.
  Future<void> saveUser(User user) async {
    try {
      await _userBox.put(AppConstants.userIdKey, user);
      _logger.i('User saved: ${user.id}');
    } catch (e, stackTrace) {
      _logger.e('Error saving user', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  /// Gets the current user from storage.
  User? getCurrentUser() {
    try {
      return _userBox.get(AppConstants.userIdKey);
    } catch (e, stackTrace) {
      _logger.e('Error getting current user', error: e, stackTrace: stackTrace);
      return null;
    }
  }
  
  /// Clears the current user from storage (logout).
  Future<void> clearUser() async {
    try {
      await _userBox.delete(AppConstants.userIdKey);
      _logger.i('User cleared from storage');
    } catch (e, stackTrace) {
      _logger.e('Error clearing user', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  /// Updates user preferences.
  Future<void> updateUserPreferences(UserPreferences preferences) async {
    try {
      final user = getCurrentUser();
      if (user != null) {
        final updatedUser = user.copyWith(
          preferences: preferences,
          updatedAt: DateTime.now(),
        );
        await saveUser(updatedUser);
        _logger.i('User preferences updated');
      } else {
        throw Exception('No user found to update preferences');
      }
    } catch (e, stackTrace) {
      _logger.e('Error updating user preferences', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  /// Updates user subscription.
  Future<void> updateUserSubscription(UserSubscription subscription) async {
    try {
      final user = getCurrentUser();
      if (user != null) {
        final updatedUser = user.copyWith(
          subscription: subscription,
          updatedAt: DateTime.now(),
        );
        await saveUser(updatedUser);
        _logger.i('User subscription updated');
      } else {
        throw Exception('No user found to update subscription');
      }
    } catch (e, stackTrace) {
      _logger.e('Error updating user subscription', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  // Lesson related methods
  
  /// Saves a lesson to storage.
  Future<void> saveLesson(Lesson lesson) async {
    try {
      await _lessonsBox.put(lesson.id, lesson);
      _logger.i('Lesson saved: ${lesson.id}');
    } catch (e, stackTrace) {
      _logger.e('Error saving lesson', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  /// Saves multiple lessons to storage.
  Future<void> saveLessons(List<Lesson> lessons) async {
    try {
      final Map<String, Lesson> lessonsMap = {
        for (var lesson in lessons) lesson.id: lesson
      };
      await _lessonsBox.putAll(lessonsMap);
      _logger.i('${lessons.length} lessons saved');
    } catch (e, stackTrace) {
      _logger.e('Error saving multiple lessons', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  /// Gets a lesson by ID.
  Lesson? getLesson(String id) {
    try {
      return _lessonsBox.get(id);
    } catch (e, stackTrace) {
      _logger.e('Error getting lesson', error: e, stackTrace: stackTrace);
      return null;
    }
  }
  
  /// Gets all lessons.
  List<Lesson> getAllLessons() {
    try {
      return _lessonsBox.values.toList();
    } catch (e, stackTrace) {
      _logger.e('Error getting all lessons', error: e, stackTrace: stackTrace);
      return [];
    }
  }
  
  /// Gets lessons by subject.
  List<Lesson> getLessonsBySubject(String subjectId) {
    try {
      return _lessonsBox.values
          .where((lesson) => lesson.subjectId == subjectId)
          .toList();
    } catch (e, stackTrace) {
      _logger.e('Error getting lessons by subject', error: e, stackTrace: stackTrace);
      return [];
    }
  }
  
  /// Gets lessons by grade level.
  List<Lesson> getLessonsByGradeLevel(String gradeLevel) {
    try {
      return _lessonsBox.values
          .where((lesson) => lesson.gradeLevel == gradeLevel)
          .toList();
    } catch (e, stackTrace) {
      _logger.e('Error getting lessons by grade level', error: e, stackTrace: stackTrace);
      return [];
    }
  }
  
  /// Deletes a lesson by ID.
  Future<void> deleteLesson(String id) async {
    try {
      await _lessonsBox.delete(id);
      _logger.i('Lesson deleted: $id');
    } catch (e, stackTrace) {
      _logger.e('Error deleting lesson', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  // Quiz related methods
  
  /// Saves a quiz to storage.
  Future<void> saveQuiz(Quiz quiz) async {
    try {
      await _quizzesBox.put(quiz.id, quiz);
      _logger.i('Quiz saved: ${quiz.id}');
    } catch (e, stackTrace) {
      _logger.e('Error saving quiz', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  /// Saves multiple quizzes to storage.
  Future<void> saveQuizzes(List<Quiz> quizzes) async {
    try {
      final Map<String, Quiz> quizzesMap = {
        for (var quiz in quizzes) quiz.id: quiz
      };
      await _quizzesBox.putAll(quizzesMap);
      _logger.i('${quizzes.length} quizzes saved');
    } catch (e, stackTrace) {
      _logger.e('Error saving multiple quizzes', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  /// Gets a quiz by ID.
  Quiz? getQuiz(String id) {
    try {
      return _quizzesBox.get(id);
    } catch (e, stackTrace) {
      _logger.e('Error getting quiz', error: e, stackTrace: stackTrace);
      return null;
    }
  }
  
  /// Gets all quizzes.
  List<Quiz> getAllQuizzes() {
    try {
      return _quizzesBox.values.toList();
    } catch (e, stackTrace) {
      _logger.e('Error getting all quizzes', error: e, stackTrace: stackTrace);
      return [];
    }
  }
  
  /// Gets quizzes by subject.
  List<Quiz> getQuizzesBySubject(String subjectId) {
    try {
      return _quizzesBox.values
          .where((quiz) => quiz.subjectId == subjectId)
          .toList();
    } catch (e, stackTrace) {
      _logger.e('Error getting quizzes by subject', error: e, stackTrace: stackTrace);
      return [];
    }
  }
  
  /// Saves a quiz attempt.
  Future<void> saveQuizAttempt(QuizAttempt attempt) async {
    try {
      await _quizAttemptsBox.put(attempt.id, attempt);
      
      // Update progress
      await _updateQuizProgress(attempt);
      
      _logger.i('Quiz attempt saved: ${attempt.id}');
    } catch (e, stackTrace) {
      _logger.e('Error saving quiz attempt', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  /// Gets quiz attempts by user.
  List<QuizAttempt> getQuizAttemptsByUser(String userId) {
    try {
      return _quizAttemptsBox.values
          .where((attempt) => attempt.userId == userId)
          .toList();
    } catch (e, stackTrace) {
      _logger.e('Error getting quiz attempts by user', error: e, stackTrace: stackTrace);
      return [];
    }
  }
  
  /// Gets quiz attempts by quiz.
  List<QuizAttempt> getQuizAttemptsByQuiz(String quizId) {
    try {
      return _quizAttemptsBox.values
          .where((attempt) => attempt.quizId == quizId)
          .toList();
    } catch (e, stackTrace) {
      _logger.e('Error getting quiz attempts by quiz', error: e, stackTrace: stackTrace);
      return [];
    }
  }
  
  /// Updates quiz progress in the progress box.
  Future<void> _updateQuizProgress(QuizAttempt attempt) async {
    try {
      final user = getCurrentUser();
      if (user == null) return;
      
      final String progressKey = 'quiz_${attempt.quizId}';
      final Map<dynamic, dynamic> progress = _progressBox.get(progressKey) ?? {};
      
      // Update progress data
      progress['userId'] = user.id;
      progress['quizId'] = attempt.quizId;
      progress['lastAttemptId'] = attempt.id;
      progress['bestScore'] = max(progress['bestScore'] ?? 0, attempt.score);
      progress['attempts'] = (progress['attempts'] ?? 0) + 1;
      progress['lastAttemptDate'] = attempt.completedAt.toIso8601String();
      progress['isPassed'] = attempt.isPassed;
      
      await _progressBox.put(progressKey, progress);
      
      // Add to sync queue if online
      if (await isOnline()) {
        await _addToSyncQueue('quiz_progress', progress);
      }
    } catch (e, stackTrace) {
      _logger.e('Error updating quiz progress', error: e, stackTrace: stackTrace);
    }
  }
  
  // Progress related methods
  
  /// Gets user progress for all content.
  Map<String, dynamic> getUserProgress() {
    try {
      final user = getCurrentUser();
      if (user == null) return {};
      
      final Map<String, dynamic> result = {};
      
      // Collect all progress entries
      for (var key in _progressBox.keys) {
        final progress = _progressBox.get(key);
        if (progress != null && progress['userId'] == user.id) {
          result[key.toString()] = Map<String, dynamic>.from(progress);
        }
      }
      
      return result;
    } catch (e, stackTrace) {
      _logger.e('Error getting user progress', error: e, stackTrace: stackTrace);
      return {};
    }
  }
  
  /// Updates lesson progress.
  Future<void> updateLessonProgress(String lessonId, double progress) async {
    try {
      final user = getCurrentUser();
      if (user == null) return;
      
      final String progressKey = 'lesson_$lessonId';
      final Map<dynamic, dynamic> progressData = _progressBox.get(progressKey) ?? {};
      
      // Update progress data
      progressData['userId'] = user.id;
      progressData['lessonId'] = lessonId;
      progressData['progress'] = progress;
      progressData['lastAccessDate'] = DateTime.now().toIso8601String();
      progressData['isCompleted'] = progress >= 1.0;
      
      await _progressBox.put(progressKey, progressData);
      
      // Add to sync queue if online
      if (await isOnline()) {
        await _addToSyncQueue('lesson_progress', progressData);
      }
      
      _logger.i('Lesson progress updated: $lessonId, progress: $progress');
    } catch (e, stackTrace) {
      _logger.e('Error updating lesson progress', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  /// Gets progress for a specific lesson.
  double getLessonProgress(String lessonId) {
    try {
      final user = getCurrentUser();
      if (user == null) return 0.0;
      
      final String progressKey = 'lesson_$lessonId';
      final progressData = _progressBox.get(progressKey);
      
      if (progressData != null && progressData['userId'] == user.id) {
        return (progressData['progress'] as num?)?.toDouble() ?? 0.0;
      }
      
      return 0.0;
    } catch (e, stackTrace) {
      _logger.e('Error getting lesson progress', error: e, stackTrace: stackTrace);
      return 0.0;
    }
  }
  
  /// Gets all completed lessons for the current user.
  List<String> getCompletedLessonIds() {
    try {
      final user = getCurrentUser();
      if (user == null) return [];
      
      final List<String> completedLessonIds = [];
      
      for (var key in _progressBox.keys) {
        if (key.toString().startsWith('lesson_')) {
          final progress = _progressBox.get(key);
          if (progress != null && 
              progress['userId'] == user.id && 
              progress['isCompleted'] == true) {
            final lessonId = key.toString().replaceFirst('lesson_', '');
            completedLessonIds.add(lessonId);
          }
        }
      }
      
      return completedLessonIds;
    } catch (e, stackTrace) {
      _logger.e('Error getting completed lesson IDs', error: e, stackTrace: stackTrace);
      return [];
    }
  }
  
  // Settings related methods
  
  /// Gets all settings.
  Map<String, dynamic> getSettings() {
    try {
      final Map<String, dynamic> settings = {};
      
      for (var key in _settingsBox.keys) {
        final setting = _settingsBox.get(key);
        if (setting != null) {
          settings[key.toString()] = setting;
        }
      }
      
      return settings;
    } catch (e, stackTrace) {
      _logger.e('Error getting settings', error: e, stackTrace: stackTrace);
      return {};
    }
  }
  
  /// Gets a specific setting.
  dynamic getSetting(String key, [dynamic defaultValue]) {
    try {
      final setting = _settingsBox.get(key);
      return setting ?? defaultValue;
    } catch (e, stackTrace) {
      _logger.e('Error getting setting: $key', error: e, stackTrace: stackTrace);
      return defaultValue;
    }
  }
  
  /// Saves a setting.
  Future<void> saveSetting(String key, dynamic value) async {
    try {
      await _settingsBox.put(key, value);
      _logger.i('Setting saved: $key');
    } catch (e, stackTrace) {
      _logger.e('Error saving setting: $key', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  // Offline content management
  
  /// Marks content as available offline.
  Future<void> markContentAsOffline(String contentId, String contentType, Map<String, dynamic> metadata) async {
    try {
      final String key = '${contentType}_$contentId';
      
      final Map<dynamic, dynamic> offlineData = {
        'id': contentId,
        'type': contentType,
        'downloadDate': DateTime.now().toIso8601String(),
        'metadata': metadata,
      };
      
      await _offlineContentBox.put(key, offlineData);
      _logger.i('Content marked as offline: $key');
    } catch (e, stackTrace) {
      _logger.e('Error marking content as offline', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  /// Checks if content is available offline.
  bool isContentAvailableOffline(String contentId, String contentType) {
    try {
      final String key = '${contentType}_$contentId';
      return _offlineContentBox.containsKey(key);
    } catch (e, stackTrace) {
      _logger.e('Error checking if content is available offline', error: e, stackTrace: stackTrace);
      return false;
    }
  }
  
  /// Gets all offline content.
  List<Map<String, dynamic>> getAllOfflineContent() {
    try {
      return _offlineContentBox.values
          .map((data) => Map<String, dynamic>.from(data))
          .toList();
    } catch (e, stackTrace) {
      _logger.e('Error getting all offline content', error: e, stackTrace: stackTrace);
      return [];
    }
  }
  
  /// Removes content from offline storage.
  Future<void> removeOfflineContent(String contentId, String contentType) async {
    try {
      final String key = '${contentType}_$contentId';
      await _offlineContentBox.delete(key);
      _logger.i('Content removed from offline storage: $key');
    } catch (e, stackTrace) {
      _logger.e('Error removing offline content', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  /// Calculates the total size of offline content.
  Future<int> calculateOfflineContentSize() async {
    try {
      int totalSize = 0;
      
      // Get app directory
      final appDir = await getApplicationDocumentsDirectory();
      final hivePath = appDir.path;
      
      // Check size of Hive boxes
      final lessonsFile = File('$hivePath/${AppConstants.lessonsBox}.hive');
      final quizzesFile = File('$hivePath/${AppConstants.quizzesBox}.hive');
      
      if (await lessonsFile.exists()) {
        totalSize += await lessonsFile.length();
      }
      
      if (await quizzesFile.exists()) {
        totalSize += await quizzesFile.length();
      }
      
      // Add size from downloaded files (if tracked in metadata)
      for (var content in getAllOfflineContent()) {
        final metadata = content['metadata'];
        if (metadata != null && metadata['fileSize'] != null) {
          totalSize += (metadata['fileSize'] as num).toInt();
        }
      }
      
      return totalSize;
    } catch (e, stackTrace) {
      _logger.e('Error calculating offline content size', error: e, stackTrace: stackTrace);
      return 0;
    }
  }
  
  // Synchronization methods
  
  /// Adds an item to the sync queue.
  Future<void> _addToSyncQueue(String type, Map<dynamic, dynamic> data) async {
    try {
      final String id = _uuid.v4();
      final Map<dynamic, dynamic> syncItem = {
        'id': id,
        'type': type,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
        'attempts': 0,
      };
      
      await _syncQueueBox.put(id, syncItem);
      _logger.i('Item added to sync queue: $id, type: $type');
    } catch (e, stackTrace) {
      _logger.e('Error adding item to sync queue', error: e, stackTrace: stackTrace);
    }
  }
  
  /// Gets all items in the sync queue.
  List<Map<String, dynamic>> getSyncQueue() {
    try {
      return _syncQueueBox.values
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } catch (e, stackTrace) {
      _logger.e('Error getting sync queue', error: e, stackTrace: stackTrace);
      return [];
    }
  }
  
  /// Removes an item from the sync queue.
  Future<void> removeSyncItem(String id) async {
    try {
      await _syncQueueBox.delete(id);
      _logger.i('Item removed from sync queue: $id');
    } catch (e, stackTrace) {
      _logger.e('Error removing item from sync queue', error: e, stackTrace: stackTrace);
    }
  }
  
  /// Checks if the device is online.
  Future<bool> isOnline() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }
  
  // Utility methods
  
  /// Clears all data from storage (use with caution).
  Future<void> clearAllData() async {
    try {
      await _userBox.clear();
      await _lessonsBox.clear();
      await _quizzesBox.clear();
      await _quizAttemptsBox.clear();
      await _progressBox.clear();
      await _settingsBox.clear();
      await _offlineContentBox.clear();
      await _syncQueueBox.clear();
      
      _logger.w('All data cleared from storage');
    } catch (e, stackTrace) {
      _logger.e('Error clearing all data', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  /// Gets the total number of items in storage.
  int getTotalItemCount() {
    try {
      return _userBox.length +
          _lessonsBox.length +
          _quizzesBox.length +
          _quizAttemptsBox.length +
          _progressBox.length +
          _settingsBox.length +
          _offlineContentBox.length +
          _syncQueueBox.length;
    } catch (e, stackTrace) {
      _logger.e('Error getting total item count', error: e, stackTrace: stackTrace);
      return 0;
    }
  }
  
  /// Compacts the database to save space.
  Future<void> compactDatabase() async {
    try {
      await _userBox.compact();
      await _lessonsBox.compact();
      await _quizzesBox.compact();
      await _quizAttemptsBox.compact();
      await _progressBox.compact();
      await _settingsBox.compact();
      await _offlineContentBox.compact();
      await _syncQueueBox.compact();
      
      _logger.i('Database compacted');
    } catch (e, stackTrace) {
      _logger.e('Error compacting database', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}

/// Helper function to get the maximum of two values
T max<T extends num>(T a, T b) => a > b ? a : b;
