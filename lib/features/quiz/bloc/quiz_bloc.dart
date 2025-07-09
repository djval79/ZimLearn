import 'dart:async';
import 'dart:math' as math;

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants.dart';
import '../../../core/services/service_locator.dart';
import '../../../data/models/quiz.dart';
import '../../../data/models/user.dart';

// Events
abstract class QuizEvent extends Equatable {
  const QuizEvent();

  @override
  List<Object?> get props => [];
}

class LoadQuizzes extends QuizEvent {
  final String? subjectId;
  final String? gradeLevel;
  final bool forceRefresh;

  const LoadQuizzes({
    this.subjectId,
    this.gradeLevel,
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [subjectId, gradeLevel, forceRefresh];
}

class LoadQuizDetail extends QuizEvent {
  final String quizId;

  const LoadQuizDetail({required this.quizId});

  @override
  List<Object?> get props => [quizId];
}

class StartQuiz extends QuizEvent {
  final String quizId;
  final QuizDifficulty difficulty;
  final bool isTimed;

  const StartQuiz({
    required this.quizId,
    this.difficulty = QuizDifficulty.medium,
    this.isTimed = true,
  });

  @override
  List<Object?> get props => [quizId, difficulty, isTimed];
}

class SubmitQuizAttempt extends QuizEvent {
  final QuizAttempt attempt;

  const SubmitQuizAttempt({required this.attempt});

  @override
  List<Object?> get props => [attempt];
}

class AnswerQuestion extends QuizEvent {
  final String quizId;
  final String questionId;
  final List<String> selectedOptionIds;
  final String textAnswer;
  final bool isCorrect;
  final int timeTaken;

  const AnswerQuestion({
    required this.quizId,
    required this.questionId,
    this.selectedOptionIds = const [],
    this.textAnswer = '',
    this.isCorrect = false,
    this.timeTaken = 0,
  });

  @override
  List<Object?> get props => [
        quizId,
        questionId,
        selectedOptionIds,
        textAnswer,
        isCorrect,
        timeTaken,
      ];
}

class UseHint extends QuizEvent {
  final String quizId;
  final String questionId;

  const UseHint({
    required this.quizId,
    required this.questionId,
  });

  @override
  List<Object?> get props => [quizId, questionId];
}

class PauseQuiz extends QuizEvent {
  final String quizId;
  final int elapsedTimeSeconds;

  const PauseQuiz({
    required this.quizId,
    required this.elapsedTimeSeconds,
  });

  @override
  List<Object?> get props => [quizId, elapsedTimeSeconds];
}

class ResumeQuiz extends QuizEvent {
  final String quizId;

  const ResumeQuiz({required this.quizId});

  @override
  List<Object?> get props => [quizId];
}

class AbandonQuiz extends QuizEvent {
  final String quizId;

  const AbandonQuiz({required this.quizId});

  @override
  List<Object?> get props => [quizId];
}

class LoadQuizAttempts extends QuizEvent {
  final String? quizId;
  final String? userId;

  const LoadQuizAttempts({
    this.quizId,
    this.userId,
  });

  @override
  List<Object?> get props => [quizId, userId];
}

class LoadQuizAnalytics extends QuizEvent {
  final String userId;
  final String? subjectId;
  final String? gradeLevel;
  final DateTime? startDate;
  final DateTime? endDate;

  const LoadQuizAnalytics({
    required this.userId,
    this.subjectId,
    this.gradeLevel,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [userId, subjectId, gradeLevel, startDate, endDate];
}

class TrackQuizEvent extends QuizEvent {
  final String quizId;
  final String eventType;
  final Map<String, dynamic> eventData;

  const TrackQuizEvent({
    required this.quizId,
    required this.eventType,
    required this.eventData,
  });

  @override
  List<Object?> get props => [quizId, eventType, eventData];
}

// States
abstract class QuizState extends Equatable {
  const QuizState();

  @override
  List<Object?> get props => [];
}

class QuizInitial extends QuizState {}

class QuizLoading extends QuizState {}

class QuizzesLoaded extends QuizState {
  final List<Quiz> quizzes;
  final bool hasReachedMax;
  final String? filterSubject;
  final String? filterGradeLevel;

  const QuizzesLoaded({
    required this.quizzes,
    this.hasReachedMax = false,
    this.filterSubject,
    this.filterGradeLevel,
  });

  @override
  List<Object?> get props => [quizzes, hasReachedMax, filterSubject, filterGradeLevel];

  QuizzesLoaded copyWith({
    List<Quiz>? quizzes,
    bool? hasReachedMax,
    String? filterSubject,
    String? filterGradeLevel,
  }) {
    return QuizzesLoaded(
      quizzes: quizzes ?? this.quizzes,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      filterSubject: filterSubject ?? this.filterSubject,
      filterGradeLevel: filterGradeLevel ?? this.filterGradeLevel,
    );
  }
}

class QuizDetailLoaded extends QuizState {
  final Quiz quiz;
  final List<QuizAttempt> attempts;
  final bool isCompleted;
  final double bestScore;

  const QuizDetailLoaded({
    required this.quiz,
    this.attempts = const [],
    this.isCompleted = false,
    this.bestScore = 0.0,
  });

  @override
  List<Object?> get props => [quiz, attempts, isCompleted, bestScore];

  QuizDetailLoaded copyWith({
    Quiz? quiz,
    List<QuizAttempt>? attempts,
    bool? isCompleted,
    double? bestScore,
  }) {
    return QuizDetailLoaded(
      quiz: quiz ?? this.quiz,
      attempts: attempts ?? this.attempts,
      isCompleted: isCompleted ?? this.isCompleted,
      bestScore: bestScore ?? this.bestScore,
    );
  }
}

class QuizStarted extends QuizState {
  final Quiz quiz;
  final QuizDifficulty difficulty;
  final bool isTimed;
  final DateTime startTime;
  final int hintsRemaining;

  const QuizStarted({
    required this.quiz,
    required this.difficulty,
    required this.isTimed,
    required this.startTime,
    required this.hintsRemaining,
  });

  @override
  List<Object?> get props => [quiz, difficulty, isTimed, startTime, hintsRemaining];
}

class QuizPaused extends QuizState {
  final Quiz quiz;
  final int elapsedTimeSeconds;
  final List<QuizAnswer> currentAnswers;
  final int hintsRemaining;

  const QuizPaused({
    required this.quiz,
    required this.elapsedTimeSeconds,
    required this.currentAnswers,
    required this.hintsRemaining,
  });

  @override
  List<Object?> get props => [quiz, elapsedTimeSeconds, currentAnswers, hintsRemaining];
}

class QuizResumed extends QuizState {
  final Quiz quiz;
  final int elapsedTimeSeconds;
  final List<QuizAnswer> currentAnswers;
  final int hintsRemaining;
  final DateTime resumeTime;

  const QuizResumed({
    required this.quiz,
    required this.elapsedTimeSeconds,
    required this.currentAnswers,
    required this.hintsRemaining,
    required this.resumeTime,
  });

  @override
  List<Object?> get props => [quiz, elapsedTimeSeconds, currentAnswers, hintsRemaining, resumeTime];
}

class QuizCompleted extends QuizState {
  final Quiz quiz;
  final QuizAttempt attempt;
  final bool isPersonalBest;
  final List<String> strongSubjects;
  final List<String> weakSubjects;

  const QuizCompleted({
    required this.quiz,
    required this.attempt,
    this.isPersonalBest = false,
    this.strongSubjects = const [],
    this.weakSubjects = const [],
  });

  @override
  List<Object?> get props => [quiz, attempt, isPersonalBest, strongSubjects, weakSubjects];
}

class QuizAbandoned extends QuizState {
  final String quizId;
  final DateTime abandonTime;

  const QuizAbandoned({
    required this.quizId,
    required this.abandonTime,
  });

  @override
  List<Object?> get props => [quizId, abandonTime];
}

class QuizAttemptsLoaded extends QuizState {
  final List<QuizAttempt> attempts;
  final String? quizId;
  final String? userId;

  const QuizAttemptsLoaded({
    required this.attempts,
    this.quizId,
    this.userId,
  });

  @override
  List<Object?> get props => [attempts, quizId, userId];
}

class QuizAnalyticsLoaded extends QuizState {
  final String userId;
  final int totalQuizzesTaken;
  final int totalQuizzesCompleted;
  final double averageScore;
  final Map<String, double> subjectPerformance;
  final List<QuizAttempt> recentAttempts;
  final Map<String, int> questionTypePerformance;

  const QuizAnalyticsLoaded({
    required this.userId,
    required this.totalQuizzesTaken,
    required this.totalQuizzesCompleted,
    required this.averageScore,
    required this.subjectPerformance,
    required this.recentAttempts,
    required this.questionTypePerformance,
  });

  @override
  List<Object?> get props => [
        userId,
        totalQuizzesTaken,
        totalQuizzesCompleted,
        averageScore,
        subjectPerformance,
        recentAttempts,
        questionTypePerformance,
      ];
}

class HintUsed extends QuizState {
  final String quizId;
  final String questionId;
  final int hintsRemaining;
  final String hintText;

  const HintUsed({
    required this.quizId,
    required this.questionId,
    required this.hintsRemaining,
    required this.hintText,
  });

  @override
  List<Object?> get props => [quizId, questionId, hintsRemaining, hintText];
}

class QuestionAnswered extends QuizState {
  final String quizId;
  final String questionId;
  final bool isCorrect;
  final String feedback;
  final int currentScore;
  final int maxScore;

  const QuestionAnswered({
    required this.quizId,
    required this.questionId,
    required this.isCorrect,
    required this.feedback,
    required this.currentScore,
    required this.maxScore,
  });

  @override
  List<Object?> get props => [quizId, questionId, isCorrect, feedback, currentScore, maxScore];
}

class QuizError extends QuizState {
  final String message;
  final Object? error;

  const QuizError({required this.message, this.error});

  @override
  List<Object?> get props => [message, error];
}

// BLoC
class QuizBloc extends HydratedBloc<QuizEvent, QuizState> {
  final Logger _logger = sl<Logger>();
  
  // In-memory cache
  List<Quiz> _allQuizzes = [];
  List<QuizAttempt> _allAttempts = [];
  Map<String, List<QuizAnswer>> _currentQuizAnswers = {};
  Map<String, int> _quizElapsedTimes = {};
  Map<String, int> _quizHintsRemaining = {};
  
  QuizBloc() : super(QuizInitial()) {
    on<LoadQuizzes>(_onLoadQuizzes);
    on<LoadQuizDetail>(_onLoadQuizDetail);
    on<StartQuiz>(_onStartQuiz);
    on<SubmitQuizAttempt>(_onSubmitQuizAttempt);
    on<AnswerQuestion>(_onAnswerQuestion);
    on<UseHint>(_onUseHint);
    on<PauseQuiz>(_onPauseQuiz);
    on<ResumeQuiz>(_onResumeQuiz);
    on<AbandonQuiz>(_onAbandonQuiz);
    on<LoadQuizAttempts>(_onLoadQuizAttempts);
    on<LoadQuizAnalytics>(_onLoadQuizAnalytics);
    on<TrackQuizEvent>(_onTrackQuizEvent);
  }
  
  Future<void> _onLoadQuizzes(
    LoadQuizzes event,
    Emitter<QuizState> emit,
  ) async {
    try {
      emit(QuizLoading());
      
      // In a real app, we would fetch this from an API or local database
      // For now, use mock data if we don't have quizzes yet or force refresh
      if (_allQuizzes.isEmpty || event.forceRefresh) {
        await _fetchQuizzes();
      }
      
      // Filter quizzes by subject and grade level if provided
      List<Quiz> filteredQuizzes = _allQuizzes;
      
      if (event.subjectId != null) {
        filteredQuizzes = filteredQuizzes
            .where((quiz) => quiz.subject == event.subjectId)
            .toList();
      }
      
      if (event.gradeLevel != null) {
        filteredQuizzes = filteredQuizzes
            .where((quiz) => quiz.gradeLevel == event.gradeLevel)
            .toList();
      }
      
      // Sort quizzes by difficulty or order
      filteredQuizzes.sort((a, b) => 
        (a.difficulty.index).compareTo(b.difficulty.index));
      
      emit(QuizzesLoaded(
        quizzes: filteredQuizzes,
        hasReachedMax: true, // Mock data is all loaded at once
        filterSubject: event.subjectId,
        filterGradeLevel: event.gradeLevel,
      ));
    } catch (e, stackTrace) {
      _logger.e('Error loading quizzes', error: e, stackTrace: stackTrace);
      emit(QuizError(message: 'Failed to load quizzes: ${e.toString()}', error: e));
    }
  }
  
  Future<void> _onLoadQuizDetail(
    LoadQuizDetail event,
    Emitter<QuizState> emit,
  ) async {
    try {
      emit(QuizLoading());
      
      // Find the quiz in our cache
      final quizIndex = _allQuizzes.indexWhere((q) => q.id == event.quizId);
      
      if (quizIndex == -1) {
        // Quiz not found in cache, try to fetch it
        await _fetchQuizDetail(event.quizId);
        
        // Check again after fetching
        final quizIndex = _allQuizzes.indexWhere((q) => q.id == event.quizId);
        if (quizIndex == -1) {
          emit(QuizError(message: 'Quiz not found'));
          return;
        }
      }
      
      final quiz = _allQuizzes[quizIndex];
      
      // Get attempts for this quiz
      final attempts = _allAttempts
          .where((a) => a.quizId == event.quizId)
          .toList();
      
      // Calculate best score
      double bestScore = 0.0;
      bool isCompleted = false;
      
      if (attempts.isNotEmpty) {
        isCompleted = true;
        
        // Find the highest score
        final bestAttempt = attempts.reduce((a, b) => 
          (a.score / a.maxScore) > (b.score / b.maxScore) ? a : b);
        
        bestScore = bestAttempt.score / bestAttempt.maxScore;
      }
      
      emit(QuizDetailLoaded(
        quiz: quiz,
        attempts: attempts,
        isCompleted: isCompleted,
        bestScore: bestScore,
      ));
    } catch (e, stackTrace) {
      _logger.e('Error loading quiz detail', error: e, stackTrace: stackTrace);
      emit(QuizError(message: 'Failed to load quiz: ${e.toString()}', error: e));
    }
  }
  
  Future<void> _onStartQuiz(
    StartQuiz event,
    Emitter<QuizState> emit,
  ) async {
    try {
      emit(QuizLoading());
      
      // Find the quiz
      final quizIndex = _allQuizzes.indexWhere((q) => q.id == event.quizId);
      
      if (quizIndex == -1) {
        emit(QuizError(message: 'Quiz not found'));
        return;
      }
      
      final quiz = _allQuizzes[quizIndex];
      
      // Calculate hints based on difficulty
      int hintsPerQuestion = 0;
      switch (event.difficulty) {
        case QuizDifficulty.easy:
          hintsPerQuestion = 3;
          break;
        case QuizDifficulty.medium:
          hintsPerQuestion = 2;
          break;
        case QuizDifficulty.hard:
          hintsPerQuestion = 1;
          break;
        case QuizDifficulty.expert:
          hintsPerQuestion = 0;
          break;
      }
      
      final totalHints = quiz.questions.length * hintsPerQuestion;
      
      // Initialize answers for this quiz
      _currentQuizAnswers[event.quizId] = List.generate(
        quiz.questions.length,
        (index) => QuizAnswer(
          questionId: quiz.questions[index].id,
          selectedOptionIds: [],
          textAnswer: '',
          isCorrect: false,
          timeTaken: 0,
        ),
      );
      
      // Reset elapsed time
      _quizElapsedTimes[event.quizId] = 0;
      
      // Set hints remaining
      _quizHintsRemaining[event.quizId] = totalHints;
      
      // Emit quiz started state
      emit(QuizStarted(
        quiz: quiz,
        difficulty: event.difficulty,
        isTimed: event.isTimed,
        startTime: DateTime.now(),
        hintsRemaining: totalHints,
      ));
      
      // Track quiz start event
      add(TrackQuizEvent(
        quizId: event.quizId,
        eventType: 'quiz_started',
        eventData: {
          'difficulty': event.difficulty.toString(),
          'isTimed': event.isTimed,
          'questionCount': quiz.questions.length,
        },
      ));
    } catch (e, stackTrace) {
      _logger.e('Error starting quiz', error: e, stackTrace: stackTrace);
      emit(QuizError(message: 'Failed to start quiz: ${e.toString()}', error: e));
    }
  }
  
  Future<void> _onSubmitQuizAttempt(
    SubmitQuizAttempt event,
    Emitter<QuizState> emit,
  ) async {
    try {
      emit(QuizLoading());
      
      // Find the quiz
      final quizIndex = _allQuizzes.indexWhere((q) => q.id == event.attempt.quizId);
      
      if (quizIndex == -1) {
        emit(QuizError(message: 'Quiz not found'));
        return;
      }
      
      final quiz = _allQuizzes[quizIndex];
      
      // Add attempt to cache
      _allAttempts.add(event.attempt);
      
      // Clean up in-memory state for this quiz
      _currentQuizAnswers.remove(event.attempt.quizId);
      _quizElapsedTimes.remove(event.attempt.quizId);
      _quizHintsRemaining.remove(event.attempt.quizId);
      
      // Check if this is a personal best
      bool isPersonalBest = false;
      final previousAttempts = _allAttempts
          .where((a) => a.quizId == event.attempt.quizId && a.id != event.attempt.id)
          .toList();
      
      if (previousAttempts.isEmpty) {
        isPersonalBest = true;
      } else {
        final currentScore = event.attempt.score / event.attempt.maxScore;
        final bestPreviousAttempt = previousAttempts.reduce((a, b) => 
          (a.score / a.maxScore) > (b.score / b.maxScore) ? a : b);
        final bestPreviousScore = bestPreviousAttempt.score / bestPreviousAttempt.maxScore;
        
        isPersonalBest = currentScore > bestPreviousScore;
      }
      
      // Analyze strong and weak subjects
      final subjectPerformance = <String, List<bool>>{};
      
      for (int i = 0; i < quiz.questions.length; i++) {
        final question = quiz.questions[i];
        final answer = i < event.attempt.answers.length ? event.attempt.answers[i] : null;
        final isCorrect = answer?.isCorrect ?? false;
        
        final subject = question.subject ?? 'General';
        if (!subjectPerformance.containsKey(subject)) {
          subjectPerformance[subject] = [];
        }
        subjectPerformance[subject]!.add(isCorrect);
      }
      
      // Determine strong and weak subjects
      final strongSubjects = <String>[];
      final weakSubjects = <String>[];
      
      subjectPerformance.forEach((subject, results) {
        if (results.isNotEmpty) {
          final correctCount = results.where((r) => r).length;
          final percentage = correctCount / results.length;
          
          if (percentage >= 0.7) {
            strongSubjects.add(subject);
          } else if (percentage <= 0.4) {
            weakSubjects.add(subject);
          }
        }
      });
      
      // Emit quiz completed state
      emit(QuizCompleted(
        quiz: quiz,
        attempt: event.attempt,
        isPersonalBest: isPersonalBest,
        strongSubjects: strongSubjects,
        weakSubjects: weakSubjects,
      ));
      
      // Track quiz completion event
      add(TrackQuizEvent(
        quizId: event.attempt.quizId,
        eventType: 'quiz_completed',
        eventData: {
          'score': event.attempt.score,
          'maxScore': event.attempt.maxScore,
          'timeTaken': event.attempt.timeTaken,
          'hintsUsed': event.attempt.hintsUsed,
          'isPersonalBest': isPersonalBest,
        },
      ));
    } catch (e, stackTrace) {
      _logger.e('Error submitting quiz attempt', error: e, stackTrace: stackTrace);
      emit(QuizError(message: 'Failed to submit quiz: ${e.toString()}', error: e));
    }
  }
  
  Future<void> _onAnswerQuestion(
    AnswerQuestion event,
    Emitter<QuizState> emit,
  ) async {
    try {
      // Find the quiz
      final quizIndex = _allQuizzes.indexWhere((q) => q.id == event.quizId);
      
      if (quizIndex == -1) {
        emit(QuizError(message: 'Quiz not found'));
        return;
      }
      
      final quiz = _allQuizzes[quizIndex];
      
      // Find the question
      final questionIndex = quiz.questions.indexWhere((q) => q.id == event.questionId);
      
      if (questionIndex == -1) {
        emit(QuizError(message: 'Question not found'));
        return;
      }
      
      final question = quiz.questions[questionIndex];
      
      // Update answer in memory
      if (_currentQuizAnswers.containsKey(event.quizId) && 
          questionIndex < _currentQuizAnswers[event.quizId]!.length) {
        
        _currentQuizAnswers[event.quizId]![questionIndex] = QuizAnswer(
          questionId: event.questionId,
          selectedOptionIds: event.selectedOptionIds,
          textAnswer: event.textAnswer,
          isCorrect: event.isCorrect,
          timeTaken: event.timeTaken,
        );
      }
      
      // Calculate current score
      int currentScore = 0;
      int maxScore = 0;
      
      if (_currentQuizAnswers.containsKey(event.quizId)) {
        for (int i = 0; i < quiz.questions.length; i++) {
          final q = quiz.questions[i];
          maxScore += q.points ?? 1;
          
          if (i < _currentQuizAnswers[event.quizId]!.length) {
            final answer = _currentQuizAnswers[event.quizId]![i];
            if (answer.isCorrect) {
              currentScore += q.points ?? 1;
            }
          }
        }
      }
      
      // Generate feedback
      String feedback = '';
      if (event.isCorrect) {
        feedback = question.correctFeedback ?? 'Correct!';
      } else {
        feedback = question.incorrectFeedback ?? 'Incorrect. Try again!';
      }
      
      // Emit question answered state
      emit(QuestionAnswered(
        quizId: event.quizId,
        questionId: event.questionId,
        isCorrect: event.isCorrect,
        feedback: feedback,
        currentScore: currentScore,
        maxScore: maxScore,
      ));
      
      // Track question answer event
      add(TrackQuizEvent(
        quizId: event.quizId,
        eventType: 'question_answered',
        eventData: {
          'questionId': event.questionId,
          'isCorrect': event.isCorrect,
          'timeTaken': event.timeTaken,
          'questionType': question.type.toString(),
        },
      ));
    } catch (e, stackTrace) {
      _logger.e('Error answering question', error: e, stackTrace: stackTrace);
      emit(QuizError(message: 'Failed to answer question: ${e.toString()}', error: e));
    }
  }
  
  Future<void> _onUseHint(
    UseHint event,
    Emitter<QuizState> emit,
  ) async {
    try {
      // Check if hints are available
      if (!_quizHintsRemaining.containsKey(event.quizId) || 
          _quizHintsRemaining[event.quizId]! <= 0) {
        emit(QuizError(message: 'No hints remaining'));
        return;
      }
      
      // Find the quiz
      final quizIndex = _allQuizzes.indexWhere((q) => q.id == event.quizId);
      
      if (quizIndex == -1) {
        emit(QuizError(message: 'Quiz not found'));
        return;
      }
      
      final quiz = _allQuizzes[quizIndex];
      
      // Find the question
      final questionIndex = quiz.questions.indexWhere((q) => q.id == event.questionId);
      
      if (questionIndex == -1) {
        emit(QuizError(message: 'Question not found'));
        return;
      }
      
      final question = quiz.questions[questionIndex];
      
      // Decrement hints remaining
      _quizHintsRemaining[event.quizId] = _quizHintsRemaining[event.quizId]! - 1;
      
      // Generate hint based on question type
      String hintText = '';
      
      switch (question.type) {
        case QuestionType.multipleChoice:
          // Eliminate one wrong option
          final correctOptionId = question.correctOptionIds.first;
          final wrongOptions = question.options
              .where((option) => option.id != correctOptionId)
              .toList();
          
          if (wrongOptions.isNotEmpty) {
            final wrongOption = wrongOptions[math.Random().nextInt(wrongOptions.length)];
            hintText = 'Hint: "${wrongOption.text}" is not the correct answer.';
          }
          break;
        case QuestionType.trueFalse:
          hintText = 'Hint: Think carefully about the statement.';
          break;
        case QuestionType.multipleAnswer:
          hintText = 'Hint: There are ${question.correctOptionIds.length} correct answers.';
          break;
        case QuestionType.fillInBlank:
          // Give first letter hint
          final answer = question.correctAnswer ?? '';
          if (answer.isNotEmpty) {
            hintText = 'Hint: The answer starts with "${answer[0]}".';
          }
          break;
        case QuestionType.matching:
          hintText = 'Hint: One of the matches is correct.';
          break;
        case QuestionType.ordering:
          hintText = 'Hint: Consider the logical sequence.';
          break;
        default:
          hintText = 'Hint: Read the question carefully.';
      }
      
      // Emit hint used state
      emit(HintUsed(
        quizId: event.quizId,
        questionId: event.questionId,
        hintsRemaining: _quizHintsRemaining[event.quizId]!,
        hintText: hintText,
      ));
      
      // Track hint use event
      add(TrackQuizEvent(
        quizId: event.quizId,
        eventType: 'hint_used',
        eventData: {
          'questionId': event.questionId,
          'hintsRemaining': _quizHintsRemaining[event.quizId]!,
          'questionType': question.type.toString(),
        },
      ));
    } catch (e, stackTrace) {
      _logger.e('Error using hint', error: e, stackTrace: stackTrace);
      emit(QuizError(message: 'Failed to use hint: ${e.toString()}', error: e));
    }
  }
  
  Future<void> _onPauseQuiz(
    PauseQuiz event,
    Emitter<QuizState> emit,
  ) async {
    try {
      // Find the quiz
      final quizIndex = _allQuizzes.indexWhere((q) => q.id == event.quizId);
      
      if (quizIndex == -1) {
        emit(QuizError(message: 'Quiz not found'));
        return;
      }
      
      final quiz = _allQuizzes[quizIndex];
      
      // Update elapsed time
      _quizElapsedTimes[event.quizId] = event.elapsedTimeSeconds;
      
      // Get current answers
      final currentAnswers = _currentQuizAnswers.containsKey(event.quizId)
          ? _currentQuizAnswers[event.quizId]!
          : [];
      
      // Get hints remaining
      final hintsRemaining = _quizHintsRemaining.containsKey(event.quizId)
          ? _quizHintsRemaining[event.quizId]!
          : 0;
      
      // Emit quiz paused state
      emit(QuizPaused(
        quiz: quiz,
        elapsedTimeSeconds: event.elapsedTimeSeconds,
        currentAnswers: currentAnswers,
        hintsRemaining: hintsRemaining,
      ));
      
      // Track pause event
      add(TrackQuizEvent(
        quizId: event.quizId,
        eventType: 'quiz_paused',
        eventData: {
          'elapsedTimeSeconds': event.elapsedTimeSeconds,
          'answeredQuestions': currentAnswers.where((a) => 
            a.selectedOptionIds.isNotEmpty || a.textAnswer.isNotEmpty).length,
        },
      ));
    } catch (e, stackTrace) {
      _logger.e('Error pausing quiz', error: e, stackTrace: stackTrace);
      emit(QuizError(message: 'Failed to pause quiz: ${e.toString()}', error: e));
    }
  }
  
  Future<void> _onResumeQuiz(
    ResumeQuiz event,
    Emitter<QuizState> emit,
  ) async {
    try {
      // Find the quiz
      final quizIndex = _allQuizzes.indexWhere((q) => q.id == event.quizId);
      
      if (quizIndex == -1) {
        emit(QuizError(message: 'Quiz not found'));
        return;
      }
      
      final quiz = _allQuizzes[quizIndex];
      
      // Get elapsed time
      final elapsedTimeSeconds = _quizElapsedTimes.containsKey(event.quizId)
          ? _quizElapsedTimes[event.quizId]!
          : 0;
      
      // Get current answers
      final currentAnswers = _currentQuizAnswers.containsKey(event.quizId)
          ? _currentQuizAnswers[event.quizId]!
          : [];
      
      // Get hints remaining
      final hintsRemaining = _quizHintsRemaining.containsKey(event.quizId)
          ? _quizHintsRemaining[event.quizId]!
          : 0;
      
      // Emit quiz resumed state
      emit(QuizResumed(
        quiz: quiz,
        elapsedTimeSeconds: elapsedTimeSeconds,
        currentAnswers: currentAnswers,
        hintsRemaining: hintsRemaining,
        resumeTime: DateTime.now(),
      ));
      
      // Track resume event
      add(TrackQuizEvent(
        quizId: event.quizId,
        eventType: 'quiz_resumed',
        eventData: {
          'elapsedTimeSeconds': elapsedTimeSeconds,
          'answeredQuestions': currentAnswers.where((a) => 
            a.selectedOptionIds.isNotEmpty || a.textAnswer.isNotEmpty).length,
        },
      ));
    } catch (e, stackTrace) {
      _logger.e('Error resuming quiz', error: e, stackTrace: stackTrace);
      emit(QuizError(message: 'Failed to resume quiz: ${e.toString()}', error: e));
    }
  }
  
  Future<void> _onAbandonQuiz(
    AbandonQuiz event,
    Emitter<QuizState> emit,
  ) async {
    try {
      // Clean up in-memory state for this quiz
      _currentQuizAnswers.remove(event.quizId);
      _quizElapsedTimes.remove(event.quizId);
      _quizHintsRemaining.remove(event.quizId);
      
      // Emit quiz abandoned state
      emit(QuizAbandoned(
        quizId: event.quizId,
        abandonTime: DateTime.now(),
      ));
      
      // Track abandon event
      add(TrackQuizEvent(
        quizId: event.quizId,
        eventType: 'quiz_abandoned',
        eventData: {
          'timestamp': DateTime.now().toIso8601String(),
        },
      ));
    } catch (e, stackTrace) {
      _logger.e('Error abandoning quiz', error: e, stackTrace: stackTrace);
      emit(QuizError(message: 'Failed to abandon quiz: ${e.toString()}', error: e));
    }
  }
  
  Future<void> _onLoadQuizAttempts(
    LoadQuizAttempts event,
    Emitter<QuizState> emit,
  ) async {
    try {
      emit(QuizLoading());
      
      // Filter attempts by quiz ID and/or user ID
      List<QuizAttempt> filteredAttempts = _allAttempts;
      
      if (event.quizId != null) {
        filteredAttempts = filteredAttempts
            .where((a) => a.quizId == event.quizId)
            .toList();
      }
      
      if (event.userId != null) {
        filteredAttempts = filteredAttempts
            .where((a) => a.userId == event.userId)
            .toList();
      }
      
      // Sort by completion date (newest first)
      filteredAttempts.sort((a, b) => b.completedAt.compareTo(a.completedAt));
      
      emit(QuizAttemptsLoaded(
        attempts: filteredAttempts,
        quizId: event.quizId,
        userId: event.userId,
      ));
    } catch (e, stackTrace) {
      _logger.e('Error loading quiz attempts', error: e, stackTrace: stackTrace);
      emit(QuizError(message: 'Failed to load attempts: ${e.toString()}', error: e));
    }
  }
  
  Future<void> _onLoadQuizAnalytics(
    LoadQuizAnalytics event,
    Emitter<QuizState> emit,
  ) async {
    try {
      emit(QuizLoading());
      
      // Filter attempts by user ID
      List<QuizAttempt> userAttempts = _allAttempts
          .where((a) => a.userId == event.userId)
          .toList();
      
      // Further filter by date range if provided
      if (event.startDate != null) {
        userAttempts = userAttempts
            .where((a) => a.completedAt.isAfter(event.startDate!))
            .toList();
      }
      
      if (event.endDate != null) {
        userAttempts = userAttempts
            .where((a) => a.completedAt.isBefore(event.endDate!))
            .toList();
      }
      
      // Calculate analytics
      final totalQuizzesTaken = userAttempts.length;
      final totalQuizzesCompleted = userAttempts.length; // Assuming all attempts are completed
      
      // Calculate average score
      double averageScore = 0.0;
      if (totalQuizzesTaken > 0) {
        final totalScorePercentage = userAttempts.fold<double>(
          0.0,
          (sum, attempt) => sum + (attempt.score / attempt.maxScore),
        );
        averageScore = totalScorePercentage / totalQuizzesTaken;
      }
      
      // Calculate subject performance
      final subjectPerformance = <String, double>{};
      final subjectAttemptCounts = <String, int>{};
      
      for (final attempt in userAttempts) {
        // Find the quiz
        final quiz = _allQuizzes.firstWhere(
          (q) => q.id == attempt.quizId,
          orElse: () => Quiz(
            id: '',
            title: '',
            description: '',
            subject: 'unknown',
            gradeLevel: '',
            difficulty: QuizDifficulty.medium,
            timeLimit: 0,
            questions: [],
          ),
        );
        
        final subject = quiz.subject ?? 'unknown';
        
        if (!subjectPerformance.containsKey(subject)) {
          subjectPerformance[subject] = 0.0;
          subjectAttemptCounts[subject] = 0;
        }
        
        subjectPerformance[subject] = subjectPerformance[subject]! + (attempt.score / attempt.maxScore);
        subjectAttemptCounts[subject] = subjectAttemptCounts[subject]! + 1;
      }
      
      // Calculate average score per subject
      subjectPerformance.forEach((subject, totalScore) {
        final attemptCount = subjectAttemptCounts[subject] ?? 1;
        subjectPerformance[subject] = totalScore / attemptCount;
      });
      
      // Get recent attempts (last 10)
      final recentAttempts = userAttempts
          .take(10)
          .toList();
      
      // Calculate question type performance
      final questionTypePerformance = <String, int>{};
      final questionTypeTotal = <String, int>{};
      
      for (final attempt in userAttempts) {
        // Find the quiz
        final quiz = _allQuizzes.firstWhere(
          (q) => q.id == attempt.quizId,
          orElse: () => Quiz(
            id: '',
            title: '',
            description: '',
            subject: 'unknown',
            gradeLevel: '',
            difficulty: QuizDifficulty.medium,
            timeLimit: 0,
            questions: [],
          ),
        );
        
        // Analyze performance by question type
        for (int i = 0; i < quiz.questions.length; i++) {
          final question = quiz.questions[i];
          final answer = i < attempt.answers.length ? attempt.answers[i] : null;
          
          final questionType = question.type.toString();
          
          if (!questionTypeTotal.containsKey(questionType)) {
            questionTypeTotal[questionType] = 0;
            questionTypePerformance[questionType] = 0;
          }
          
          questionTypeTotal[questionType] = questionTypeTotal[questionType]! + 1;
          
          if (answer?.isCorrect ?? false) {
            questionTypePerformance[questionType] = questionTypePerformance[questionType]! + 1;
          }
        }
      }
      
      // Calculate percentage correct for each question type
      final questionTypePercentages = <String, int>{};
      questionTypeTotal.forEach((type, total) {
        final correct = questionTypePerformance[type] ?? 0;
        questionTypePercentages[type] = total > 0 ? ((correct / total) * 100).round() : 0;
      });
      
      emit(QuizAnalyticsLoaded(
        userId: event.userId,
        totalQuizzesTaken: totalQuizzesTaken,
        totalQuizzesCompleted: totalQuizzesCompleted,
        averageScore: averageScore,
        subjectPerformance: subjectPerformance,
        recentAttempts: recentAttempts,
        questionTypePerformance: questionTypePercentages,
      ));
    } catch (e, stackTrace) {
      _logger.e('Error loading quiz analytics', error: e, stackTrace: stackTrace);
      emit(QuizError(message: 'Failed to load analytics: ${e.toString()}', error: e));
    }
  }
  
  Future<void> _onTrackQuizEvent(
    TrackQuizEvent event,
    Emitter<QuizState> emit,
  ) async {
    try {
      // In a real app, this would send the event to an analytics service
      _logger.i('Quiz event tracked', error: {
        'quizId': event.quizId,
        'eventType': event.eventType,
        'eventData': event.eventData,
      });
      
      // For now, just log it
    } catch (e, stackTrace) {
      _logger.e('Error tracking quiz event', error: e, stackTrace: stackTrace);
      // Don't emit error state, just log it
    }
  }
  
  // Helper methods
  Future<void> _fetchQuizzes() async {
    // In a real app, we would fetch this from an API or local database
    // For now, use mock data
    
    final subjects = ['mathematics', 'english', 'science', 'history', 'geography', 'agriculture'];
    final gradeLevels = ['ecd', 'primary_1_3', 'primary_4_7', 'secondary_1_2', 'secondary_3_4'];
    
    // Create mock quizzes
    _allQuizzes = [];
    
    for (final subject in subjects) {
      for (final gradeLevel in gradeLevels) {
        // Create 3 quizzes per subject and grade level
        for (int i = 1; i <= 3; i++) {
          final quizId = '${subject}_${gradeLevel}_quiz_$i';
          
          final questions = _generateMockQuestions(subject, gradeLevel, i);
          
          _allQuizzes.add(Quiz(
            id: quizId,
            title: '${_getSubjectTitle(subject)} Quiz $i',
            description: 'Test your knowledge of ${_getSubjectTitle(subject)} for ${_getGradeLevelTitle(gradeLevel)} students.',
            subject: subject,
            gradeLevel: gradeLevel,
            difficulty: _getDifficultyForIndex(i),
            timeLimit: 30 * questions.length, // 30 seconds per question
            questions: questions,
            passingScore: 0.6, // 60% to pass
            allowRetryWrongAnswers: i < 3, // Allow retry for easier quizzes
            showFeedbackAfterEachQuestion: i < 3, // Show feedback for easier quizzes
            randomizeQuestionOrder: i == 3, // Randomize for hardest quiz
            createdAt: DateTime.now().subtract(Duration(days: 30 - i)),
            updatedAt: DateTime.now().subtract(Duration(days: 15 - i)),
          ));
        }
      }
    }
  }
  
  Future<void> _fetchQuizDetail(String quizId) async {
    // In a real app, we would fetch this from an API or local database
    // For now, just check if it exists in our mock data
    
    final quizIndex = _allQuizzes.indexWhere((q) => q.id == quizId);
    
    if (quizIndex == -1) {
      // If not found, create a mock quiz
      final parts = quizId.split('_');
      if (parts.length >= 3) {
        final subject = parts[0];
        final gradeLevel = parts[1];
        final quizNumber = int.tryParse(parts.last) ?? 1;
        
        final questions = _generateMockQuestions(subject, gradeLevel, quizNumber);
        
        final quiz = Quiz(
          id: quizId,
          title: '${_getSubjectTitle(subject)} Quiz $quizNumber',
          description: 'Test your knowledge of ${_getSubjectTitle(subject)} for ${_getGradeLevelTitle(gradeLevel)} students.',
          subject: subject,
          gradeLevel: gradeLevel,
          difficulty: _getDifficultyForIndex(quizNumber),
          timeLimit: 30 * questions.length, // 30 seconds per question
          questions: questions,
          passingScore: 0.6, // 60% to pass
          allowRetryWrongAnswers: quizNumber < 3, // Allow retry for easier quizzes
          showFeedbackAfterEachQuestion: quizNumber < 3, // Show feedback for easier quizzes
          randomizeQuestionOrder: quizNumber == 3, // Randomize for hardest quiz
          createdAt: DateTime.now().subtract(Duration(days: 30 - quizNumber)),
          updatedAt: DateTime.now().subtract(Duration(days: 15 - quizNumber)),
        );
        
        _allQuizzes.add(quiz);
      }
    }
  }
  
  List<QuizQuestion> _generateMockQuestions(String subject, String gradeLevel, int quizNumber) {
    final questions = <QuizQuestion>[];
    
    // Number of questions based on quiz number
    final questionCount = 5 + quizNumber * 2; // 7, 9, 11 questions
    
    for (int i = 1; i <= questionCount; i++) {
      final questionId = '${subject}_${gradeLevel}_quiz_${quizNumber}_q_$i';
      
      // Alternate question types
      final questionType = _getQuestionTypeForIndex(i);
      
      // Generate question based on type
      switch (questionType) {
        case QuestionType.multipleChoice:
          questions.add(_generateMultipleChoiceQuestion(questionId, subject, gradeLevel, i));
          break;
        case QuestionType.trueFalse:
          questions.add(_generateTrueFalseQuestion(questionId, subject, gradeLevel, i));
          break;
        case QuestionType.multipleAnswer:
          questions.add(_generateMultipleAnswerQuestion(questionId, subject, gradeLevel, i));
          break;
        case QuestionType.fillInBlank:
          questions.add(_generateFillInBlankQuestion(questionId, subject, gradeLevel, i));
          break;
        case QuestionType.matching:
          questions.add(_generateMatchingQuestion(questionId, subject, gradeLevel, i));
          break;
        case QuestionType.ordering:
          questions.add(_generateOrderingQuestion(questionId, subject, gradeLevel, i));
          break;
      }
    }
    
    return questions;
  }
  
  QuizQuestion _generateMultipleChoiceQuestion(String id, String subject, String gradeLevel, int index) {
    // Generate options
    final options = <QuizOption>[];
    final correctOptionId = '${id}_option_1';
    
    // Create 4 options
    for (int i = 1; i <= 4; i++) {
      options.add(QuizOption(
        id: '${id}_option_$i',
        text: 'Option $i for ${_getSubjectTitle(subject)} question $index',
      ));
    }
    
    return QuizQuestion(
      id: id,
      text: 'Multiple choice question $index for ${_getSubjectTitle(subject)}',
      type: QuestionType.multipleChoice,
      options: options,
      correctOptionIds: [correctOptionId],
      points: 1,
      subject: subject,
      correctFeedback: 'Well done! You selected the correct answer.',
      incorrectFeedback: 'Not quite right. Try again!',
    );
  }
  
  QuizQuestion _generateTrueFalseQuestion(String id, String subject, String gradeLevel, int index) {
    // Generate true/false options
    final options = <QuizOption>[
      QuizOption(id: '${id}_true', text: 'True'),
      QuizOption(id: '${id}_false', text: 'False'),
    ];
    
    // Randomly select correct answer
    final isTrue = math.Random().nextBool();
    final correctOptionId = isTrue ? '${id}_true' : '${id}_false';
    
    return QuizQuestion(
      id: id,
      text: 'True or False: This is statement $index about ${_getSubjectTitle(subject)}',
      type: QuestionType.trueFalse,
      options: options,
      correctOptionIds: [correctOptionId],
      points: 1,
      subject: subject,
      correctFeedback: 'Correct! The statement is ${isTrue ? 'true' : 'false'}.',
      incorrectFeedback: 'Incorrect. The statement is ${isTrue ? 'true' : 'false'}.',
    );
  }
  
  QuizQuestion _generateMultipleAnswerQuestion(String id, String subject, String gradeLevel, int index) {
    // Generate options
    final options = <QuizOption>[];
    final correctOptionIds = <String>[];
    
    // Create 5 options, with 2-3 correct answers
    for (int i = 1; i <= 5; i++) {
      final optionId = '${id}_option_$i';
      options.add(QuizOption(
        id: optionId,
        text: 'Option $i for ${_getSubjectTitle(subject)} question $index',
      ));
      
      // Make 2-3 options correct
      if (i <= 2 || (i == 3 && math.Random().nextBool())) {
        correctOptionIds.add(optionId);
      }
    }
    
    return QuizQuestion(
      id: id,
      text: 'Select all that apply for ${_getSubjectTitle(subject)} question $index',
      type: QuestionType.multipleAnswer,
      options: options,
      correctOptionIds: correctOptionIds,
      points: 2, // Worth more points
      subject: subject,
      correctFeedback: 'Perfect! You selected all the correct answers.',
      incorrectFeedback: 'Some selections are incorrect. Please try again.',
    );
  }
  
  QuizQuestion _generateFillInBlankQuestion(String id, String subject, String gradeLevel, int index) {
    // Generate a correct answer
    final correctAnswer = '${_getSubjectTitle(subject)} answer $index';
    
    return QuizQuestion(
      id: id,
      text: 'Fill in the blank: The correct answer for ${_getSubjectTitle(subject)} question $index is _____.',
      type: QuestionType.fillInBlank,
      options: [], // No options for fill in the blank
      correctAnswer: correctAnswer,
      points: 2, // Worth more points
      subject: subject,
      correctFeedback: 'Excellent! The correct answer is "$correctAnswer".',
      incorrectFeedback: 'Not correct. The answer should be "$correctAnswer".',
    );
  }
  
  QuizQuestion _generateMatchingQuestion(String id, String subject, String gradeLevel, int index) {
    // Generate matching pairs
    final options = <QuizOption>[];
    final matchingPairs = <Map<String, String>>[];
    
    // Create 4 matching pairs
    for (int i = 1; i <= 4; i++) {
      final itemId = '${id}_item_$i';
      final matchId = '${id}_match_$i';
      
      options.add(QuizOption(
        id: itemId,
        text: 'Item $i for ${_getSubjectTitle(subject)}',
      ));
      
      options.add(QuizOption(
        id: matchId,
        text: 'Match $i for ${_getSubjectTitle(subject)}',
      ));
      
      matchingPairs.add({
        'itemId': itemId,
        'matchId': matchId,
      });
    }
    
    return QuizQuestion(
      id: id,
      text: 'Match the following items for ${_getSubjectTitle(subject)} question $index',
      type: QuestionType.matching,
      options: options,
      matchingPairs: matchingPairs,
      points: 3, // Worth more points
      subject: subject,
      correctFeedback: 'Great job! All items are correctly matched.',
      incorrectFeedback: 'Some matches are incorrect. Please try again.',
    );
  }
  
  QuizQuestion _generateOrderingQuestion(String id, String subject, String gradeLevel, int index) {
    // Generate items to order
    final options = <QuizOption>[];
    final correctOrder = <String>[];
    
    // Create 4 items to order
    for (int i = 1; i <= 4; i++) {
      final itemId = '${id}_item_$i';
      
      options.add(QuizOption(
        id: itemId,
        text: 'Item $i for ${_getSubjectTitle(subject)}',
      ));
      
      correctOrder.add(itemId);
    }
    
    return QuizQuestion(
      id: id,
      text: 'Arrange the following items in the correct order for ${_getSubjectTitle(subject)} question $index',
      type: QuestionType.ordering,
      options: options,
      correctOrder: correctOrder,
      points: 3, // Worth more points
      subject: subject,
      correctFeedback: 'Perfect! The items are in the correct order.',
      incorrectFeedback: 'The order is not correct. Please try again.',
    );
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
  
  QuizDifficulty _getDifficultyForIndex(int index) {
    switch (index) {
      case 1:
        return QuizDifficulty.easy;
      case 2:
        return QuizDifficulty.medium;
      case 3:
        return QuizDifficulty.hard;
      default:
        return QuizDifficulty.medium;
    }
  }
  
  QuestionType _getQuestionTypeForIndex(int index) {
    switch (index % 6) {
      case 0:
        return QuestionType.multipleChoice;
      case 1:
        return QuestionType.trueFalse;
      case 2:
        return QuestionType.multipleAnswer;
      case 3:
        return QuestionType.fillInBlank;
      case 4:
        return QuestionType.matching;
      case 5:
        return QuestionType.ordering;
      default:
        return QuestionType.multipleChoice;
    }
  }
  
  // HydratedBloc methods
  @override
  QuizState? fromJson(Map<String, dynamic> json) {
    try {
      // Deserialize quizzes
      final quizzes = (json['quizzes'] as List?)
          ?.map((e) => Quiz.fromJson(e as Map<String, dynamic>))
          .toList() ?? [];
      
      // Deserialize attempts
      final attempts = (json['attempts'] as List?)
          ?.map((e) => QuizAttempt.fromJson(e as Map<String, dynamic>))
          .toList() ?? [];
      
      // Update in-memory cache
      _allQuizzes = quizzes;
      _allAttempts = attempts;
      
      // Return the appropriate state
      final currentState = json['currentState'] as String?;
      
      switch (currentState) {
        case 'quizzesLoaded':
          return QuizzesLoaded(
            quizzes: quizzes,
            hasReachedMax: json['hasReachedMax'] as bool? ?? true,
            filterSubject: json['filterSubject'] as String?,
            filterGradeLevel: json['filterGradeLevel'] as String?,
          );
        case 'quizDetailLoaded':
          final quizId = json['currentQuizId'] as String?;
          if (quizId == null) return QuizInitial();
          
          final quizIndex = quizzes.indexWhere((q) => q.id == quizId);
          if (quizIndex == -1) return QuizInitial();
          
          final quiz = quizzes[quizIndex];
          
          final quizAttempts = attempts
              .where((a) => a.quizId == quizId)
              .toList();
          
          return QuizDetailLoaded(
            quiz: quiz,
            attempts: quizAttempts,
            isCompleted: json['isCompleted'] as bool? ?? false,
            bestScore: (json['bestScore'] as num?)?.toDouble() ?? 0.0,
          );
        default:
          return QuizInitial();
      }
    } catch (e, stackTrace) {
      _logger.e('Error deserializing quiz state', error: e, stackTrace: stackTrace);
      return QuizInitial();
    }
  }
  
  @override
  Map<String, dynamic>? toJson(QuizState state) {
    try {
      final Map<String, dynamic> json = {
        'quizzes': _allQuizzes.map((q) => q.toJson()).toList(),
        'attempts': _allAttempts.map((a) => a.toJson()).toList(),
      };
      
      if (state is QuizzesLoaded) {
        json['currentState'] = 'quizzesLoaded';
        json['hasReachedMax'] = state.hasReachedMax;
        json['filterSubject'] = state.filterSubject;
        json['filterGradeLevel'] = state.filterGradeLevel;
      } else if (state is QuizDetailLoaded) {
        json['currentState'] = 'quizDetailLoaded';
        json['currentQuizId'] = state.quiz.id;
        json['isCompleted'] = state.isCompleted;
        json['bestScore'] = state.bestScore;
      }
      
      return json;
    } catch (e, stackTrace) {
      _logger.e('Error serializing quiz state', error: e, stackTrace: stackTrace);
      return null;
    }
  }
}
