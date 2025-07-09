import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'quiz.g.dart';

@HiveType(typeId: 7)
class Quiz extends Equatable {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String title;
  
  @HiveField(2)
  final String description;
  
  @HiveField(3)
  final String subjectId;
  
  @HiveField(4)
  final String gradeLevel;
  
  @HiveField(5)
  final List<QuizQuestion> questions;
  
  @HiveField(6)
  final int timeLimit; // in minutes
  
  @HiveField(7)
  final int maxAttempts;
  
  @HiveField(8)
  final double passingScore;
  
  @HiveField(9)
  final QuizType type;
  
  @HiveField(10)
  final bool isRandomized;
  
  @HiveField(11)
  final String? thumbnailUrl;
  
  @HiveField(12)
  final bool isPremium;
  
  @HiveField(13)
  final DateTime createdAt;
  
  @HiveField(14)
  final DateTime updatedAt;

  const Quiz({
    required this.id,
    required this.title,
    required this.description,
    required this.subjectId,
    required this.gradeLevel,
    required this.questions,
    required this.timeLimit,
    this.maxAttempts = 3,
    this.passingScore = 0.6,
    required this.type,
    this.isRandomized = false,
    this.thumbnailUrl,
    this.isPremium = false,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        subjectId,
        gradeLevel,
        questions,
        timeLimit,
        maxAttempts,
        passingScore,
        type,
        isRandomized,
        thumbnailUrl,
        isPremium,
        createdAt,
        updatedAt,
      ];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'subjectId': subjectId,
      'gradeLevel': gradeLevel,
      'questions': questions.map((q) => q.toJson()).toList(),
      'timeLimit': timeLimit,
      'maxAttempts': maxAttempts,
      'passingScore': passingScore,
      'type': type.name,
      'isRandomized': isRandomized,
      'thumbnailUrl': thumbnailUrl,
      'isPremium': isPremium,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      subjectId: json['subjectId'],
      gradeLevel: json['gradeLevel'],
      questions: (json['questions'] as List)
          .map((q) => QuizQuestion.fromJson(q))
          .toList(),
      timeLimit: json['timeLimit'],
      maxAttempts: json['maxAttempts'] ?? 3,
      passingScore: (json['passingScore'] ?? 0.6).toDouble(),
      type: QuizType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => QuizType.practice,
      ),
      isRandomized: json['isRandomized'] ?? false,
      thumbnailUrl: json['thumbnailUrl'],
      isPremium: json['isPremium'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  int get totalQuestions => questions.length;
  int get totalPoints => questions.fold(0, (sum, q) => sum + q.points);
}

@HiveType(typeId: 8)
enum QuizType {
  @HiveField(0)
  practice,
  @HiveField(1)
  assessment,
  @HiveField(2)
  challenge,
  @HiveField(3)
  game,
}

@HiveType(typeId: 9)
class QuizQuestion extends Equatable {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String question;
  
  @HiveField(2)
  final QuestionType type;
  
  @HiveField(3)
  final List<QuizOption> options;
  
  @HiveField(4)
  final List<String> correctAnswers;
  
  @HiveField(5)
  final int points;
  
  @HiveField(6)
  final String? explanation;
  
  @HiveField(7)
  final String? imageUrl;
  
  @HiveField(8)
  final String? audioUrl;
  
  @HiveField(9)
  final Map<String, dynamic>? metadata;

  const QuizQuestion({
    required this.id,
    required this.question,
    required this.type,
    required this.options,
    required this.correctAnswers,
    this.points = 1,
    this.explanation,
    this.imageUrl,
    this.audioUrl,
    this.metadata,
  });

  @override
  List<Object?> get props => [
        id,
        question,
        type,
        options,
        correctAnswers,
        points,
        explanation,
        imageUrl,
        audioUrl,
        metadata,
      ];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'type': type.name,
      'options': options.map((o) => o.toJson()).toList(),
      'correctAnswers': correctAnswers,
      'points': points,
      'explanation': explanation,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
      'metadata': metadata,
    };
  }

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'],
      question: json['question'],
      type: QuestionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => QuestionType.multipleChoice,
      ),
      options: (json['options'] as List)
          .map((o) => QuizOption.fromJson(o))
          .toList(),
      correctAnswers: List<String>.from(json['correctAnswers']),
      points: json['points'] ?? 1,
      explanation: json['explanation'],
      imageUrl: json['imageUrl'],
      audioUrl: json['audioUrl'],
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
    );
  }
}

@HiveType(typeId: 10)
enum QuestionType {
  @HiveField(0)
  multipleChoice,
  @HiveField(1)
  trueFalse,
  @HiveField(2)
  fillInTheBlank,
  @HiveField(3)
  shortAnswer,
  @HiveField(4)
  matching,
  @HiveField(5)
  dragAndDrop,
  @HiveField(6)
  ordering,
}

@HiveType(typeId: 11)
class QuizOption extends Equatable {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String text;
  
  @HiveField(2)
  final String? imageUrl;
  
  @HiveField(3)
  final bool isCorrect;

  const QuizOption({
    required this.id,
    required this.text,
    this.imageUrl,
    required this.isCorrect,
  });

  @override
  List<Object?> get props => [id, text, imageUrl, isCorrect];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'imageUrl': imageUrl,
      'isCorrect': isCorrect,
    };
  }

  factory QuizOption.fromJson(Map<String, dynamic> json) {
    return QuizOption(
      id: json['id'],
      text: json['text'],
      imageUrl: json['imageUrl'],
      isCorrect: json['isCorrect'] ?? false,
    );
  }
}

@HiveType(typeId: 12)
class QuizAttempt extends Equatable {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String quizId;
  
  @HiveField(2)
  final String userId;
  
  @HiveField(3)
  final List<QuizAnswer> answers;
  
  @HiveField(4)
  final int score;
  
  @HiveField(5)
  final int totalPoints;
  
  @HiveField(6)
  final double percentage;
  
  @HiveField(7)
  final DateTime startedAt;
  
  @HiveField(8)
  final DateTime completedAt;
  
  @HiveField(9)
  final bool isPassed;

  const QuizAttempt({
    required this.id,
    required this.quizId,
    required this.userId,
    required this.answers,
    required this.score,
    required this.totalPoints,
    required this.percentage,
    required this.startedAt,
    required this.completedAt,
    required this.isPassed,
  });

  @override
  List<Object?> get props => [
        id,
        quizId,
        userId,
        answers,
        score,
        totalPoints,
        percentage,
        startedAt,
        completedAt,
        isPassed,
      ];

  Duration get duration => completedAt.difference(startedAt);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quizId': quizId,
      'userId': userId,
      'answers': answers.map((a) => a.toJson()).toList(),
      'score': score,
      'totalPoints': totalPoints,
      'percentage': percentage,
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt.toIso8601String(),
      'isPassed': isPassed,
    };
  }

  factory QuizAttempt.fromJson(Map<String, dynamic> json) {
    return QuizAttempt(
      id: json['id'],
      quizId: json['quizId'],
      userId: json['userId'],
      answers: (json['answers'] as List)
          .map((a) => QuizAnswer.fromJson(a))
          .toList(),
      score: json['score'],
      totalPoints: json['totalPoints'],
      percentage: (json['percentage'] ?? 0.0).toDouble(),
      startedAt: DateTime.parse(json['startedAt']),
      completedAt: DateTime.parse(json['completedAt']),
      isPassed: json['isPassed'] ?? false,
    );
  }
}

@HiveType(typeId: 13)
class QuizAnswer extends Equatable {
  @HiveField(0)
  final String questionId;
  
  @HiveField(1)
  final List<String> selectedAnswers;
  
  @HiveField(2)
  final bool isCorrect;
  
  @HiveField(3)
  final int pointsEarned;

  const QuizAnswer({
    required this.questionId,
    required this.selectedAnswers,
    required this.isCorrect,
    required this.pointsEarned,
  });

  @override
  List<Object?> get props => [questionId, selectedAnswers, isCorrect, pointsEarned];

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'selectedAnswers': selectedAnswers,
      'isCorrect': isCorrect,
      'pointsEarned': pointsEarned,
    };
  }

  factory QuizAnswer.fromJson(Map<String, dynamic> json) {
    return QuizAnswer(
      questionId: json['questionId'],
      selectedAnswers: List<String>.from(json['selectedAnswers']),
      isCorrect: json['isCorrect'] ?? false,
      pointsEarned: json['pointsEarned'] ?? 0,
    );
  }
}
