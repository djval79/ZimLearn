import 'dart:async';
import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/service_locator.dart';
import '../../../data/models/lesson.dart';

// Events
abstract class LessonEvent extends Equatable {
  const LessonEvent();

  @override
  List<Object?> get props => [];
}

class LoadLessons extends LessonEvent {
  final String? subjectId;
  final String? gradeLevel;
  final bool forceRefresh;

  const LoadLessons({
    this.subjectId,
    this.gradeLevel,
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [subjectId, gradeLevel, forceRefresh];
}

class LoadLessonDetail extends LessonEvent {
  final String lessonId;

  const LoadLessonDetail({required this.lessonId});

  @override
  List<Object?> get props => [lessonId];
}

class UpdateLessonProgress extends LessonEvent {
  final String lessonId;
  final double progress;

  const UpdateLessonProgress({
    required this.lessonId,
    required this.progress,
  });

  @override
  List<Object?> get props => [lessonId, progress];
}

class ToggleLessonBookmark extends LessonEvent {
  final String lessonId;
  final bool isBookmarked;

  const ToggleLessonBookmark({
    required this.lessonId,
    required this.isBookmarked,
  });

  @override
  List<Object?> get props => [lessonId, isBookmarked];
}

class UpdateLessonNotes extends LessonEvent {
  final String lessonId;
  final String notes;

  const UpdateLessonNotes({
    required this.lessonId,
    required this.notes,
  });

  @override
  List<Object?> get props => [lessonId, notes];
}

class MarkLessonComplete extends LessonEvent {
  final String lessonId;

  const MarkLessonComplete({required this.lessonId});

  @override
  List<Object?> get props => [lessonId];
}

class DownloadLessonContent extends LessonEvent {
  final String lessonId;

  const DownloadLessonContent({required this.lessonId});

  @override
  List<Object?> get props => [lessonId];
}

class DeleteLessonDownload extends LessonEvent {
  final String lessonId;

  const DeleteLessonDownload({required this.lessonId});

  @override
  List<Object?> get props => [lessonId];
}

class NavigateToNextLesson extends LessonEvent {
  final String currentLessonId;

  const NavigateToNextLesson({required this.currentLessonId});

  @override
  List<Object?> get props => [currentLessonId];
}

class NavigateToPreviousLesson extends LessonEvent {
  final String currentLessonId;

  const NavigateToPreviousLesson({required this.currentLessonId});

  @override
  List<Object?> get props => [currentLessonId];
}

class TrackLessonInteraction extends LessonEvent {
  final String lessonId;
  final String interactionType;
  final Map<String, dynamic> interactionData;

  const TrackLessonInteraction({
    required this.lessonId,
    required this.interactionType,
    required this.interactionData,
  });

  @override
  List<Object?> get props => [lessonId, interactionType, interactionData];
}

// States
abstract class LessonState extends Equatable {
  const LessonState();

  @override
  List<Object?> get props => [];
}

class LessonInitial extends LessonState {}

class LessonLoading extends LessonState {}

class LessonsLoaded extends LessonState {
  final List<Lesson> lessons;
  final bool hasReachedMax;
  final String? filterSubject;
  final String? filterGradeLevel;

  const LessonsLoaded({
    required this.lessons,
    this.hasReachedMax = false,
    this.filterSubject,
    this.filterGradeLevel,
  });

  @override
  List<Object?> get props => [lessons, hasReachedMax, filterSubject, filterGradeLevel];

  LessonsLoaded copyWith({
    List<Lesson>? lessons,
    bool? hasReachedMax,
    String? filterSubject,
    String? filterGradeLevel,
  }) {
    return LessonsLoaded(
      lessons: lessons ?? this.lessons,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      filterSubject: filterSubject ?? this.filterSubject,
      filterGradeLevel: filterGradeLevel ?? this.filterGradeLevel,
    );
  }
}

class LessonDetailLoaded extends LessonState {
  final Lesson lesson;
  final Lesson? nextLesson;
  final Lesson? previousLesson;
  final bool isDownloaded;

  const LessonDetailLoaded({
    required this.lesson,
    this.nextLesson,
    this.previousLesson,
    this.isDownloaded = false,
  });

  @override
  List<Object?> get props => [lesson, nextLesson, previousLesson, isDownloaded];

  LessonDetailLoaded copyWith({
    Lesson? lesson,
    Lesson? nextLesson,
    Lesson? previousLesson,
    bool? isDownloaded,
  }) {
    return LessonDetailLoaded(
      lesson: lesson ?? this.lesson,
      nextLesson: nextLesson ?? this.nextLesson,
      previousLesson: previousLesson ?? this.previousLesson,
      isDownloaded: isDownloaded ?? this.isDownloaded,
    );
  }
}

class LessonProgressUpdated extends LessonState {
  final String lessonId;
  final double progress;

  const LessonProgressUpdated({
    required this.lessonId,
    required this.progress,
  });

  @override
  List<Object?> get props => [lessonId, progress];
}

class LessonBookmarkToggled extends LessonState {
  final String lessonId;
  final bool isBookmarked;

  const LessonBookmarkToggled({
    required this.lessonId,
    required this.isBookmarked,
  });

  @override
  List<Object?> get props => [lessonId, isBookmarked];
}

class LessonNotesUpdated extends LessonState {
  final String lessonId;
  final String notes;

  const LessonNotesUpdated({
    required this.lessonId,
    required this.notes,
  });

  @override
  List<Object?> get props => [lessonId, notes];
}

class LessonCompleted extends LessonState {
  final String lessonId;
  final Lesson? nextLesson;

  const LessonCompleted({
    required this.lessonId,
    this.nextLesson,
  });

  @override
  List<Object?> get props => [lessonId, nextLesson];
}

class LessonDownloadStarted extends LessonState {
  final String lessonId;

  const LessonDownloadStarted({required this.lessonId});

  @override
  List<Object?> get props => [lessonId];
}

class LessonDownloadProgress extends LessonState {
  final String lessonId;
  final double progress;

  const LessonDownloadProgress({
    required this.lessonId,
    required this.progress,
  });

  @override
  List<Object?> get props => [lessonId, progress];
}

class LessonDownloadCompleted extends LessonState {
  final String lessonId;

  const LessonDownloadCompleted({required this.lessonId});

  @override
  List<Object?> get props => [lessonId];
}

class LessonDownloadDeleted extends LessonState {
  final String lessonId;

  const LessonDownloadDeleted({required this.lessonId});

  @override
  List<Object?> get props => [lessonId];
}

class LessonError extends LessonState {
  final String message;
  final Object? error;

  const LessonError({required this.message, this.error});

  @override
  List<Object?> get props => [message, error];
}

// BLoC
class LessonBloc extends HydratedBloc<LessonEvent, LessonState> {
  final Logger _logger = sl<Logger>();
  
  // In-memory cache of lessons
  List<Lesson> _allLessons = [];
  List<String> _downloadedLessonIds = [];
  Map<String, double> _lessonProgress = {};
  Map<String, bool> _lessonBookmarks = {};
  Map<String, String> _lessonNotes = {};
  
  // Track recently viewed lessons
  List<String> _recentlyViewedLessonIds = [];
  
  LessonBloc() : super(LessonInitial()) {
    on<LoadLessons>(_onLoadLessons);
    on<LoadLessonDetail>(_onLoadLessonDetail);
    on<UpdateLessonProgress>(_onUpdateLessonProgress);
    on<ToggleLessonBookmark>(_onToggleLessonBookmark);
    on<UpdateLessonNotes>(_onUpdateLessonNotes);
    on<MarkLessonComplete>(_onMarkLessonComplete);
    on<DownloadLessonContent>(_onDownloadLessonContent);
    on<DeleteLessonDownload>(_onDeleteLessonDownload);
    on<NavigateToNextLesson>(_onNavigateToNextLesson);
    on<NavigateToPreviousLesson>(_onNavigateToPreviousLesson);
    on<TrackLessonInteraction>(_onTrackLessonInteraction);
  }
  
  Future<void> _onLoadLessons(
    LoadLessons event,
    Emitter<LessonState> emit,
  ) async {
    try {
      emit(LessonLoading());
      
      // In a real app, we would fetch this from an API or local database
      // For now, use mock data if we don't have lessons yet or force refresh
      if (_allLessons.isEmpty || event.forceRefresh) {
        await _fetchLessons();
      }
      
      // Filter lessons by subject and grade level if provided
      List<Lesson> filteredLessons = _allLessons;
      
      if (event.subjectId != null) {
        filteredLessons = filteredLessons
            .where((lesson) => lesson.subject == event.subjectId)
            .toList();
      }
      
      if (event.gradeLevel != null) {
        filteredLessons = filteredLessons
            .where((lesson) => lesson.gradeLevel == event.gradeLevel)
            .toList();
      }
      
      // Sort lessons by sequence or order
      filteredLessons.sort((a, b) => 
        (a.sequence ?? 0).compareTo(b.sequence ?? 0));
      
      emit(LessonsLoaded(
        lessons: filteredLessons,
        hasReachedMax: true, // Mock data is all loaded at once
        filterSubject: event.subjectId,
        filterGradeLevel: event.gradeLevel,
      ));
    } catch (e, stackTrace) {
      _logger.e('Error loading lessons', error: e, stackTrace: stackTrace);
      emit(LessonError(message: 'Failed to load lessons: ${e.toString()}', error: e));
    }
  }
  
  Future<void> _onLoadLessonDetail(
    LoadLessonDetail event,
    Emitter<LessonState> emit,
  ) async {
    try {
      emit(LessonLoading());
      
      // Find the lesson in our cache
      final lessonIndex = _allLessons.indexWhere((l) => l.id == event.lessonId);
      
      if (lessonIndex == -1) {
        // Lesson not found in cache, try to fetch it
        await _fetchLessonDetail(event.lessonId);
        
        // Check again after fetching
        final lessonIndex = _allLessons.indexWhere((l) => l.id == event.lessonId);
        if (lessonIndex == -1) {
          emit(LessonError(message: 'Lesson not found'));
          return;
        }
      }
      
      // Get the lesson and adjacent lessons
      final lesson = _allLessons[lessonIndex];
      
      // Add progress and bookmark information
      final updatedLesson = lesson.copyWith(
        progress: _lessonProgress[lesson.id] ?? 0.0,
        isBookmarked: _lessonBookmarks[lesson.id] ?? false,
        notes: _lessonNotes[lesson.id],
      );
      
      // Find next and previous lessons
      Lesson? nextLesson;
      Lesson? previousLesson;
      
      // Only get adjacent lessons from the same subject
      final subjectLessons = _allLessons
          .where((l) => l.subject == lesson.subject)
          .toList()
        ..sort((a, b) => (a.sequence ?? 0).compareTo(b.sequence ?? 0));
      
      final currentIndex = subjectLessons.indexWhere((l) => l.id == lesson.id);
      
      if (currentIndex != -1) {
        if (currentIndex > 0) {
          previousLesson = subjectLessons[currentIndex - 1];
        }
        
        if (currentIndex < subjectLessons.length - 1) {
          nextLesson = subjectLessons[currentIndex + 1];
        }
      }
      
      // Add to recently viewed
      _addToRecentlyViewed(lesson.id);
      
      // Check if lesson is downloaded
      final isDownloaded = _downloadedLessonIds.contains(lesson.id);
      
      emit(LessonDetailLoaded(
        lesson: updatedLesson,
        nextLesson: nextLesson,
        previousLesson: previousLesson,
        isDownloaded: isDownloaded,
      ));
    } catch (e, stackTrace) {
      _logger.e('Error loading lesson detail', error: e, stackTrace: stackTrace);
      emit(LessonError(message: 'Failed to load lesson: ${e.toString()}', error: e));
    }
  }
  
  Future<void> _onUpdateLessonProgress(
    UpdateLessonProgress event,
    Emitter<LessonState> emit,
  ) async {
    try {
      // Update progress in memory
      _lessonProgress[event.lessonId] = event.progress;
      
      // Update lesson in cache if it exists
      final lessonIndex = _allLessons.indexWhere((l) => l.id == event.lessonId);
      if (lessonIndex != -1) {
        _allLessons[lessonIndex] = _allLessons[lessonIndex].copyWith(
          progress: event.progress,
        );
      }
      
      // Emit progress updated state
      emit(LessonProgressUpdated(
        lessonId: event.lessonId,
        progress: event.progress,
      ));
      
      // If current state is LessonDetailLoaded, update it
      if (state is LessonDetailLoaded) {
        final currentState = state as LessonDetailLoaded;
        if (currentState.lesson.id == event.lessonId) {
          emit(currentState.copyWith(
            lesson: currentState.lesson.copyWith(
              progress: event.progress,
            ),
          ));
        }
      }
      
      // If progress is 100%, mark as complete
      if (event.progress >= 1.0) {
        add(MarkLessonComplete(lessonId: event.lessonId));
      }
    } catch (e, stackTrace) {
      _logger.e('Error updating lesson progress', error: e, stackTrace: stackTrace);
      emit(LessonError(message: 'Failed to update progress: ${e.toString()}', error: e));
    }
  }
  
  Future<void> _onToggleLessonBookmark(
    ToggleLessonBookmark event,
    Emitter<LessonState> emit,
  ) async {
    try {
      // Update bookmark in memory
      _lessonBookmarks[event.lessonId] = event.isBookmarked;
      
      // Update lesson in cache if it exists
      final lessonIndex = _allLessons.indexWhere((l) => l.id == event.lessonId);
      if (lessonIndex != -1) {
        _allLessons[lessonIndex] = _allLessons[lessonIndex].copyWith(
          isBookmarked: event.isBookmarked,
        );
      }
      
      // Emit bookmark toggled state
      emit(LessonBookmarkToggled(
        lessonId: event.lessonId,
        isBookmarked: event.isBookmarked,
      ));
      
      // If current state is LessonDetailLoaded, update it
      if (state is LessonDetailLoaded) {
        final currentState = state as LessonDetailLoaded;
        if (currentState.lesson.id == event.lessonId) {
          emit(currentState.copyWith(
            lesson: currentState.lesson.copyWith(
              isBookmarked: event.isBookmarked,
            ),
          ));
        }
      }
    } catch (e, stackTrace) {
      _logger.e('Error toggling lesson bookmark', error: e, stackTrace: stackTrace);
      emit(LessonError(message: 'Failed to toggle bookmark: ${e.toString()}', error: e));
    }
  }
  
  Future<void> _onUpdateLessonNotes(
    UpdateLessonNotes event,
    Emitter<LessonState> emit,
  ) async {
    try {
      // Update notes in memory
      _lessonNotes[event.lessonId] = event.notes;
      
      // Update lesson in cache if it exists
      final lessonIndex = _allLessons.indexWhere((l) => l.id == event.lessonId);
      if (lessonIndex != -1) {
        _allLessons[lessonIndex] = _allLessons[lessonIndex].copyWith(
          notes: event.notes,
        );
      }
      
      // Emit notes updated state
      emit(LessonNotesUpdated(
        lessonId: event.lessonId,
        notes: event.notes,
      ));
      
      // If current state is LessonDetailLoaded, update it
      if (state is LessonDetailLoaded) {
        final currentState = state as LessonDetailLoaded;
        if (currentState.lesson.id == event.lessonId) {
          emit(currentState.copyWith(
            lesson: currentState.lesson.copyWith(
              notes: event.notes,
            ),
          ));
        }
      }
    } catch (e, stackTrace) {
      _logger.e('Error updating lesson notes', error: e, stackTrace: stackTrace);
      emit(LessonError(message: 'Failed to update notes: ${e.toString()}', error: e));
    }
  }
  
  Future<void> _onMarkLessonComplete(
    MarkLessonComplete event,
    Emitter<LessonState> emit,
  ) async {
    try {
      // Update progress to 100%
      _lessonProgress[event.lessonId] = 1.0;
      
      // Update lesson in cache if it exists
      final lessonIndex = _allLessons.indexWhere((l) => l.id == event.lessonId);
      if (lessonIndex == -1) {
        emit(LessonError(message: 'Lesson not found'));
        return;
      }
      
      _allLessons[lessonIndex] = _allLessons[lessonIndex].copyWith(
        progress: 1.0,
        completedAt: DateTime.now(),
      );
      
      // Find next lesson
      Lesson? nextLesson;
      
      // Get the current lesson
      final lesson = _allLessons[lessonIndex];
      
      // Find lessons in the same subject
      final subjectLessons = _allLessons
          .where((l) => l.subject == lesson.subject)
          .toList()
        ..sort((a, b) => (a.sequence ?? 0).compareTo(b.sequence ?? 0));
      
      final currentIndex = subjectLessons.indexWhere((l) => l.id == lesson.id);
      
      if (currentIndex != -1 && currentIndex < subjectLessons.length - 1) {
        nextLesson = subjectLessons[currentIndex + 1];
      }
      
      // Emit lesson completed state
      emit(LessonCompleted(
        lessonId: event.lessonId,
        nextLesson: nextLesson,
      ));
      
      // If current state is LessonDetailLoaded, update it
      if (state is LessonDetailLoaded) {
        final currentState = state as LessonDetailLoaded;
        if (currentState.lesson.id == event.lessonId) {
          emit(currentState.copyWith(
            lesson: currentState.lesson.copyWith(
              progress: 1.0,
              completedAt: DateTime.now(),
            ),
          ));
        }
      }
    } catch (e, stackTrace) {
      _logger.e('Error marking lesson complete', error: e, stackTrace: stackTrace);
      emit(LessonError(message: 'Failed to mark lesson complete: ${e.toString()}', error: e));
    }
  }
  
  Future<void> _onDownloadLessonContent(
    DownloadLessonContent event,
    Emitter<LessonState> emit,
  ) async {
    try {
      // Emit download started state
      emit(LessonDownloadStarted(lessonId: event.lessonId));
      
      // Simulate download progress
      for (int i = 1; i <= 10; i++) {
        await Future.delayed(const Duration(milliseconds: 200));
        emit(LessonDownloadProgress(
          lessonId: event.lessonId,
          progress: i / 10,
        ));
      }
      
      // Add to downloaded lessons
      if (!_downloadedLessonIds.contains(event.lessonId)) {
        _downloadedLessonIds.add(event.lessonId);
      }
      
      // Emit download completed state
      emit(LessonDownloadCompleted(lessonId: event.lessonId));
      
      // If current state is LessonDetailLoaded, update it
      if (state is LessonDetailLoaded) {
        final currentState = state as LessonDetailLoaded;
        if (currentState.lesson.id == event.lessonId) {
          emit(currentState.copyWith(isDownloaded: true));
        }
      }
    } catch (e, stackTrace) {
      _logger.e('Error downloading lesson content', error: e, stackTrace: stackTrace);
      emit(LessonError(message: 'Failed to download lesson: ${e.toString()}', error: e));
    }
  }
  
  Future<void> _onDeleteLessonDownload(
    DeleteLessonDownload event,
    Emitter<LessonState> emit,
  ) async {
    try {
      // Remove from downloaded lessons
      _downloadedLessonIds.remove(event.lessonId);
      
      // Emit download deleted state
      emit(LessonDownloadDeleted(lessonId: event.lessonId));
      
      // If current state is LessonDetailLoaded, update it
      if (state is LessonDetailLoaded) {
        final currentState = state as LessonDetailLoaded;
        if (currentState.lesson.id == event.lessonId) {
          emit(currentState.copyWith(isDownloaded: false));
        }
      }
    } catch (e, stackTrace) {
      _logger.e('Error deleting lesson download', error: e, stackTrace: stackTrace);
      emit(LessonError(message: 'Failed to delete download: ${e.toString()}', error: e));
    }
  }
  
  Future<void> _onNavigateToNextLesson(
    NavigateToNextLesson event,
    Emitter<LessonState> emit,
  ) async {
    try {
      // Find the current lesson
      final lessonIndex = _allLessons.indexWhere((l) => l.id == event.currentLessonId);
      if (lessonIndex == -1) {
        emit(LessonError(message: 'Current lesson not found'));
        return;
      }
      
      final lesson = _allLessons[lessonIndex];
      
      // Find lessons in the same subject
      final subjectLessons = _allLessons
          .where((l) => l.subject == lesson.subject)
          .toList()
        ..sort((a, b) => (a.sequence ?? 0).compareTo(b.sequence ?? 0));
      
      final currentIndex = subjectLessons.indexWhere((l) => l.id == lesson.id);
      
      if (currentIndex == -1 || currentIndex >= subjectLessons.length - 1) {
        emit(LessonError(message: 'No next lesson available'));
        return;
      }
      
      // Get the next lesson
      final nextLesson = subjectLessons[currentIndex + 1];
      
      // Load the next lesson
      add(LoadLessonDetail(lessonId: nextLesson.id));
    } catch (e, stackTrace) {
      _logger.e('Error navigating to next lesson', error: e, stackTrace: stackTrace);
      emit(LessonError(message: 'Failed to navigate to next lesson: ${e.toString()}', error: e));
    }
  }
  
  Future<void> _onNavigateToPreviousLesson(
    NavigateToPreviousLesson event,
    Emitter<LessonState> emit,
  ) async {
    try {
      // Find the current lesson
      final lessonIndex = _allLessons.indexWhere((l) => l.id == event.currentLessonId);
      if (lessonIndex == -1) {
        emit(LessonError(message: 'Current lesson not found'));
        return;
      }
      
      final lesson = _allLessons[lessonIndex];
      
      // Find lessons in the same subject
      final subjectLessons = _allLessons
          .where((l) => l.subject == lesson.subject)
          .toList()
        ..sort((a, b) => (a.sequence ?? 0).compareTo(b.sequence ?? 0));
      
      final currentIndex = subjectLessons.indexWhere((l) => l.id == lesson.id);
      
      if (currentIndex <= 0) {
        emit(LessonError(message: 'No previous lesson available'));
        return;
      }
      
      // Get the previous lesson
      final previousLesson = subjectLessons[currentIndex - 1];
      
      // Load the previous lesson
      add(LoadLessonDetail(lessonId: previousLesson.id));
    } catch (e, stackTrace) {
      _logger.e('Error navigating to previous lesson', error: e, stackTrace: stackTrace);
      emit(LessonError(message: 'Failed to navigate to previous lesson: ${e.toString()}', error: e));
    }
  }
  
  Future<void> _onTrackLessonInteraction(
    TrackLessonInteraction event,
    Emitter<LessonState> emit,
  ) async {
    try {
      // In a real app, we would track this in analytics
      _logger.i('Lesson interaction tracked', error: {
        'lessonId': event.lessonId,
        'interactionType': event.interactionType,
        'interactionData': event.interactionData,
      });
      
      // For now, just log it
    } catch (e, stackTrace) {
      _logger.e('Error tracking lesson interaction', error: e, stackTrace: stackTrace);
      // Don't emit error state, just log it
    }
  }
  
  // Helper methods
  Future<void> _fetchLessons() async {
    // In a real app, we would fetch this from an API or local database
    // For now, use mock data
    
    final subjects = ['mathematics', 'english', 'science', 'history', 'geography', 'agriculture'];
    final gradeLevels = ['ecd', 'primary_1_3', 'primary_4_7', 'secondary_1_2', 'secondary_3_4'];
    
    // Create mock lessons
    _allLessons = [];
    
    for (final subject in subjects) {
      for (final gradeLevel in gradeLevels) {
        // Create 5 lessons per subject and grade level
        for (int i = 1; i <= 5; i++) {
          final lessonId = const Uuid().v4();
          
          _allLessons.add(Lesson(
            id: lessonId,
            title: 'Lesson $i: ${_getSubjectTitle(subject)} for ${_getGradeLevelTitle(gradeLevel)}',
            description: 'Learn about important concepts in ${_getSubjectTitle(subject)} for ${_getGradeLevelTitle(gradeLevel)} students.',
            subject: subject,
            gradeLevel: gradeLevel,
            contentType: _getRandomContentType(),
            sequence: i,
            duration: Duration(minutes: 15 + (i * 5)),
            hasVideoContent: i % 2 == 0, // Even numbered lessons have video
            videoUrl: i % 2 == 0 ? 'https://example.com/videos/$subject/$gradeLevel/lesson_$i.mp4' : null,
            createdAt: DateTime.now().subtract(Duration(days: 30 - i)),
            updatedAt: DateTime.now().subtract(Duration(days: 15 - i)),
          ));
        }
      }
    }
  }
  
  Future<void> _fetchLessonDetail(String lessonId) async {
    // In a real app, we would fetch this from an API or local database
    // For now, just check if it exists in our mock data
    
    final lessonIndex = _allLessons.indexWhere((l) => l.id == lessonId);
    
    if (lessonIndex == -1) {
      // If not found, create a mock lesson
      final lesson = Lesson(
        id: lessonId,
        title: 'Lesson Detail',
        description: 'This is a mock lesson detail that was not found in the cache.',
        subject: 'general',
        gradeLevel: 'primary_4_7',
        contentType: ContentType.text,
        sequence: 1,
        duration: const Duration(minutes: 30),
        hasVideoContent: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      _allLessons.add(lesson);
    }
  }
  
  void _addToRecentlyViewed(String lessonId) {
    // Remove if already exists
    _recentlyViewedLessonIds.remove(lessonId);
    
    // Add to the beginning
    _recentlyViewedLessonIds.insert(0, lessonId);
    
    // Keep only the 10 most recent
    if (_recentlyViewedLessonIds.length > 10) {
      _recentlyViewedLessonIds = _recentlyViewedLessonIds.sublist(0, 10);
    }
  }
  
  String _getSubjectTitle(String subject) {
    switch (subject) {
      case 'mathematics':
        return 'Mathematics';
      case 'english':
        return 'English Language';
      case 'science':
        return 'Science';
      case 'history':
        return 'History';
      case 'geography':
        return 'Geography';
      case 'agriculture':
        return 'Agriculture';
      default:
        return 'General';
    }
  }
  
  String _getGradeLevelTitle(String gradeLevel) {
    switch (gradeLevel) {
      case 'ecd':
        return 'ECD';
      case 'primary_1_3':
        return 'Primary 1-3';
      case 'primary_4_7':
        return 'Primary 4-7';
      case 'secondary_1_2':
        return 'Form 1-2';
      case 'secondary_3_4':
        return 'Form 3-4';
      default:
        return 'All Grades';
    }
  }
  
  ContentType _getRandomContentType() {
    final types = ContentType.values;
    return types[DateTime.now().millisecondsSinceEpoch % types.length];
  }
  
  // Hydrated BLoC methods
  @override
  LessonState? fromJson(Map<String, dynamic> json) {
    try {
      // Deserialize lessons
      final lessons = (json['lessons'] as List?)
          ?.map((e) => Lesson.fromJson(e as Map<String, dynamic>))
          .toList() ?? [];
      
      // Deserialize downloaded lesson IDs
      final downloadedLessonIds = (json['downloadedLessonIds'] as List?)
          ?.map((e) => e as String)
          .toList() ?? [];
      
      // Deserialize lesson progress
      final lessonProgress = (json['lessonProgress'] as Map?)?.map(
        (k, v) => MapEntry(k as String, (v as num).toDouble()),
      ) ?? {};
      
      // Deserialize lesson bookmarks
      final lessonBookmarks = (json['lessonBookmarks'] as Map?)?.map(
        (k, v) => MapEntry(k as String, v as bool),
      ) ?? {};
      
      // Deserialize lesson notes
      final lessonNotes = (json['lessonNotes'] as Map?)?.map(
        (k, v) => MapEntry(k as String, v as String),
      ) ?? {};
      
      // Deserialize recently viewed lesson IDs
      final recentlyViewedLessonIds = (json['recentlyViewedLessonIds'] as List?)
          ?.map((e) => e as String)
          .toList() ?? [];
      
      // Update in-memory cache
      _allLessons = lessons;
      _downloadedLessonIds = downloadedLessonIds;
      _lessonProgress = lessonProgress;
      _lessonBookmarks = lessonBookmarks;
      _lessonNotes = lessonNotes;
      _recentlyViewedLessonIds = recentlyViewedLessonIds;
      
      // Return the appropriate state
      final currentState = json['currentState'] as String?;
      
      switch (currentState) {
        case 'lessonsLoaded':
          return LessonsLoaded(
            lessons: lessons,
            hasReachedMax: json['hasReachedMax'] as bool? ?? true,
            filterSubject: json['filterSubject'] as String?,
            filterGradeLevel: json['filterGradeLevel'] as String?,
          );
        case 'lessonDetailLoaded':
          final lessonId = json['currentLessonId'] as String?;
          if (lessonId == null) return LessonInitial();
          
          final lessonIndex = lessons.indexWhere((l) => l.id == lessonId);
          if (lessonIndex == -1) return LessonInitial();
          
          final lesson = lessons[lessonIndex];
          
          // Find next and previous lessons
          Lesson? nextLesson;
          Lesson? previousLesson;
          
          final nextLessonId = json['nextLessonId'] as String?;
          final previousLessonId = json['previousLessonId'] as String?;
          
          if (nextLessonId != null) {
            final nextIndex = lessons.indexWhere((l) => l.id == nextLessonId);
            if (nextIndex != -1) {
              nextLesson = lessons[nextIndex];
            }
          }
          
          if (previousLessonId != null) {
            final prevIndex = lessons.indexWhere((l) => l.id == previousLessonId);
            if (prevIndex != -1) {
              previousLesson = lessons[prevIndex];
            }
          }
          
          return LessonDetailLoaded(
            lesson: lesson,
            nextLesson: nextLesson,
            previousLesson: previousLesson,
            isDownloaded: downloadedLessonIds.contains(lessonId),
          );
        default:
          return LessonInitial();
      }
    } catch (e, stackTrace) {
      _logger.e('Error deserializing lesson state', error: e, stackTrace: stackTrace);
      return LessonInitial();
    }
  }
  
  @override
  Map<String, dynamic>? toJson(LessonState state) {
    try {
      final Map<String, dynamic> json = {
        'lessons': _allLessons.map((l) => l.toJson()).toList(),
        'downloadedLessonIds': _downloadedLessonIds,
        'lessonProgress': _lessonProgress,
        'lessonBookmarks': _lessonBookmarks,
        'lessonNotes': _lessonNotes,
        'recentlyViewedLessonIds': _recentlyViewedLessonIds,
      };
      
      if (state is LessonsLoaded) {
        json['currentState'] = 'lessonsLoaded';
        json['hasReachedMax'] = state.hasReachedMax;
        json['filterSubject'] = state.filterSubject;
        json['filterGradeLevel'] = state.filterGradeLevel;
      } else if (state is LessonDetailLoaded) {
        json['currentState'] = 'lessonDetailLoaded';
        json['currentLessonId'] = state.lesson.id;
        json['nextLessonId'] = state.nextLesson?.id;
        json['previousLessonId'] = state.previousLesson?.id;
      }
      
      return json;
    } catch (e, stackTrace) {
      _logger.e('Error serializing lesson state', error: e, stackTrace: stackTrace);
      return null;
    }
  }
}
