import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:logger/logger.dart';
import 'package:meta/meta.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../core/services/service_locator.dart';
import '../../../core/services/ai_tutor_service.dart';
import '../../../core/models/learning_style.dart';
import '../../../data/models/user.dart';

part 'ai_tutor_event.dart';
part 'ai_tutor_state.dart';

class AiTutorBloc extends HydratedBloc<AiTutorEvent, AiTutorState> {
  final AiTutorService _aiTutorService;
  final Logger _logger;
  final Connectivity _connectivity;
  
  // Stream subscriptions
  StreamSubscription? _messageSubscription;
  StreamSubscription? _studyPlanSubscription;
  StreamSubscription? _connectivitySubscription;
  
  // Connectivity status
  bool _isConnected = true;
  
  // Message queue for offline mode
  final List<Map<String, dynamic>> _offlineMessageQueue = [];
  
  AiTutorBloc({
    AiTutorService? aiTutorService,
    Logger? logger,
    Connectivity? connectivity,
  }) : 
    _aiTutorService = aiTutorService ?? sl<AiTutorService>(),
    _logger = logger ?? sl<Logger>(),
    _connectivity = connectivity ?? Connectivity(),
    super(AiTutorInitial()) {
    _initBloc();
  }
  
  void _initBloc() {
    // Register event handlers
    on<StartTutoringSession>(_onStartTutoringSession);
    on<EndTutoringSession>(_onEndTutoringSession);
    on<SendTutoringMessage>(_onSendTutoringMessage);
    on<GeneratePracticeQuestions>(_onGeneratePracticeQuestions);
    on<CreateStudyPlan>(_onCreateStudyPlan);
    on<UpdateLearningStyle>(_onUpdateLearningStyle);
    on<LoadSessionHistory>(_onLoadSessionHistory);
    on<LoadActiveSession>(_onLoadActiveSession);
    on<ProcessOfflineQueue>(_onProcessOfflineQueue);
    
    // Subscribe to message stream
    _messageSubscription = _aiTutorService.messageStream.listen((message) {
      // Update state when new message is received
      if (state is AiTutorActiveSession) {
        final currentSession = (state as AiTutorActiveSession).session;
        
        if (message.isFromTutor && currentSession.id == message.metadata?['sessionId']) {
          // Update session with new message
          final updatedMessages = List<TutoringMessage>.from(currentSession.messages)
            ..add(message);
          
          final updatedSession = TutoringSession(
            id: currentSession.id,
            userId: currentSession.userId,
            startTime: currentSession.startTime,
            endTime: currentSession.endTime,
            subject: currentSession.subject,
            lessonId: currentSession.lessonId,
            quizId: currentSession.quizId,
            messages: updatedMessages,
            personality: currentSession.personality,
            language: currentSession.language,
            learningStyle: currentSession.learningStyle,
          );
          
          // Emit updated state
          emit(AiTutorMessageSent(
            session: updatedSession,
            message: message,
          ));
        }
      }
    });
    
    // Subscribe to study plan stream
    _studyPlanSubscription = _aiTutorService.studyPlanStream.listen((studyPlan) {
      // Update state when study plan is created or updated
      emit(AiTutorStudyPlanCreated(studyPlan: studyPlan));
    });
    
    // Monitor connectivity
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((result) {
      _isConnected = result != ConnectivityResult.none;
      
      // Process offline queue when connection is restored
      if (_isConnected && _offlineMessageQueue.isNotEmpty) {
        add(ProcessOfflineQueue());
      }
    });
    
    // Check initial connectivity
    _connectivity.checkConnectivity().then((result) {
      _isConnected = result != ConnectivityResult.none;
    });
  }
  
  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    _studyPlanSubscription?.cancel();
    _connectivitySubscription?.cancel();
    return super.close();
  }
  
  Future<void> _onStartTutoringSession(
    StartTutoringSession event,
    Emitter<AiTutorState> emit,
  ) async {
    try {
      emit(AiTutorLoading());
      
      // Check connectivity
      if (!_isConnected) {
        emit(AiTutorError(
          message: 'Cannot start tutoring session while offline',
          code: 'connectivity_error',
        ));
        return;
      }
      
      // Start session
      final session = await _aiTutorService.startSession(
        userId: event.userId,
        subject: event.subject,
        lessonId: event.lessonId,
        quizId: event.quizId,
        personality: event.personality,
        language: event.language,
        learningStyle: event.learningStyle,
      );
      
      // Emit active session state
      emit(AiTutorActiveSession(session: session));
      
      _logger.i('Started tutoring session', error: {
        'sessionId': session.id,
        'subject': session.subject,
      });
    } catch (e, stackTrace) {
      _logger.e('Error starting tutoring session', 
          error: e, stackTrace: stackTrace);
      
      emit(AiTutorError(
        message: 'Failed to start tutoring session: ${e.toString()}',
        code: 'session_start_error',
      ));
    }
  }
  
  Future<void> _onEndTutoringSession(
    EndTutoringSession event,
    Emitter<AiTutorState> emit,
  ) async {
    try {
      emit(AiTutorLoading());
      
      // Check if we have an active session
      if (state is! AiTutorActiveSession && 
          state is! AiTutorMessageSent) {
        emit(AiTutorError(
          message: 'No active session to end',
          code: 'no_active_session',
        ));
        return;
      }
      
      // Get current session
      TutoringSession currentSession;
      if (state is AiTutorActiveSession) {
        currentSession = (state as AiTutorActiveSession).session;
      } else {
        currentSession = (state as AiTutorMessageSent).session;
      }
      
      // Check if session ID matches
      if (currentSession.id != event.sessionId) {
        emit(AiTutorError(
          message: 'Session ID mismatch',
          code: 'session_id_mismatch',
        ));
        return;
      }
      
      // Check connectivity
      if (!_isConnected) {
        // Add to offline queue
        _offlineMessageQueue.add({
          'type': 'end_session',
          'sessionId': event.sessionId,
        });
        
        // Update session locally
        final updatedSession = TutoringSession(
          id: currentSession.id,
          userId: currentSession.userId,
          startTime: currentSession.startTime,
          endTime: DateTime.now(),
          subject: currentSession.subject,
          lessonId: currentSession.lessonId,
          quizId: currentSession.quizId,
          messages: currentSession.messages,
          personality: currentSession.personality,
          language: currentSession.language,
          learningStyle: currentSession.learningStyle,
        );
        
        emit(AiTutorSessionEnded(session: updatedSession));
        return;
      }
      
      // End session
      await _aiTutorService.endSession(event.sessionId);
      
      // Get updated session
      final session = await _aiTutorService.getSession(event.sessionId);
      
      if (session == null) {
        emit(AiTutorError(
          message: 'Session not found after ending',
          code: 'session_not_found',
        ));
        return;
      }
      
      // Emit session ended state
      emit(AiTutorSessionEnded(session: session));
      
      _logger.i('Ended tutoring session', error: {
        'sessionId': session.id,
        'duration': session.endTime!.difference(session.startTime).inMinutes,
      });
    } catch (e, stackTrace) {
      _logger.e('Error ending tutoring session', 
          error: e, stackTrace: stackTrace);
      
      emit(AiTutorError(
        message: 'Failed to end tutoring session: ${e.toString()}',
        code: 'session_end_error',
      ));
    }
  }
  
  Future<void> _onSendTutoringMessage(
    SendTutoringMessage event,
    Emitter<AiTutorState> emit,
  ) async {
    try {
      // Check if we have an active session
      if (state is! AiTutorActiveSession && 
          state is! AiTutorMessageSent) {
        emit(AiTutorError(
          message: 'No active session to send message to',
          code: 'no_active_session',
        ));
        return;
      }
      
      // Get current session
      TutoringSession currentSession;
      if (state is AiTutorActiveSession) {
        currentSession = (state as AiTutorActiveSession).session;
      } else {
        currentSession = (state as AiTutorMessageSent).session;
      }
      
      // Check if session ID matches
      if (currentSession.id != event.sessionId) {
        emit(AiTutorError(
          message: 'Session ID mismatch',
          code: 'session_id_mismatch',
        ));
        return;
      }
      
      // Create user message
      final userMessage = TutoringMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        isFromTutor: false,
        content: event.content,
        timestamp: DateTime.now(),
        requestType: event.requestType,
        metadata: event.metadata ?? {
          'sessionId': event.sessionId,
        },
      );
      
      // Add user message to session
      final updatedMessages = List<TutoringMessage>.from(currentSession.messages)
        ..add(userMessage);
      
      final updatedSession = TutoringSession(
        id: currentSession.id,
        userId: currentSession.userId,
        startTime: currentSession.startTime,
        endTime: currentSession.endTime,
        subject: currentSession.subject,
        lessonId: currentSession.lessonId,
        quizId: currentSession.quizId,
        messages: updatedMessages,
        personality: currentSession.personality,
        language: currentSession.language,
        learningStyle: currentSession.learningStyle,
      );
      
      // Emit updated state with user message
      emit(AiTutorMessageSent(
        session: updatedSession,
        message: userMessage,
      ));
      
      // Check connectivity
      if (!_isConnected) {
        // Add to offline queue
        _offlineMessageQueue.add({
          'type': 'send_message',
          'sessionId': event.sessionId,
          'content': event.content,
          'requestType': event.requestType.toString(),
          'metadata': event.metadata,
          'messageId': userMessage.id,
        });
        
        // Show offline message
        final offlineMessage = TutoringMessage(
          id: 'offline_${DateTime.now().millisecondsSinceEpoch}',
          isFromTutor: true,
          content: 'You are currently offline. Your message will be sent when you reconnect.',
          timestamp: DateTime.now(),
          metadata: {
            'isOfflineMessage': true,
            'sessionId': event.sessionId,
          },
        );
        
        final offlineUpdatedMessages = List<TutoringMessage>.from(updatedMessages)
          ..add(offlineMessage);
        
        final offlineUpdatedSession = TutoringSession(
          id: updatedSession.id,
          userId: updatedSession.userId,
          startTime: updatedSession.startTime,
          endTime: updatedSession.endTime,
          subject: updatedSession.subject,
          lessonId: updatedSession.lessonId,
          quizId: updatedSession.quizId,
          messages: offlineUpdatedMessages,
          personality: updatedSession.personality,
          language: updatedSession.language,
          learningStyle: updatedSession.learningStyle,
        );
        
        emit(AiTutorMessageSent(
          session: offlineUpdatedSession,
          message: offlineMessage,
        ));
        
        return;
      }
      
      // Send message to AI tutor
      final aiResponse = await _aiTutorService.sendMessage(
        sessionId: event.sessionId,
        content: event.content,
        requestType: event.requestType,
        metadata: event.metadata,
      );
      
      // Add AI response to session
      final finalMessages = List<TutoringMessage>.from(updatedMessages)
        ..add(aiResponse);
      
      final finalSession = TutoringSession(
        id: updatedSession.id,
        userId: updatedSession.userId,
        startTime: updatedSession.startTime,
        endTime: updatedSession.endTime,
        subject: updatedSession.subject,
        lessonId: updatedSession.lessonId,
        quizId: updatedSession.quizId,
        messages: finalMessages,
        personality: updatedSession.personality,
        language: updatedSession.language,
        learningStyle: updatedSession.learningStyle,
      );
      
      // Emit updated state with AI response
      emit(AiTutorMessageSent(
        session: finalSession,
        message: aiResponse,
      ));
      
      _logger.i('Sent message to AI tutor', error: {
        'sessionId': event.sessionId,
        'requestType': event.requestType.toString(),
      });
    } catch (e, stackTrace) {
      _logger.e('Error sending message to AI tutor', 
          error: e, stackTrace: stackTrace);
      
      emit(AiTutorError(
        message: 'Failed to send message: ${e.toString()}',
        code: 'message_send_error',
      ));
    }
  }
  
  Future<void> _onGeneratePracticeQuestions(
    GeneratePracticeQuestions event,
    Emitter<AiTutorState> emit,
  ) async {
    try {
      emit(AiTutorLoading());
      
      // Check connectivity
      if (!_isConnected) {
        emit(AiTutorError(
          message: 'Cannot generate practice questions while offline',
          code: 'connectivity_error',
        ));
        return;
      }
      
      // Generate practice questions
      final questions = await _aiTutorService.generatePracticeQuestions(
        subject: event.subject,
        topic: event.topic,
        difficulty: event.difficulty,
        count: event.count,
        gradeLevel: event.gradeLevel,
      );
      
      // Emit practice questions generated state
      emit(AiTutorPracticeQuestionsGenerated(
        questions: questions,
        subject: event.subject,
        topic: event.topic,
      ));
      
      _logger.i('Generated practice questions', error: {
        'subject': event.subject,
        'topic': event.topic,
        'count': event.count,
      });
    } catch (e, stackTrace) {
      _logger.e('Error generating practice questions', 
          error: e, stackTrace: stackTrace);
      
      emit(AiTutorError(
        message: 'Failed to generate practice questions: ${e.toString()}',
        code: 'practice_questions_error',
      ));
    }
  }
  
  Future<void> _onCreateStudyPlan(
    CreateStudyPlan event,
    Emitter<AiTutorState> emit,
  ) async {
    try {
      emit(AiTutorLoading());
      
      // Check connectivity
      if (!_isConnected) {
        emit(AiTutorError(
          message: 'Cannot create study plan while offline',
          code: 'connectivity_error',
        ));
        return;
      }
      
      // Create study plan
      final studyPlan = await _aiTutorService.createStudyPlan(
        userId: event.userId,
        startDate: event.startDate,
        endDate: event.endDate,
        subjectDistribution: event.subjectDistribution,
        user: event.user,
        title: event.title,
        description: event.description,
      );
      
      // Emit study plan created state
      emit(AiTutorStudyPlanCreated(studyPlan: studyPlan));
      
      _logger.i('Created study plan', error: {
        'userId': event.userId,
        'planId': studyPlan.id,
      });
    } catch (e, stackTrace) {
      _logger.e('Error creating study plan', 
          error: e, stackTrace: stackTrace);
      
      emit(AiTutorError(
        message: 'Failed to create study plan: ${e.toString()}',
        code: 'study_plan_error',
      ));
    }
  }
  
  Future<void> _onUpdateLearningStyle(
    UpdateLearningStyle event,
    Emitter<AiTutorState> emit,
  ) async {
    try {
      emit(AiTutorLoading());
      
      // Update learning style
      await _aiTutorService.updateLearningStyle(
        userId: event.userId,
        learningStyle: event.learningStyle,
      );
      
      // If we have an active session, update it
      if (state is AiTutorActiveSession) {
        final currentSession = (state as AiTutorActiveSession).session;
        
        final updatedSession = TutoringSession(
          id: currentSession.id,
          userId: currentSession.userId,
          startTime: currentSession.startTime,
          endTime: currentSession.endTime,
          subject: currentSession.subject,
          lessonId: currentSession.lessonId,
          quizId: currentSession.quizId,
          messages: currentSession.messages,
          personality: currentSession.personality,
          language: currentSession.language,
          learningStyle: event.learningStyle,
        );
        
        emit(AiTutorActiveSession(session: updatedSession));
      } else if (state is AiTutorMessageSent) {
        final currentSession = (state as AiTutorMessageSent).session;
        
        final updatedSession = TutoringSession(
          id: currentSession.id,
          userId: currentSession.userId,
          startTime: currentSession.startTime,
          endTime: currentSession.endTime,
          subject: currentSession.subject,
          lessonId: currentSession.lessonId,
          quizId: currentSession.quizId,
          messages: currentSession.messages,
          personality: currentSession.personality,
          language: currentSession.language,
          learningStyle: event.learningStyle,
        );
        
        emit(AiTutorMessageSent(
          session: updatedSession,
          message: currentSession.messages.last,
        ));
      } else {
        emit(AiTutorLearningStyleUpdated(
          userId: event.userId,
          learningStyle: event.learningStyle,
        ));
      }
      
      _logger.i('Updated learning style', error: {
        'userId': event.userId,
      });
    } catch (e, stackTrace) {
      _logger.e('Error updating learning style', 
          error: e, stackTrace: stackTrace);
      
      emit(AiTutorError(
        message: 'Failed to update learning style: ${e.toString()}',
        code: 'learning_style_error',
      ));
    }
  }
  
  Future<void> _onLoadSessionHistory(
    LoadSessionHistory event,
    Emitter<AiTutorState> emit,
  ) async {
    try {
      emit(AiTutorLoading());
      
      // Load session history
      final sessions = await _aiTutorService.getSessionHistory(event.userId);
      
      // Emit session history loaded state
      emit(AiTutorSessionHistoryLoaded(
        userId: event.userId,
        sessions: sessions,
      ));
      
      _logger.i('Loaded session history', error: {
        'userId': event.userId,
        'sessionCount': sessions.length,
      });
    } catch (e, stackTrace) {
      _logger.e('Error loading session history', 
          error: e, stackTrace: stackTrace);
      
      emit(AiTutorError(
        message: 'Failed to load session history: ${e.toString()}',
        code: 'session_history_error',
      ));
    }
  }
  
  Future<void> _onLoadActiveSession(
    LoadActiveSession event,
    Emitter<AiTutorState> emit,
  ) async {
    try {
      emit(AiTutorLoading());
      
      // Load active session
      final session = await _aiTutorService.getActiveSession(event.userId);
      
      if (session == null) {
        emit(AiTutorInitial());
        return;
      }
      
      // Emit active session state
      emit(AiTutorActiveSession(session: session));
      
      _logger.i('Loaded active session', error: {
        'userId': event.userId,
        'sessionId': session.id,
      });
    } catch (e, stackTrace) {
      _logger.e('Error loading active session', 
          error: e, stackTrace: stackTrace);
      
      emit(AiTutorError(
        message: 'Failed to load active session: ${e.toString()}',
        code: 'active_session_error',
      ));
    }
  }
  
  Future<void> _onProcessOfflineQueue(
    ProcessOfflineQueue event,
    Emitter<AiTutorState> emit,
  ) async {
    try {
      if (_offlineMessageQueue.isEmpty) {
        return;
      }
      
      // Process each item in the queue
      for (final item in List<Map<String, dynamic>>.from(_offlineMessageQueue)) {
        final type = item['type'] as String;
        
        if (type == 'send_message') {
          // Send message
          final sessionId = item['sessionId'] as String;
          final content = item['content'] as String;
          final requestTypeStr = item['requestType'] as String;
          final metadata = item['metadata'] as Map<String, dynamic>?;
          
          // Convert request type string to enum
          final requestType = TutorRequestType.values.firstWhere(
            (e) => e.toString() == requestTypeStr,
            orElse: () => TutorRequestType.quickQuestion,
          );
          
          // Send message
          await _aiTutorService.sendMessage(
            sessionId: sessionId,
            content: content,
            requestType: requestType,
            metadata: metadata,
          );
        } else if (type == 'end_session') {
          // End session
          final sessionId = item['sessionId'] as String;
          
          // End session
          await _aiTutorService.endSession(sessionId);
        }
        
        // Remove item from queue
        _offlineMessageQueue.remove(item);
      }
      
      // Load active session
      if (state is AiTutorActiveSession) {
        final currentSession = (state as AiTutorActiveSession).session;
        
        // Reload session
        final session = await _aiTutorService.getSession(currentSession.id);
        
        if (session != null) {
          emit(AiTutorActiveSession(session: session));
        }
      }
      
      _logger.i('Processed offline queue', error: {
        'queueSize': _offlineMessageQueue.length,
      });
    } catch (e, stackTrace) {
      _logger.e('Error processing offline queue', 
          error: e, stackTrace: stackTrace);
      
      // Don't emit error state, just log it
    }
  }
  
  @override
  AiTutorState? fromJson(Map<String, dynamic> json) {
    try {
      final stateType = json['stateType'] as String?;
      
      if (stateType == null) {
        return AiTutorInitial();
      }
      
      switch (stateType) {
        case 'AiTutorActiveSession':
          final sessionJson = json['session'] as Map<String, dynamic>;
          return AiTutorActiveSession(
            session: TutoringSession.fromJson(sessionJson),
          );
        
        case 'AiTutorSessionEnded':
          final sessionJson = json['session'] as Map<String, dynamic>;
          return AiTutorSessionEnded(
            session: TutoringSession.fromJson(sessionJson),
          );
        
        case 'AiTutorSessionHistoryLoaded':
          final userId = json['userId'] as String;
          final sessionsJson = json['sessions'] as List<dynamic>;
          final sessions = sessionsJson
              .map((s) => TutoringSession.fromJson(s as Map<String, dynamic>))
              .toList();
          
          return AiTutorSessionHistoryLoaded(
            userId: userId,
            sessions: sessions,
          );
        
        default:
          return AiTutorInitial();
      }
    } catch (e, stackTrace) {
      _logger.e('Error deserializing AI tutor state', 
          error: e, stackTrace: stackTrace);
      return AiTutorInitial();
    }
  }
  
  @override
  Map<String, dynamic>? toJson(AiTutorState state) {
    try {
      if (state is AiTutorActiveSession) {
        return {
          'stateType': 'AiTutorActiveSession',
          'session': state.session.toJson(),
        };
      } else if (state is AiTutorSessionEnded) {
        return {
          'stateType': 'AiTutorSessionEnded',
          'session': state.session.toJson(),
        };
      } else if (state is AiTutorSessionHistoryLoaded) {
        return {
          'stateType': 'AiTutorSessionHistoryLoaded',
          'userId': state.userId,
          'sessions': state.sessions.map((s) => s.toJson()).toList(),
        };
      }
      
      return null;
    } catch (e, stackTrace) {
      _logger.e('Error serializing AI tutor state', 
          error: e, stackTrace: stackTrace);
      return null;
    }
  }
}

part 'ai_tutor_event.dart';
part 'ai_tutor_state.dart';
