import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

import '../../../core/services/ai_tutor_service.dart';
import '../../common/widgets/glassmorphic_widgets.dart';

class PracticeQuestionCard extends StatefulWidget {
  final TutoringMessage message;
  final Function(String questionId, String answerId) onAnswerSelected;
  
  const PracticeQuestionCard({
    Key? key,
    required this.message,
    required this.onAnswerSelected,
  }) : super(key: key);

  @override
  State<PracticeQuestionCard> createState() => _PracticeQuestionCardState();
}

class _PracticeQuestionCardState extends State<PracticeQuestionCard> with SingleTickerProviderStateMixin {
  int _currentQuestionIndex = 0;
  final Map<String, List<String>> _selectedAnswers = {};
  final Map<String, bool> _questionCorrectness = {};
  bool _showExplanation = false;
  int _score = 0;
  int _maxScore = 0;
  bool _isCompleted = false;
  late AnimationController _animationController;
  
  // Mock practice questions - in a real app, these would be parsed from the message
  final List<Map<String, dynamic>> _mockQuestions = [
    {
      'id': 'q1',
      'question': 'What is the capital of Zimbabwe?',
      'type': 'multipleChoice',
      'options': [
        {'id': 'a', 'text': 'Harare'},
        {'id': 'b', 'text': 'Bulawayo'},
        {'id': 'c', 'text': 'Mutare'},
        {'id': 'd', 'text': 'Gweru'},
      ],
      'correctOptionIds': ['a'],
      'explanation': 'Harare is the capital city of Zimbabwe.',
      'points': 1,
    },
    {
      'id': 'q2',
      'question': 'Which river forms the northern border of Zimbabwe?',
      'type': 'multipleChoice',
      'options': [
        {'id': 'a', 'text': 'Limpopo River'},
        {'id': 'b', 'text': 'Zambezi River'},
        {'id': 'c', 'text': 'Save River'},
        {'id': 'd', 'text': 'Runde River'},
      ],
      'correctOptionIds': ['b'],
      'explanation': 'The Zambezi River forms the northern border between Zimbabwe and Zambia.',
      'points': 1,
    },
    {
      'id': 'q3',
      'question': 'What is the main cash crop in Zimbabwe?',
      'type': 'multipleChoice',
      'options': [
        {'id': 'a', 'text': 'Maize'},
        {'id': 'b', 'text': 'Cotton'},
        {'id': 'c', 'text': 'Tobacco'},
        {'id': 'd', 'text': 'Coffee'},
      ],
      'correctOptionIds': ['c'],
      'explanation': 'Tobacco is Zimbabwe\'s largest export crop.',
      'points': 1,
    },
    {
      'id': 'q4',
      'question': 'Select all minerals that are mined in Zimbabwe.',
      'type': 'multipleAnswer',
      'options': [
        {'id': 'a', 'text': 'Gold'},
        {'id': 'b', 'text': 'Platinum'},
        {'id': 'c', 'text': 'Diamonds'},
        {'id': 'd', 'text': 'Oil'},
      ],
      'correctOptionIds': ['a', 'b', 'c'],
      'explanation': 'Zimbabwe is rich in mineral resources including gold, platinum, and diamonds. However, oil is not a significant resource in Zimbabwe.',
      'points': 2,
    },
    {
      'id': 'q5',
      'question': 'The Great Zimbabwe ruins are located near which modern city?',
      'type': 'multipleChoice',
      'options': [
        {'id': 'a', 'text': 'Harare'},
        {'id': 'b', 'text': 'Bulawayo'},
        {'id': 'c', 'text': 'Masvingo'},
        {'id': 'd', 'text': 'Mutare'},
      ],
      'correctOptionIds': ['c'],
      'explanation': 'The Great Zimbabwe ruins are located near the modern city of Masvingo in south-central Zimbabwe.',
      'points': 1,
    },
  ];
  
  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Calculate max score
    for (final question in _mockQuestions) {
      _maxScore += question['points'] as int;
    }
    
    // Initialize selected answers
    for (final question in _mockQuestions) {
      _selectedAnswers[question['id'] as String] = [];
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _selectAnswer(String questionId, String optionId) {
    if (_isCompleted) return;
    
    setState(() {
      final question = _mockQuestions.firstWhere((q) => q['id'] == questionId);
      final questionType = question['type'] as String;
      
      if (questionType == 'multipleChoice') {
        // For multiple choice, only one answer can be selected
        _selectedAnswers[questionId] = [optionId];
      } else if (questionType == 'multipleAnswer') {
        // For multiple answer, toggle the selection
        if (_selectedAnswers[questionId]!.contains(optionId)) {
          _selectedAnswers[questionId]!.remove(optionId);
        } else {
          _selectedAnswers[questionId]!.add(optionId);
        }
      }
      
      // Check if answer is correct
      final correctOptionIds = question['correctOptionIds'] as List<dynamic>;
      
      if (questionType == 'multipleChoice') {
        _questionCorrectness[questionId] = correctOptionIds.contains(optionId);
      } else if (questionType == 'multipleAnswer') {
        // For multiple answer, all correct options must be selected and no incorrect ones
        final isCorrect = _selectedAnswers[questionId]!.length == correctOptionIds.length &&
                          _selectedAnswers[questionId]!.every((id) => correctOptionIds.contains(id));
        _questionCorrectness[questionId] = isCorrect;
      }
      
      _showExplanation = true;
      
      // Update score
      _updateScore();
      
      // Animate the explanation
      _animationController.forward(from: 0.0);
    });
    
    // Call the callback
    widget.onAnswerSelected(questionId, optionId);
  }
  
  void _updateScore() {
    int newScore = 0;
    
    for (final question in _mockQuestions) {
      final questionId = question['id'] as String;
      final points = question['points'] as int;
      
      if (_questionCorrectness[questionId] == true) {
        newScore += points;
      }
    }
    
    _score = newScore;
    
    // Check if all questions are answered
    final allAnswered = _mockQuestions.every((q) => 
      _selectedAnswers[q['id'] as String]!.isNotEmpty);
    
    _isCompleted = allAnswered;
  }
  
  void _nextQuestion() {
    if (_currentQuestionIndex < _mockQuestions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _showExplanation = _selectedAnswers[_mockQuestions[_currentQuestionIndex]['id'] as String]!.isNotEmpty;
      });
    }
  }
  
  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
        _showExplanation = _selectedAnswers[_mockQuestions[_currentQuestionIndex]['id'] as String]!.isNotEmpty;
      });
    }
  }
  
  void _retryQuiz() {
    setState(() {
      _currentQuestionIndex = 0;
      _selectedAnswers.clear();
      _questionCorrectness.clear();
      _showExplanation = false;
      _score = 0;
      _isCompleted = false;
      
      // Re-initialize selected answers
      for (final question in _mockQuestions) {
        _selectedAnswers[question['id'] as String] = [];
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // In a real app, we would parse the questions from the message
    // For now, use mock questions
    final questions = _mockQuestions;
          
    if (questions.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final currentQuestion = questions[_currentQuestionIndex];
    final questionId = currentQuestion['id'] as String;
    final questionType = currentQuestion['type'] as String;
    final options = currentQuestion['options'] as List<dynamic>;
    final selectedAnswerIds = _selectedAnswers[questionId] ?? [];
    final correctOptionIds = currentQuestion['correctOptionIds'] as List<dynamic>;
    final explanation = currentQuestion['explanation'] as String;
    final isAnswered = selectedAnswerIds.isNotEmpty;
    final isCorrect = _questionCorrectness[questionId] ?? false;
    
    return GlassmorphicContainer(
      width: double.infinity,
      borderRadius: 16,
      blur: 10,
      border: 1,
      linearGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.1),
          Colors.white.withOpacity(0.05),
        ],
      ),
      borderGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.3),
          Colors.white.withOpacity(0.1),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question header with progress
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.quiz,
                      color: theme.colorScheme.secondary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Question ${_currentQuestionIndex + 1}/${questions.length}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Score: $_score/$_maxScore',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearPercentIndicator(
                  percent: ((_currentQuestionIndex + 1) / questions.length).clamp(0.0, 1.0),
                  lineHeight: 8,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  progressColor: theme.colorScheme.secondary,
                  barRadius: const Radius.circular(4),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          
          // Question text
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              currentQuestion['question'] as String,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
              ),
            ),
          ),
          
          // Question type indicator
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _getQuestionTypeColor(questionType).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getQuestionTypeColor(questionType).withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Text(
                _getQuestionTypeLabel(questionType),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          // Options
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: options.map((option) {
                final optionId = option['id'] as String;
                final optionText = option['text'] as String;
                final isSelected = selectedAnswerIds.contains(optionId);
                
                // Determine option color based on selection and correctness
                Color optionColor = Colors.white.withOpacity(0.1);
                
                if (isAnswered) {
                  if (correctOptionIds.contains(optionId)) {
                    optionColor = Colors.green.withOpacity(0.3);
                  } else if (isSelected) {
                    optionColor = Colors.red.withOpacity(0.3);
                  }
                } else if (isSelected) {
                  optionColor = theme.colorScheme.secondary.withOpacity(0.3);
                }
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: BouncingWidget(
                    onTap: () {
                      if (!isAnswered) {
                        _selectAnswer(questionId, optionId);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: optionColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.secondary.withOpacity(0.5)
                              : Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: questionType == 'multipleChoice'
                                  ? BoxShape.circle
                                  : BoxShape.rectangle,
                              borderRadius: questionType == 'multipleAnswer'
                                  ? BorderRadius.circular(4)
                                  : null,
                              border: Border.all(
                                color: isSelected
                                    ? theme.colorScheme.secondary
                                    : Colors.white.withOpacity(0.5),
                                width: 2,
                              ),
                              color: isSelected
                                  ? theme.colorScheme.secondary.withOpacity(0.5)
                                  : Colors.transparent,
                            ),
                            child: isSelected
                                ? Icon(
                                    questionType == 'multipleChoice'
                                        ? Icons.circle
                                        : Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              optionText,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                          if (isAnswered && correctOptionIds.contains(optionId))
                            const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 20,
                            ),
                          if (isAnswered && isSelected && !correctOptionIds.contains(optionId))
                            const Icon(
                              Icons.cancel,
                              color: Colors.red,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          // Explanation
          if (_showExplanation)
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return SizeTransition(
                  sizeFactor: CurvedAnimation(
                    parent: _animationController,
                    curve: Curves.easeOut,
                  ),
                  child: child,
                );
              },
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isCorrect
                      ? Colors.green.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isCorrect
                        ? Colors.green.withOpacity(0.5)
                        : Colors.red.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isCorrect ? Icons.check_circle : Icons.cancel,
                          color: isCorrect ? Colors.green : Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isCorrect ? 'Correct!' : 'Incorrect',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: isCorrect ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    MarkdownBody(
                      data: explanation,
                      styleSheet: MarkdownStyleSheet(
                        p: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Navigation buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Previous button
                AnimatedGlassmorphicButton(
                  width: 100,
                  height: 40,
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: 8,
                  onPressed: _currentQuestionIndex > 0 ? _previousQuestion : null,
                  isEnabled: _currentQuestionIndex > 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Previous',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Retry button (shown when completed)
                if (_isCompleted)
                  AnimatedGlassmorphicButton(
                    width: 100,
                    height: 40,
                    color: theme.colorScheme.secondary,
                    borderRadius: 8,
                    onPressed: _retryQuiz,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.refresh,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Retry',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Next button
                AnimatedGlassmorphicButton(
                  width: 100,
                  height: 40,
                  color: theme.colorScheme.secondary,
                  borderRadius: 8,
                  onPressed: _currentQuestionIndex < questions.length - 1 ? _nextQuestion : null,
                  isEnabled: _currentQuestionIndex < questions.length - 1,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Next',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getQuestionTypeColor(String type) {
    switch (type) {
      case 'multipleChoice':
        return Colors.blue;
      case 'multipleAnswer':
        return Colors.purple;
      case 'trueFalse':
        return Colors.green;
      case 'fillInBlank':
        return Colors.orange;
      case 'matching':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
  
  String _getQuestionTypeLabel(String type) {
    switch (type) {
      case 'multipleChoice':
        return 'Multiple Choice';
      case 'multipleAnswer':
        return 'Multiple Answer';
      case 'trueFalse':
        return 'True/False';
      case 'fillInBlank':
        return 'Fill in the Blank';
      case 'matching':
        return 'Matching';
      default:
        return 'Question';
    }
  }
}
