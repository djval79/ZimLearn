import 'dart:math';

/// A comprehensive model representing a user's learning style preferences
/// Used by the AI tutor to personalize educational content and interactions
class LearningStyle {
  /// Learning modality preferences (0.0 to 1.0)
  /// Higher values indicate stronger preference
  final double visualPreference;
  final double auditoryPreference;
  final double kinestheticPreference;
  final double readingWritingPreference;
  
  /// Preferred depth of explanations (0.0 to 1.0)
  /// 0.0 = very basic, 1.0 = extremely detailed
  final double preferredDepth;
  
  /// Complexity level preferences (0.0 to 1.0)
  /// 0.0 = simplified, 1.0 = advanced
  final double complexityPreference;
  
  /// Interaction style preferences
  final bool prefersQuestions;
  final bool prefersExamples;
  final bool prefersStepByStep;
  final bool prefersRealWorldConnections;
  
  /// Motivational factors (0.0 to 1.0)
  final double achievementMotivation;
  final double curiosityMotivation;
  final double socialMotivation;
  final double masteryMotivation;
  
  /// Attention span characteristics
  final Duration typicalFocusDuration;
  final int optimalSessionLength; // in minutes
  final bool needsFrequentBreaks;
  
  /// Preferred learning pace (0.0 to 1.0)
  /// 0.0 = very slow, 0.5 = moderate, 1.0 = very fast
  final double learningPace;
  
  /// Cultural and linguistic preferences
  final String preferredLanguage;
  final bool usesCulturalReferences;
  final List<String> culturalContexts;
  
  /// Additional preferences
  final bool prefersGameBasedLearning;
  final bool prefersCollaborativeLearning;
  final bool prefersSelfDirectedLearning;
  final Map<String, double> subjectSpecificPreferences;
  
  /// Constructor with default values for new users
  LearningStyle({
    this.visualPreference = 0.5,
    this.auditoryPreference = 0.5,
    this.kinestheticPreference = 0.5,
    this.readingWritingPreference = 0.5,
    this.preferredDepth = 0.5,
    this.complexityPreference = 0.5,
    this.prefersQuestions = true,
    this.prefersExamples = true,
    this.prefersStepByStep = true,
    this.prefersRealWorldConnections = true,
    this.achievementMotivation = 0.5,
    this.curiosityMotivation = 0.5,
    this.socialMotivation = 0.5,
    this.masteryMotivation = 0.5,
    this.typicalFocusDuration = const Duration(minutes: 30),
    this.optimalSessionLength = 45,
    this.needsFrequentBreaks = false,
    this.learningPace = 0.5,
    this.preferredLanguage = 'en',
    this.usesCulturalReferences = true,
    this.culturalContexts = const ['zimbabwean'],
    this.prefersGameBasedLearning = false,
    this.prefersCollaborativeLearning = false,
    this.prefersSelfDirectedLearning = true,
    this.subjectSpecificPreferences = const {},
  });
  
  /// Create a copy of this learning style with modified properties
  LearningStyle copyWith({
    double? visualPreference,
    double? auditoryPreference,
    double? kinestheticPreference,
    double? readingWritingPreference,
    double? preferredDepth,
    double? complexityPreference,
    bool? prefersQuestions,
    bool? prefersExamples,
    bool? prefersStepByStep,
    bool? prefersRealWorldConnections,
    double? achievementMotivation,
    double? curiosityMotivation,
    double? socialMotivation,
    double? masteryMotivation,
    Duration? typicalFocusDuration,
    int? optimalSessionLength,
    bool? needsFrequentBreaks,
    double? learningPace,
    String? preferredLanguage,
    bool? usesCulturalReferences,
    List<String>? culturalContexts,
    bool? prefersGameBasedLearning,
    bool? prefersCollaborativeLearning,
    bool? prefersSelfDirectedLearning,
    Map<String, double>? subjectSpecificPreferences,
  }) {
    return LearningStyle(
      visualPreference: visualPreference ?? this.visualPreference,
      auditoryPreference: auditoryPreference ?? this.auditoryPreference,
      kinestheticPreference: kinestheticPreference ?? this.kinestheticPreference,
      readingWritingPreference: readingWritingPreference ?? this.readingWritingPreference,
      preferredDepth: preferredDepth ?? this.preferredDepth,
      complexityPreference: complexityPreference ?? this.complexityPreference,
      prefersQuestions: prefersQuestions ?? this.prefersQuestions,
      prefersExamples: prefersExamples ?? this.prefersExamples,
      prefersStepByStep: prefersStepByStep ?? this.prefersStepByStep,
      prefersRealWorldConnections: prefersRealWorldConnections ?? this.prefersRealWorldConnections,
      achievementMotivation: achievementMotivation ?? this.achievementMotivation,
      curiosityMotivation: curiosityMotivation ?? this.curiosityMotivation,
      socialMotivation: socialMotivation ?? this.socialMotivation,
      masteryMotivation: masteryMotivation ?? this.masteryMotivation,
      typicalFocusDuration: typicalFocusDuration ?? this.typicalFocusDuration,
      optimalSessionLength: optimalSessionLength ?? this.optimalSessionLength,
      needsFrequentBreaks: needsFrequentBreaks ?? this.needsFrequentBreaks,
      learningPace: learningPace ?? this.learningPace,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      usesCulturalReferences: usesCulturalReferences ?? this.usesCulturalReferences,
      culturalContexts: culturalContexts ?? this.culturalContexts,
      prefersGameBasedLearning: prefersGameBasedLearning ?? this.prefersGameBasedLearning,
      prefersCollaborativeLearning: prefersCollaborativeLearning ?? this.prefersCollaborativeLearning,
      prefersSelfDirectedLearning: prefersSelfDirectedLearning ?? this.prefersSelfDirectedLearning,
      subjectSpecificPreferences: subjectSpecificPreferences ?? this.subjectSpecificPreferences,
    );
  }
  
  /// Get the dominant learning modality
  String get dominantModality {
    final preferences = {
      'visual': visualPreference,
      'auditory': auditoryPreference,
      'kinesthetic': kinestheticPreference,
      'reading/writing': readingWritingPreference,
    };
    
    return preferences.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }
  
  /// Get the optimal content format based on learning style
  String getOptimalContentFormat() {
    if (visualPreference > 0.7) {
      return 'visual-rich';
    } else if (auditoryPreference > 0.7) {
      return 'audio-focused';
    } else if (kinestheticPreference > 0.7) {
      return 'interactive';
    } else if (readingWritingPreference > 0.7) {
      return 'text-based';
    } else {
      return 'mixed';
    }
  }
  
  /// Get recommended session duration in minutes
  int getRecommendedSessionDuration() {
    // Base on typical focus duration and optimal session length
    final baseDuration = optimalSessionLength;
    
    // Adjust for learning pace
    if (learningPace < 0.3) {
      return (baseDuration * 1.3).round(); // Slower learners need more time
    } else if (learningPace > 0.7) {
      return (baseDuration * 0.8).round(); // Faster learners need less time
    }
    
    return baseDuration;
  }
  
  /// Get recommended break frequency in minutes
  int getRecommendedBreakFrequency() {
    if (needsFrequentBreaks) {
      return 15; // Break every 15 minutes
    } else if (typicalFocusDuration.inMinutes > 45) {
      return 45; // Break every 45 minutes
    } else {
      return 30; // Break every 30 minutes
    }
  }
  
  /// Determine if content should be simplified based on preferences
  bool shouldSimplifyContent() {
    return complexityPreference < 0.4 || preferredDepth < 0.3;
  }
  
  /// Determine if content should be enriched with advanced concepts
  bool shouldEnrichContent() {
    return complexityPreference > 0.7 && preferredDepth > 0.6;
  }
  
  /// Get subject-specific learning pace
  double getSubjectLearningPace(String subject) {
    if (subjectSpecificPreferences.containsKey(subject)) {
      return subjectSpecificPreferences[subject]!;
    }
    return learningPace;
  }
  
  /// Get primary motivation factor
  String getPrimaryMotivationFactor() {
    final motivations = {
      'achievement': achievementMotivation,
      'curiosity': curiosityMotivation,
      'social': socialMotivation,
      'mastery': masteryMotivation,
    };
    
    return motivations.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }
  
  /// Generate a random learning style for testing
  static LearningStyle random() {
    final random = Random();
    
    return LearningStyle(
      visualPreference: random.nextDouble(),
      auditoryPreference: random.nextDouble(),
      kinestheticPreference: random.nextDouble(),
      readingWritingPreference: random.nextDouble(),
      preferredDepth: random.nextDouble(),
      complexityPreference: random.nextDouble(),
      prefersQuestions: random.nextBool(),
      prefersExamples: random.nextBool(),
      prefersStepByStep: random.nextBool(),
      prefersRealWorldConnections: random.nextBool(),
      achievementMotivation: random.nextDouble(),
      curiosityMotivation: random.nextDouble(),
      socialMotivation: random.nextDouble(),
      masteryMotivation: random.nextDouble(),
      typicalFocusDuration: Duration(minutes: 15 + random.nextInt(46)),
      optimalSessionLength: 15 + random.nextInt(46),
      needsFrequentBreaks: random.nextBool(),
      learningPace: random.nextDouble(),
      preferredLanguage: ['en', 'sn', 'nd'][random.nextInt(3)],
      usesCulturalReferences: random.nextBool(),
    );
  }
  
  /// Create a learning style optimized for younger children
  static LearningStyle forYoungerChild() {
    return LearningStyle(
      visualPreference: 0.8,
      auditoryPreference: 0.7,
      kinestheticPreference: 0.9,
      readingWritingPreference: 0.3,
      preferredDepth: 0.3,
      complexityPreference: 0.2,
      prefersQuestions: true,
      prefersExamples: true,
      prefersStepByStep: true,
      prefersRealWorldConnections: true,
      achievementMotivation: 0.6,
      curiosityMotivation: 0.9,
      socialMotivation: 0.7,
      masteryMotivation: 0.5,
      typicalFocusDuration: const Duration(minutes: 15),
      optimalSessionLength: 20,
      needsFrequentBreaks: true,
      learningPace: 0.4,
      prefersGameBasedLearning: true,
    );
  }
  
  /// Create a learning style optimized for older students
  static LearningStyle forOlderStudent() {
    return LearningStyle(
      visualPreference: 0.6,
      auditoryPreference: 0.5,
      kinestheticPreference: 0.4,
      readingWritingPreference: 0.8,
      preferredDepth: 0.7,
      complexityPreference: 0.7,
      prefersQuestions: true,
      prefersExamples: true,
      prefersStepByStep: true,
      prefersRealWorldConnections: true,
      achievementMotivation: 0.8,
      curiosityMotivation: 0.7,
      socialMotivation: 0.5,
      masteryMotivation: 0.8,
      typicalFocusDuration: const Duration(minutes: 45),
      optimalSessionLength: 60,
      needsFrequentBreaks: false,
      learningPace: 0.7,
      prefersSelfDirectedLearning: true,
    );
  }
  
  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'visualPreference': visualPreference,
      'auditoryPreference': auditoryPreference,
      'kinestheticPreference': kinestheticPreference,
      'readingWritingPreference': readingWritingPreference,
      'preferredDepth': preferredDepth,
      'complexityPreference': complexityPreference,
      'prefersQuestions': prefersQuestions,
      'prefersExamples': prefersExamples,
      'prefersStepByStep': prefersStepByStep,
      'prefersRealWorldConnections': prefersRealWorldConnections,
      'achievementMotivation': achievementMotivation,
      'curiosityMotivation': curiosityMotivation,
      'socialMotivation': socialMotivation,
      'masteryMotivation': masteryMotivation,
      'typicalFocusDurationMinutes': typicalFocusDuration.inMinutes,
      'optimalSessionLength': optimalSessionLength,
      'needsFrequentBreaks': needsFrequentBreaks,
      'learningPace': learningPace,
      'preferredLanguage': preferredLanguage,
      'usesCulturalReferences': usesCulturalReferences,
      'culturalContexts': culturalContexts,
      'prefersGameBasedLearning': prefersGameBasedLearning,
      'prefersCollaborativeLearning': prefersCollaborativeLearning,
      'prefersSelfDirectedLearning': prefersSelfDirectedLearning,
      'subjectSpecificPreferences': subjectSpecificPreferences,
    };
  }
  
  /// Create from JSON data
  factory LearningStyle.fromJson(Map<String, dynamic> json) {
    return LearningStyle(
      visualPreference: json['visualPreference'] ?? 0.5,
      auditoryPreference: json['auditoryPreference'] ?? 0.5,
      kinestheticPreference: json['kinestheticPreference'] ?? 0.5,
      readingWritingPreference: json['readingWritingPreference'] ?? 0.5,
      preferredDepth: json['preferredDepth'] ?? 0.5,
      complexityPreference: json['complexityPreference'] ?? 0.5,
      prefersQuestions: json['prefersQuestions'] ?? true,
      prefersExamples: json['prefersExamples'] ?? true,
      prefersStepByStep: json['prefersStepByStep'] ?? true,
      prefersRealWorldConnections: json['prefersRealWorldConnections'] ?? true,
      achievementMotivation: json['achievementMotivation'] ?? 0.5,
      curiosityMotivation: json['curiosityMotivation'] ?? 0.5,
      socialMotivation: json['socialMotivation'] ?? 0.5,
      masteryMotivation: json['masteryMotivation'] ?? 0.5,
      typicalFocusDuration: Duration(minutes: json['typicalFocusDurationMinutes'] ?? 30),
      optimalSessionLength: json['optimalSessionLength'] ?? 45,
      needsFrequentBreaks: json['needsFrequentBreaks'] ?? false,
      learningPace: json['learningPace'] ?? 0.5,
      preferredLanguage: json['preferredLanguage'] ?? 'en',
      usesCulturalReferences: json['usesCulturalReferences'] ?? true,
      culturalContexts: json['culturalContexts'] != null 
          ? List<String>.from(json['culturalContexts']) 
          : ['zimbabwean'],
      prefersGameBasedLearning: json['prefersGameBasedLearning'] ?? false,
      prefersCollaborativeLearning: json['prefersCollaborativeLearning'] ?? false,
      prefersSelfDirectedLearning: json['prefersSelfDirectedLearning'] ?? true,
      subjectSpecificPreferences: json['subjectSpecificPreferences'] != null
          ? Map<String, double>.from(json['subjectSpecificPreferences'])
          : {},
    );
  }
}
