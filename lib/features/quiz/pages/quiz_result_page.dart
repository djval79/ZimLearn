import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:confetti/confetti.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants.dart';
import '../../../core/services/service_locator.dart';
import '../../../data/models/quiz.dart';
import '../../../data/models/user.dart';
import '../../common/widgets/glassmorphic_widgets.dart';
import '../../common/widgets/kids_animation_widgets.dart';
import '../bloc/quiz_bloc.dart';

class QuizResultPage extends StatefulWidget {
  final Quiz quiz;
  final QuizAttempt attempt;
  final bool isYoungerChild;
  
  const QuizResultPage({
    Key? key,
    required this.quiz,
    required this.attempt,
    this.isYoungerChild = false,
  }) : super(key: key);

  @override
  State<QuizResultPage> createState() => _QuizResultPageState();
}

class _QuizResultPageState extends State<QuizResultPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late ConfettiController _confettiController;
  
  // Performance metrics
  late double _scorePercentage;
  late int _correctAnswers;
  late int _incorrectAnswers;
  late int _unansweredQuestions;
  late Duration _averageTimePerQuestion;
  late List<String> _strongSubjects;
  late List<String> _weakSubjects;
  
  // UI state
  bool _showWrongAnswersOnly = false;
  bool _expandedAnalytics = false;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..forward();
    
    _confettiController = ConfettiController(duration: const Duration(seconds: 5));
    
    // Calculate performance metrics
    _calculatePerformanceMetrics();
    
    // Play celebration for good scores
    if (_scorePercentage >= 0.7) {
      _confettiController.play();
    }
  }
  
  void _calculatePerformanceMetrics() {
    // Calculate score percentage
    _scorePercentage = widget.attempt.score / widget.attempt.maxScore;
    
    // Count correct, incorrect, and unanswered questions
    _correctAnswers = widget.attempt.answers.where((a) => a.isCorrect).length;
    _incorrectAnswers = widget.attempt.answers.where((a) => !a.isCorrect && (a.selectedOptionIds.isNotEmpty || a.textAnswer.isNotEmpty)).length;
    _unansweredQuestions = widget.quiz.questions.length - _correctAnswers - _incorrectAnswers;
    
    // Calculate average time per question
    final totalSeconds = widget.attempt.timeTaken;
    final totalQuestions = widget.quiz.questions.length;
    _averageTimePerQuestion = Duration(seconds: totalQuestions > 0 ? (totalSeconds / totalQuestions).round() : 0);
    
    // Analyze strong and weak subjects (in a real app, this would be more sophisticated)
    // For now, we'll use a simplified approach
    final subjectPerformance = <String, List<bool>>{};
    
    for (int i = 0; i < widget.quiz.questions.length; i++) {
      final question = widget.quiz.questions[i];
      final answer = i < widget.attempt.answers.length ? widget.attempt.answers[i] : null;
      final isCorrect = answer?.isCorrect ?? false;
      
      final subject = question.subject ?? 'General';
      if (!subjectPerformance.containsKey(subject)) {
        subjectPerformance[subject] = [];
      }
      subjectPerformance[subject]!.add(isCorrect);
    }
    
    // Determine strong and weak subjects
    _strongSubjects = [];
    _weakSubjects = [];
    
    subjectPerformance.forEach((subject, results) {
      if (results.isNotEmpty) {
        final correctCount = results.where((r) => r).length;
        final percentage = correctCount / results.length;
        
        if (percentage >= 0.7) {
          _strongSubjects.add(subject);
        } else if (percentage <= 0.4) {
          _weakSubjects.add(subject);
        }
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassmorphicAppBar(
        title: 'Quiz Results',
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: _shareResults,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF008751).withOpacity(0.8), // Green (Zimbabwe flag)
              const Color(0xFF000000).withOpacity(0.9), // Black (Zimbabwe flag)
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Confetti animation for good scores
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirection: math.pi / 2, // straight down
                  emissionFrequency: 0.05,
                  numberOfParticles: 20,
                  maxBlastForce: 20,
                  minBlastForce: 10,
                  gravity: 0.2,
                ),
              ),
              
              // Main content
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Score summary
                  SliverToBoxAdapter(
                    child: _buildScoreSummary(theme),
                  ),
                  
                  // Performance analytics
                  SliverToBoxAdapter(
                    child: _buildPerformanceAnalytics(theme),
                  ),
                  
                  // Questions review
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          Text(
                            'Questions Review',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          // Toggle to show only wrong answers
                          Row(
                            children: [
                              Text(
                                'Wrong Only',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                              Switch(
                                value: _showWrongAnswersOnly,
                                onChanged: (value) {
                                  setState(() {
                                    _showWrongAnswersOnly = value;
                                  });
                                },
                                activeColor: theme.colorScheme.secondary,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Questions list
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final question = widget.quiz.questions[index];
                        final answer = index < widget.attempt.answers.length 
                            ? widget.attempt.answers[index] 
                            : null;
                        
                        // Skip if showing only wrong answers and this one is correct
                        if (_showWrongAnswersOnly && answer?.isCorrect == true) {
                          return const SizedBox.shrink();
                        }
                        
                        return _buildQuestionReviewCard(question, answer, theme, index);
                      },
                      childCount: widget.quiz.questions.length,
                    ),
                  ),
                  
                  // Recommendations
                  SliverToBoxAdapter(
                    child: _buildRecommendations(theme),
                  ),
                  
                  // Action buttons
                  SliverToBoxAdapter(
                    child: _buildActionButtons(theme),
                  ),
                  
                  // Bottom padding
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 32),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildScoreSummary(ThemeData theme) {
    // Determine performance level and message
    String performanceMessage;
    Color performanceColor;
    String lottieAnimation;
    
    if (_scorePercentage >= 0.9) {
      performanceMessage = widget.isYoungerChild 
          ? 'Amazing! You\'re a Star! 🌟' 
          : 'Excellent! Outstanding performance!';
      performanceColor = Colors.green;
      lottieAnimation = 'assets/animations/trophy.json';
    } else if (_scorePercentage >= 0.7) {
      performanceMessage = widget.isYoungerChild 
          ? 'Great Job! 🎉' 
          : 'Great work! Well done!';
      performanceColor = Colors.green;
      lottieAnimation = 'assets/animations/celebration.json';
    } else if (_scorePercentage >= 0.5) {
      performanceMessage = widget.isYoungerChild 
          ? 'Good Effort! 👍' 
          : 'Good effort! Keep practicing!';
      performanceColor = Colors.amber;
      lottieAnimation = 'assets/animations/thumbs_up.json';
    } else {
      performanceMessage = widget.isYoungerChild 
          ? 'Try Again! You Can Do It! 💪' 
          : 'Keep learning! You\'ll improve with practice.';
      performanceColor = Colors.orange;
      lottieAnimation = 'assets/animations/encouragement.json';
    }
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GlassmorphicCard(
        height: 300,
        child: Column(
          children: [
            // Score circle
            Expanded(
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Score percentage
                    CircularPercentIndicator(
                      radius: 80,
                      lineWidth: 15,
                      percent: _scorePercentage,
                      center: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${(_scorePercentage * 100).round()}%',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Score',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      progressColor: performanceColor,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      circularStrokeCap: CircularStrokeCap.round,
                      animation: true,
                      animationDuration: 1500,
                    ),
                    
                    const SizedBox(width: 24),
                    
                    // Animation
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: Lottie.asset(
                        lottieAnimation,
                        fit: BoxFit.contain,
                        repeat: true,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            _scorePercentage >= 0.7 
                                ? Icons.emoji_events 
                                : Icons.psychology,
                            color: performanceColor,
                            size: 80,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Performance message
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: performanceColor.withOpacity(0.3),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Column(
                children: [
                  widget.isYoungerChild
                      ? DancingLetters(
                          text: performanceMessage,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : Text(
                          performanceMessage,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                  const SizedBox(height: 8),
                  Text(
                    'You got ${widget.attempt.score} out of ${widget.attempt.maxScore} points',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPerformanceAnalytics(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassmorphicCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with expand/collapse
            InkWell(
              onTap: () {
                setState(() {
                  _expandedAnalytics = !_expandedAnalytics;
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      'Performance Analytics',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      _expandedAnalytics
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
            
            // Basic stats always visible
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  _buildStatItem(
                    icon: Icons.check_circle,
                    label: 'Correct',
                    value: _correctAnswers.toString(),
                    color: Colors.green,
                    theme: theme,
                  ),
                  const SizedBox(width: 16),
                  _buildStatItem(
                    icon: Icons.cancel,
                    label: 'Incorrect',
                    value: _incorrectAnswers.toString(),
                    color: Colors.red,
                    theme: theme,
                  ),
                  const SizedBox(width: 16),
                  _buildStatItem(
                    icon: Icons.help_outline,
                    label: 'Unanswered',
                    value: _unansweredQuestions.toString(),
                    color: Colors.grey,
                    theme: theme,
                  ),
                ],
              ),
            ),
            
            // Expanded analytics
            if (_expandedAnalytics) ...[
              const Divider(
                color: Colors.white24,
                height: 1,
              ),
              
              // Time analytics
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Time Analytics',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildStatItem(
                          icon: Icons.timer,
                          label: 'Total Time',
                          value: '${Duration(seconds: widget.attempt.timeTaken).inMinutes}m ${Duration(seconds: widget.attempt.timeTaken).inSeconds % 60}s',
                          color: Colors.blue,
                          theme: theme,
                        ),
                        const SizedBox(width: 16),
                        _buildStatItem(
                          icon: Icons.speed,
                          label: 'Avg. per Question',
                          value: '${_averageTimePerQuestion.inSeconds}s',
                          color: Colors.amber,
                          theme: theme,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Performance chart
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Performance Breakdown',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: _buildPerformanceChart(theme),
                    ),
                  ],
                ),
              ),
              
              // Strengths and weaknesses
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Strengths & Areas for Improvement',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_strongSubjects.isNotEmpty) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Strengths:',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _strongSubjects.join(', '),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_weakSubjects.isNotEmpty) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.build,
                            color: Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Areas for Improvement:',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _weakSubjects.join(', '),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required ThemeData theme,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPerformanceChart(ThemeData theme) {
    // Create data for pie chart
    final correctSection = PieChartSectionData(
      value: _correctAnswers.toDouble(),
      title: '${(_correctAnswers / widget.quiz.questions.length * 100).round()}%',
      color: Colors.green,
      radius: 80,
      titleStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
    );
    
    final incorrectSection = PieChartSectionData(
      value: _incorrectAnswers.toDouble(),
      title: '${(_incorrectAnswers / widget.quiz.questions.length * 100).round()}%',
      color: Colors.red,
      radius: 80,
      titleStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
    );
    
    final unansweredSection = PieChartSectionData(
      value: _unansweredQuestions.toDouble(),
      title: '${(_unansweredQuestions / widget.quiz.questions.length * 100).round()}%',
      color: Colors.grey,
      radius: 80,
      titleStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
    );
    
    final sections = [
      correctSection,
      incorrectSection,
      if (_unansweredQuestions > 0) unansweredSection,
    ];
    
    return Row(
      children: [
        // Pie chart
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 2,
              startDegreeOffset: 180,
            ),
          ),
        ),
        
        // Legend
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLegendItem(
                color: Colors.green,
                label: 'Correct',
                value: '$_correctAnswers (${(_correctAnswers / widget.quiz.questions.length * 100).round()}%)',
                theme: theme,
              ),
              const SizedBox(height: 12),
              _buildLegendItem(
                color: Colors.red,
                label: 'Incorrect',
                value: '$_incorrectAnswers (${(_incorrectAnswers / widget.quiz.questions.length * 100).round()}%)',
                theme: theme,
              ),
              if (_unansweredQuestions > 0) ...[
                const SizedBox(height: 12),
                _buildLegendItem(
                  color: Colors.grey,
                  label: 'Unanswered',
                  value: '$_unansweredQuestions (${(_unansweredQuestions / widget.quiz.questions.length * 100).round()}%)',
                  theme: theme,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildLegendItem({
    required Color color,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildQuestionReviewCard(
    QuizQuestion question,
    QuizAnswer? answer,
    ThemeData theme,
    int index,
  ) {
    final isCorrect = answer?.isCorrect ?? false;
    final isAnswered = answer != null && 
        (answer.selectedOptionIds.isNotEmpty || answer.textAnswer.isNotEmpty);
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: GlassmorphicCard(
        color: isCorrect
            ? Colors.green.withOpacity(0.2)
            : isAnswered
                ? Colors.red.withOpacity(0.2)
                : Colors.grey.withOpacity(0.2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'Question ${index + 1}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isCorrect
                          ? Colors.green
                          : isAnswered
                              ? Colors.red
                              : Colors.grey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isCorrect
                          ? 'Correct'
                          : isAnswered
                              ? 'Incorrect'
                              : 'Unanswered',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Question content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question text
                  Text(
                    question.text,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  if (question.imageUrl != null && question.imageUrl!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        question.imageUrl!,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 150,
                          width: double.infinity,
                          color: Colors.grey.withOpacity(0.3),
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.white54,
                            size: 48,
                          ),
                        ),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 16),
                  
                  // Your answer
                  Text(
                    'Your Answer:',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildUserAnswer(question, answer, theme),
                  
                  const SizedBox(height: 16),
                  
                  // Correct answer
                  if (!isCorrect) ...[
                    Text(
                      'Correct Answer:',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildCorrectAnswer(question, theme),
                  ],
                  
                  // Explanation if available
                  if (question.explanation != null && question.explanation!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Explanation:',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      question.explanation!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildUserAnswer(QuizQuestion question, QuizAnswer? answer, ThemeData theme) {
    if (answer == null || (!answer.selectedOptionIds.isNotEmpty && answer.textAnswer.isEmpty)) {
      return Text(
        'No answer provided',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: Colors.grey,
          fontStyle: FontStyle.italic,
        ),
      );
    }
    
    switch (question.type) {
      case QuestionType.multipleChoice:
      case QuestionType.trueFalse:
        // Find the selected option
        final selectedOptionId = answer.selectedOptionIds.isNotEmpty 
            ? answer.selectedOptionIds.first 
            : null;
        
        if (selectedOptionId == null) {
          return Text(
            'No option selected',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          );
        }
        
        final selectedOption = question.options.firstWhere(
          (o) => o.id == selectedOptionId,
          orElse: () => QuizOption(id: '', text: 'Unknown option'),
        );
        
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: answer.isCorrect
                ? Colors.green.withOpacity(0.3)
                : Colors.red.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: answer.isCorrect ? Colors.green : Colors.red,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                answer.isCorrect ? Icons.check_circle : Icons.cancel,
                color: answer.isCorrect ? Colors.green : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  selectedOption.text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
        
      case QuestionType.multipleAnswer:
        // Show all selected options
        final selectedOptionIds = answer.selectedOptionIds;
        
        if (selectedOptionIds.isEmpty) {
          return Text(
            'No options selected',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          );
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: selectedOptionIds.map((optionId) {
            final option = question.options.firstWhere(
              (o) => o.id == optionId,
              orElse: () => QuizOption(id: '', text: 'Unknown option'),
            );
            
            final isCorrectOption = question.correctOptionIds.contains(optionId);
            
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCorrectOption
                    ? Colors.green.withOpacity(0.3)
                    : Colors.red.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isCorrectOption ? Colors.green : Colors.red,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isCorrectOption ? Icons.check_circle : Icons.cancel,
                    color: isCorrectOption ? Colors.green : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      option.text,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
        
      case QuestionType.fillInBlank:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: answer.isCorrect
                ? Colors.green.withOpacity(0.3)
                : Colors.red.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: answer.isCorrect ? Colors.green : Colors.red,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                answer.isCorrect ? Icons.check_circle : Icons.cancel,
                color: answer.isCorrect ? Colors.green : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  answer.textAnswer,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
        
      case QuestionType.matching:
      case QuestionType.ordering:
        // These would need more complex UI in a real app
        return Text(
          answer.isCorrect ? 'Correctly matched' : 'Incorrectly matched',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: answer.isCorrect ? Colors.green : Colors.red,
          ),
        );
        
      default:
        return Text(
          'Answer not available',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        );
    }
  }
  
  Widget _buildCorrectAnswer(QuizQuestion question, ThemeData theme) {
    switch (question.type) {
      case QuestionType.multipleChoice:
      case QuestionType.trueFalse:
        // Find the correct option
        final correctOptionId = question.correctOptionIds.isNotEmpty 
            ? question.correctOptionIds.first 
            : null;
        
        if (correctOptionId == null) {
          return Text(
            'No correct answer defined',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          );
        }
        
        final correctOption = question.options.firstWhere(
          (o) => o.id == correctOptionId,
          orElse: () => QuizOption(id: '', text: 'Unknown option'),
        );
        
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.green,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  correctOption.text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
        
      case QuestionType.multipleAnswer:
        // Show all correct options
        final correctOptionIds = question.correctOptionIds;
        
        if (correctOptionIds.isEmpty) {
          return Text(
            'No correct answers defined',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          );
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: correctOptionIds.map((optionId) {
            final option = question.options.firstWhere(
              (o) => o.id == optionId,
              orElse: () => QuizOption(id: '', text: 'Unknown option'),
            );
            
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.green,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      option.text,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
        
      case QuestionType.fillInBlank:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.green,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  question.correctAnswer ?? 'No correct answer defined',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
        
      case QuestionType.matching:
      case QuestionType.ordering:
        // These would need more complex UI in a real app
        return Text(
          'Matching/Ordering answers would be displayed here',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.green,
          ),
        );
        
      default:
        return Text(
          'Correct answer not available',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        );
    }
  }
  
  Widget _buildRecommendations(ThemeData theme) {
    // Generate personalized recommendations based on performance
    List<String> recommendations = [];
    
    if (_scorePercentage < 0.5) {
      recommendations.add('Review the lesson materials before attempting the quiz again.');
      recommendations.add('Take notes while studying to improve retention.');
      if (_weakSubjects.isNotEmpty) {
        recommendations.add('Focus on improving your knowledge in: ${_weakSubjects.join(', ')}.');
      }
    } else if (_scorePercentage < 0.7) {
      recommendations.add('Practice more questions related to the topics you missed.');
      if (_weakSubjects.isNotEmpty) {
        recommendations.add('Spend extra time studying: ${_weakSubjects.join(', ')}.');
      }
    } else if (_scorePercentage < 0.9) {
      recommendations.add('You\'re doing well! Review the few questions you missed.');
      recommendations.add('Try more challenging questions to further improve your skills.');
    } else {
      recommendations.add('Excellent work! Consider moving to more advanced topics.');
      recommendations.add('Help your classmates understand these concepts.');
    }
    
    // Add time management recommendation if applicable
    if (_averageTimePerQuestion.inSeconds > 30) {
      recommendations.add('Work on improving your speed. Try to answer questions more quickly.');
    }
    
    // Add recommendation about using hints if applicable
    if (widget.attempt.hintsUsed > widget.quiz.questions.length / 3) {
      recommendations.add('Try to rely less on hints to build confidence in your knowledge.');
    }
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: GlassmorphicCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.lightbulb,
                    color: theme.colorScheme.secondary,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Recommendations',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...recommendations.map((recommendation) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.arrow_right,
                        color: theme.colorScheme.secondary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          recommendation,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              
              // Next steps suggestion
              const SizedBox(height: 16),
              Text(
                'Next Steps:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _scorePercentage >= 0.7
                    ? 'You\'re ready to move on to the next lesson!'
                    : 'Review the material and try the quiz again to improve your score.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildActionButtons(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          // Retry quiz button
          Expanded(
            child: AnimatedGlassmorphicButton(
              height: 50,
              onPressed: () {
                // Navigate back to quiz
                Navigator.pop(context);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.replay,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Retry Quiz',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Continue learning button
          Expanded(
            child: AnimatedGlassmorphicButton(
              height: 50,
              color: theme.colorScheme.secondary,
              onPressed: () {
                // Navigate to dashboard or next lesson
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Continue',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _shareResults() {
    // Format the results for sharing
    final percentage = (_scorePercentage * 100).round();
    final message = 'I scored $percentage% (${widget.attempt.score}/${widget.attempt.maxScore}) on the "${widget.quiz.title}" quiz in ZimLearn! 🇿🇼📚';
    
    // Share the results
    Share.share(message);
  }
}
