part of 'ai_tutor_bloc.dart';

@immutable
abstract class AiTutorEvent extends Equatable {
  const AiTutorEvent();

  @override
  List<Object?> get props => [];
}

/// Event to start a new tutoring session
class StartTutoringSession extends AiTutorEvent {
  final String userId;
  final String subject;
  final String? lessonId;
  final String? quizId;
  final TutorPersonality personality;
  final String language;
  final LearningStyle? learningStyle;

  const StartTutoringSession({
    required this.userId,
    required this.subject,
    this.lessonId,
    this.quizId,
    this.personality = TutorPersonality.encouraging,
    this.language = 'en',
    this.learningStyle,
  });

  @override
  List<Object?> get props => [
        userId,
        subject,
        lessonId,
        quizId,
        personality,
        language,
        learningStyle,
      ];
}

/// Event to end an active tutoring session
class EndTutoringSession extends AiTutorEvent {
  final String sessionId;

  const EndTutoringSession({
    required this.sessionId,
  });

  @override
  List<Object?> get props => [sessionId];
}

/// Event to send a message to the AI tutor
class SendTutoringMessage extends AiTutorEvent {
  final String sessionId;
  final String content;
  final TutorRequestType requestType;
  final Map<String, dynamic>? metadata;

  const SendTutoringMessage({
    required this.sessionId,
    required this.content,
    this.requestType = TutorRequestType.quickQuestion,
    this.metadata,
  });

  @override
  List<Object?> get props => [
        sessionId,
        content,
        requestType,
        metadata,
      ];
}

/// Event to generate practice questions
class GeneratePracticeQuestions extends AiTutorEvent {
  final String subject;
  final String topic;
  final String difficulty;
  final int count;
  final String gradeLevel;

  const GeneratePracticeQuestions({
    required this.subject,
    required this.topic,
    this.difficulty = 'medium',
    this.count = 5,
    required this.gradeLevel,
  });

  @override
  List<Object?> get props => [
        subject,
        topic,
        difficulty,
        count,
        gradeLevel,
      ];
}

/// Event to create a study plan
class CreateStudyPlan extends AiTutorEvent {
  final String userId;
  final DateTime startDate;
  final DateTime endDate;
  final Map<String, int> subjectDistribution;
  final User user;
  final String? title;
  final String? description;

  const CreateStudyPlan({
    required this.userId,
    required this.startDate,
    required this.endDate,
    required this.subjectDistribution,
    required this.user,
    this.title,
    this.description,
  });

  @override
  List<Object?> get props => [
        userId,
        startDate,
        endDate,
        subjectDistribution,
        user,
        title,
        description,
      ];
}

/// Event to update the user's learning style
class UpdateLearningStyle extends AiTutorEvent {
  final String userId;
  final LearningStyle learningStyle;

  const UpdateLearningStyle({
    required this.userId,
    required this.learningStyle,
  });

  @override
  List<Object?> get props => [
        userId,
        learningStyle,
      ];
}

/// Event to load the user's session history
class LoadSessionHistory extends AiTutorEvent {
  final String userId;

  const LoadSessionHistory({
    required this.userId,
  });

  @override
  List<Object?> get props => [userId];
}

/// Event to load an active session
class LoadActiveSession extends AiTutorEvent {
  final String userId;

  const LoadActiveSession({
    required this.userId,
  });

  @override
  List<Object?> get props => [userId];
}

/// Event to process the offline message queue
class ProcessOfflineQueue extends AiTutorEvent {
  const ProcessOfflineQueue();

  @override
  List<Object?> get props => [];
}
