import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'lesson.g.dart';

@HiveType(typeId: 3)
class Lesson extends Equatable {
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
  final int orderIndex;
  
  @HiveField(6)
  final LessonType type;
  
  @HiveField(7)
  final List<LessonContent> content;
  
  @HiveField(8)
  final int estimatedDurationMinutes;
  
  @HiveField(9)
  final List<String> prerequisites;
  
  @HiveField(10)
  final List<String> learningObjectives;
  
  @HiveField(11)
  final List<String> keywords;
  
  @HiveField(12)
  final String? thumbnailUrl;
  
  @HiveField(13)
  final bool isOfflineAvailable;
  
  @HiveField(14)
  final bool isPremium;
  
  @HiveField(15)
  final DateTime createdAt;
  
  @HiveField(16)
  final DateTime updatedAt;

  const Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.subjectId,
    required this.gradeLevel,
    required this.orderIndex,
    required this.type,
    required this.content,
    required this.estimatedDurationMinutes,
    this.prerequisites = const [],
    this.learningObjectives = const [],
    this.keywords = const [],
    this.thumbnailUrl,
    this.isOfflineAvailable = false,
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
        orderIndex,
        type,
        content,
        estimatedDurationMinutes,
        prerequisites,
        learningObjectives,
        keywords,
        thumbnailUrl,
        isOfflineAvailable,
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
      'orderIndex': orderIndex,
      'type': type.name,
      'content': content.map((c) => c.toJson()).toList(),
      'estimatedDurationMinutes': estimatedDurationMinutes,
      'prerequisites': prerequisites,
      'learningObjectives': learningObjectives,
      'keywords': keywords,
      'thumbnailUrl': thumbnailUrl,
      'isOfflineAvailable': isOfflineAvailable,
      'isPremium': isPremium,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      subjectId: json['subjectId'],
      gradeLevel: json['gradeLevel'],
      orderIndex: json['orderIndex'],
      type: LessonType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => LessonType.text,
      ),
      content: (json['content'] as List)
          .map((c) => LessonContent.fromJson(c))
          .toList(),
      estimatedDurationMinutes: json['estimatedDurationMinutes'],
      prerequisites: List<String>.from(json['prerequisites'] ?? []),
      learningObjectives: List<String>.from(json['learningObjectives'] ?? []),
      keywords: List<String>.from(json['keywords'] ?? []),
      thumbnailUrl: json['thumbnailUrl'],
      isOfflineAvailable: json['isOfflineAvailable'] ?? false,
      isPremium: json['isPremium'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

@HiveType(typeId: 4)
enum LessonType {
  @HiveField(0)
  text,
  @HiveField(1)
  video,
  @HiveField(2)
  audio,
  @HiveField(3)
  interactive,
  @HiveField(4)
  game,
  @HiveField(5)
  simulation,
  @HiveField(6)
  quiz,
  @HiveField(7)
  mixed,
}

@HiveType(typeId: 5)
class LessonContent extends Equatable {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final ContentType type;
  
  @HiveField(2)
  final String? title;
  
  @HiveField(3)
  final String? text;
  
  @HiveField(4)
  final String? mediaUrl;
  
  @HiveField(5)
  final String? localPath;
  
  @HiveField(6)
  final int orderIndex;
  
  @HiveField(7)
  final Map<String, dynamic>? metadata;
  
  @HiveField(8)
  final bool isInteractive;

  const LessonContent({
    required this.id,
    required this.type,
    this.title,
    this.text,
    this.mediaUrl,
    this.localPath,
    required this.orderIndex,
    this.metadata,
    this.isInteractive = false,
  });

  @override
  List<Object?> get props => [
        id,
        type,
        title,
        text,
        mediaUrl,
        localPath,
        orderIndex,
        metadata,
        isInteractive,
      ];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'text': text,
      'mediaUrl': mediaUrl,
      'localPath': localPath,
      'orderIndex': orderIndex,
      'metadata': metadata,
      'isInteractive': isInteractive,
    };
  }

  factory LessonContent.fromJson(Map<String, dynamic> json) {
    return LessonContent(
      id: json['id'],
      type: ContentType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ContentType.text,
      ),
      title: json['title'],
      text: json['text'],
      mediaUrl: json['mediaUrl'],
      localPath: json['localPath'],
      orderIndex: json['orderIndex'],
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
      isInteractive: json['isInteractive'] ?? false,
    );
  }
}

@HiveType(typeId: 6)
enum ContentType {
  @HiveField(0)
  text,
  @HiveField(1)
  image,
  @HiveField(2)
  video,
  @HiveField(3)
  audio,
  @HiveField(4)
  animation,
  @HiveField(5)
  interactive,
  @HiveField(6)
  code,
  @HiveField(7)
  math,
  @HiveField(8)
  diagram,
}
