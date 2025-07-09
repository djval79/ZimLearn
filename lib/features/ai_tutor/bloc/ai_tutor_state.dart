part of 'ai_tutor_bloc.dart';

@immutable
abstract class AiTutorState extends Equatable {
  const AiTutorState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class AiTutorInitial extends AiTutorState {}

/// Loading state for async operations
class AiTutorLoading extends AiTutorState {}

/// State when a tutoring session is active
class AiTutorActiveSession extends AiTutorState {
  final TutoringSession session;

  const AiTutorActiveSession({
    required this.session,
  });

  @override
  List<Object?> get props => [session];
}

/// State when a tutoring session has ended
class AiTutorSessionEnded extends AiTutorState {
  final TutoringSession session;

  const AiTutorSessionEnded({
    required this.session,
  });

  @override
  List<Object?> get props => [session];
}

/// State when a message has been sent
class AiTutorMessageSent extends AiTutorState {
  final TutoringSession session;
  final TutoringMessage message;

  const AiTutorMessageSent({
    required this.session,
    required this.message,
  });

  @override
  List<Object?> get props => [session, message];
}

/// State when practice questions have been generated
class AiTutorPracticeQuestionsGenerated extends AiTutorState {
  final List<PracticeQuestion> questions;
  final String subject;
  final String topic;

  const AiTutorPracticeQuestionsGenerated({
    required this.questions,
    required this.subject,
    required this.topic,
  });

  @override
  List<Object?> get props => [questions, subject, topic];
}

/// State when a study plan has been created
class AiTutorStudyPlanCreated extends AiTutorState {
  final StudyPlan studyPlan;

  const AiTutorStudyPlanCreated({
    required this.studyPlan,
  });

  @override
  List<Object?> get props => [studyPlan];
}

/// State when a learning style has been updated
class AiTutorLearningStyleUpdated extends AiTutorState {
  final String userId;
  final LearningStyle learningStyle;

  const AiTutorLearningStyleUpdated({
    required this.userId,
    required this.learningStyle,
  });

  @override
  List<Object?> get props => [userId, learningStyle];
}

/// State when session history has been loaded
class AiTutorSessionHistoryLoaded extends AiTutorState {
  final String userId;
  final List<TutoringSession> sessions;

  const AiTutorSessionHistoryLoaded({
    required this.userId,
    required this.sessions,
  });

  @override
  List<Object?> get props => [userId, sessions];
}

/// Error state
class AiTutorError extends AiTutorState {
  final String message;
  final String? code;
  final Object? error;

  const AiTutorError({
    required this.message,
    this.code,
    this.error,
  });

  @override
  List<Object?> get props => [message, code, error];
}
