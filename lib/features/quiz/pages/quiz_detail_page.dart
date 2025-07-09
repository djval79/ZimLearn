import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:confetti/confetti.dart';

import '../../../core/constants.dart';
import '../../../core/services/service_locator.dart';
import '../../../data/models/quiz.dart';
import '../../../data/models/user.dart';
import '../../common/widgets/glassmorphic_widgets.dart';
import '../../common/widgets/kids_animation_widgets.dart';
import '../bloc/quiz_bloc.dart';
import '../widgets/question_widgets.dart';
import 'quiz_result_page.dart';

class QuizDetailPage extends StatefulWidget {
  final Quiz quiz;
  final bool isYoungerChild;
  final bool isTimed;
  final QuizDifficulty difficulty;
  
  const QuizDetailPage({
    Key? key,
    required this.quiz,
    this.isYoungerChild = false,
    this.isTimed = true,
    this.difficulty = QuizDifficulty.medium,
  }) : super(key: key);

  @override
  State<QuizDetailPage> createState() => _QuizDetailPageState();
}

class _QuizDetailPageState extends State<QuizDetailPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late PageController _pageController;
  late ConfettiController _confettiController;
  
  // Timer related variables
  Timer? _quizTimer;
  int _remainingSeconds = 0;
  int _totalTimeSeconds = 0;
  bool _isTimerPaused = false;
  
  // Quiz state
  int _currentQuestionIndex = 0;
  List<QuizAnswer> _userAnswers = [];
  bool _quizCompleted = false;
  bool _isSubmitting = false;
  int _score = 0;
  int _maxScore = 0;
  int _hintsUsed = 0;
  int _maxHints = 0;
  
  // Question feedback
  bool _showFeedback = false;
  bool _isCorrect = false;
  String _feedbackMessage = '';
  
  // Difficulty multipliers
  final Map<QuizDifficulty, double> _difficultyTimeMultiplier = {
    QuizDifficulty.easy: 1.5,
    QuizDifficulty.medium: 1.0,
    QuizDifficulty.hard: 0.7,
    QuizDifficulty.expert: 0.5,
  };
  
  final Map<QuizDifficulty, int> _difficultyHintsMultiplier = {
    QuizDifficulty.easy: 3,
    QuizDifficulty.medium: 2,
    QuizDifficulty.hard: 1,
    QuizDifficulty.expert: 0,
  };
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..forward();
    
    _pageController = PageController();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    
    // Initialize user answers
    _userAnswers = List.generate(
      widget.quiz.questions.length,
      (index) => QuizAnswer(
        questionId: widget.quiz.questions[index].id,
        selectedOptionIds: [],
        textAnswer: '',
        isCorrect: false,
        timeTaken: 0,
      ),
    );
    
    // Calculate max score
    _maxScore = widget.quiz.questions.fold<int>(
      0,
      (sum, question) => sum + (question.points ?? 1),
    );
    
    // Set up timer if quiz is timed
    if (widget.isTimed) {
      _setupTimer();
    }
    
    // Set up hints based on difficulty
    _maxHints = widget.quiz.questions.length * 
      (_difficultyHintsMultiplier[widget.difficulty] ?? 0);
  }
  
  void _setupTimer() {
    // Calculate total time based on quiz length and difficulty
    final baseTimePerQuestion = 30; // 30 seconds per question
    final totalQuestions = widget.quiz.questions.length;
    final difficultyMultiplier = _difficultyTimeMultiplier[widget.difficulty] ?? 1.0;
    
    _totalTimeSeconds = (baseTimePerQuestion * totalQuestions * difficultyMultiplier).round();
    _remainingSeconds = _totalTimeSeconds;
    
    // Start timer
    _quizTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isTimerPaused) {
        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
          } else {
            // Time's up - submit quiz
            _submitQuiz(true);
            timer.cancel();
          }
        });
      }
    });
  }
  
  void _pauseTimer() {
    setState(() {
      _isTimerPaused = true;
    });
  }
  
  void _resumeTimer() {
    setState(() {
      _isTimerPaused = false;
    });
  }
  
  void _useHint() {
    if (_hintsUsed < _maxHints) {
      setState(() {
        _hintsUsed++;
      });
      
      // Show hint for current question
      final currentQuestion = widget.quiz.questions[_currentQuestionIndex];
      String hintText = '';
      
      switch (currentQuestion.type) {
        case QuestionType.multipleChoice:
          // Eliminate one wrong option
          final correctOptionId = currentQuestion.correctOptionIds.first;
          final wrongOptions = currentQuestion.options
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
          hintText = 'Hint: There are ${currentQuestion.correctOptionIds.length} correct answers.';
          break;
        case QuestionType.fillInBlank:
          // Give first letter hint
          final answer = currentQuestion.correctAnswer ?? '';
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
      
      // Show hint dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          title: const Text(
            'Hint',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            hintText,
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Got it',
                style: TextStyle(color: Colors.amber),
              ),
            ),
          ],
        ),
      );
    } else {
      // No hints left
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hints remaining!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _submitQuiz(bool isTimeUp) {
    if (_isSubmitting) return;
    
    setState(() {
      _isSubmitting = true;
      _quizCompleted = true;
    });
    
    // Calculate score
    int totalScore = 0;
    for (int i = 0; i < widget.quiz.questions.length; i++) {
      final question = widget.quiz.questions[i];
      final answer = _userAnswers[i];
      
      bool isCorrect = false;
      
      switch (question.type) {
        case QuestionType.multipleChoice:
        case QuestionType.trueFalse:
          isCorrect = answer.selectedOptionIds.isNotEmpty &&
              answer.selectedOptionIds.first == question.correctOptionIds.first;
          break;
        case QuestionType.multipleAnswer:
          // All correct options must be selected and no incorrect ones
          isCorrect = answer.selectedOptionIds.length == question.correctOptionIds.length &&
              answer.selectedOptionIds.every((id) => question.correctOptionIds.contains(id));
          break;
        case QuestionType.fillInBlank:
          isCorrect = answer.textAnswer.trim().toLowerCase() ==
              (question.correctAnswer ?? '').toLowerCase();
          break;
        case QuestionType.matching:
        case QuestionType.ordering:
          // These would require more complex validation in a real app
          isCorrect = answer.isCorrect;
          break;
        default:
          isCorrect = false;
      }
      
      // Update answer with correct status
      _userAnswers[i] = answer.copyWith(isCorrect: isCorrect);
      
      // Add points if correct
      if (isCorrect) {
        totalScore += question.points ?? 1;
      }
    }
    
    setState(() {
      _score = totalScore;
    });
    
    // Cancel timer if active
    _quizTimer?.cancel();
    
    // Create quiz attempt
    final attempt = QuizAttempt(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      quizId: widget.quiz.id,
      userId: 'current_user_id', // In a real app, get from auth service
      answers: _userAnswers,
      score: _score,
      maxScore: _maxScore,
      timeTaken: _totalTimeSeconds - _remainingSeconds,
      completedAt: DateTime.now(),
      hintsUsed: _hintsUsed,
    );
    
    // In a real app, dispatch to bloc
    // context.read<QuizBloc>().add(SubmitQuizAttempt(attempt: attempt));
    
    // Show completion animation
    if (_score >= _maxScore * 0.7) {
      // Good score - show celebration
      _confettiController.play();
    }
    
    // Navigate to results page after a short delay
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => QuizResultPage(
            quiz: widget.quiz,
            attempt: attempt,
            isYoungerChild: widget.isYoungerChild,
          ),
        ),
      );
    });
  }
  
  void _answerQuestion({
    List<String>? selectedOptionIds,
    String? textAnswer,
    bool? isCorrect,
  }) {
    if (_currentQuestionIndex < _userAnswers.length) {
      final currentAnswer = _userAnswers[_currentQuestionIndex];
      final updatedAnswer = currentAnswer.copyWith(
        selectedOptionIds: selectedOptionIds ?? currentAnswer.selectedOptionIds,
        textAnswer: textAnswer ?? currentAnswer.textAnswer,
        isCorrect: isCorrect ?? currentAnswer.isCorrect,
      );
      
      setState(() {
        _userAnswers[_currentQuestionIndex] = updatedAnswer;
      });
      
      // Check if answer is correct for immediate feedback
      final currentQuestion = widget.quiz.questions[_currentQuestionIndex];
      bool isAnswerCorrect = false;
      
      switch (currentQuestion.type) {
        case QuestionType.multipleChoice:
        case QuestionType.trueFalse:
          isAnswerCorrect = updatedAnswer.selectedOptionIds.isNotEmpty &&
              updatedAnswer.selectedOptionIds.first == currentQuestion.correctOptionIds.first;
          break;
        case QuestionType.multipleAnswer:
          isAnswerCorrect = updatedAnswer.selectedOptionIds.length == currentQuestion.correctOptionIds.length &&
              updatedAnswer.selectedOptionIds.every((id) => currentQuestion.correctOptionIds.contains(id));
          break;
        case QuestionType.fillInBlank:
          isAnswerCorrect = updatedAnswer.textAnswer.trim().toLowerCase() ==
              (currentQuestion.correctAnswer ?? '').toLowerCase();
          break;
        case QuestionType.matching:
        case QuestionType.ordering:
          isAnswerCorrect = isCorrect ?? false;
          break;
        default:
          isAnswerCorrect = false;
      }
      
      // Show feedback if enabled
      if (widget.quiz.showFeedbackAfterEachQuestion) {
        _showAnswerFeedback(isAnswerCorrect, currentQuestion);
      } else {
        // Move to next question automatically
        _moveToNextQuestion();
      }
    }
  }
  
  void _showAnswerFeedback(bool isCorrect, QuizQuestion question) {
    setState(() {
      _showFeedback = true;
      _isCorrect = isCorrect;
      _feedbackMessage = isCorrect
          ? question.correctFeedback ?? 'Correct!'
          : question.incorrectFeedback ?? 'Incorrect. Try again!';
      _isTimerPaused = true; // Pause timer during feedback
    });
    
    // Auto-dismiss feedback after a few seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showFeedback = false;
          _isTimerPaused = false; // Resume timer
        });
        
        // Move to next question after feedback
        if (isCorrect || !widget.quiz.allowRetryWrongAnswers) {
          _moveToNextQuestion();
        }
      }
    });
  }
  
  void _moveToNextQuestion() {
    if (_currentQuestionIndex < widget.quiz.questions.length - 1) {
      // Move to next question
      setState(() {
        _currentQuestionIndex++;
      });
      
      _pageController.animateToPage(
        _currentQuestionIndex,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      // All questions answered - submit quiz
      _submitQuiz(false);
    }
  }
  
  void _moveToPreviousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
      
      _pageController.animateToPage(
        _currentQuestionIndex,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    _confettiController.dispose();
    _quizTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassmorphicAppBar(
        title: widget.quiz.title,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            // Show confirmation dialog before exiting quiz
            _showExitConfirmation(context);
          },
        ),
        actions: [
          if (widget.isTimed) ...[
            // Timer display
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: _buildTimerDisplay(theme),
            ),
          ],
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
              // Confetti animation for completion
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
              Column(
                children: [
                  // Progress indicator
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Question ${_currentQuestionIndex + 1} of ${widget.quiz.questions.length}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                            const Spacer(),
                            if (_maxHints > 0) ...[
                              InkWell(
                                onTap: _useHint,
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.lightbulb_outline,
                                      color: _hintsUsed < _maxHints
                                          ? Colors.amber
                                          : Colors.grey,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Hints: ${_maxHints - _hintsUsed}/${_maxHints}',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: _hintsUsed < _maxHints
                                            ? Colors.amber
                                            : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        widget.isYoungerChild
                            ? RainbowProgressIndicator(
                                percent: (_currentQuestionIndex + 1) / widget.quiz.questions.length,
                                height: 12,
                              )
                            : LinearPercentIndicator(
                                percent: (_currentQuestionIndex + 1) / widget.quiz.questions.length,
                                lineHeight: 8,
                                animation: true,
                                animationDuration: 500,
                                backgroundColor: Colors.white.withOpacity(0.2),
                                progressColor: theme.colorScheme.secondary,
                                barRadius: const Radius.circular(4),
                                padding: EdgeInsets.zero,
                              ),
                      ],
                    ),
                  ),
                  
                  // Quiz questions
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.quiz.questions.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentQuestionIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        final question = widget.quiz.questions[index];
                        return _buildQuestionWidget(question, theme);
                      },
                    ),
                  ),
                  
                  // Navigation buttons
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Previous button
                        if (_currentQuestionIndex > 0)
                          Expanded(
                            child: AnimatedGlassmorphicButton(
                              height: 50,
                              onPressed: _moveToPreviousQuestion,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.arrow_back_ios,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Previous',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          const Spacer(),
                        
                        const SizedBox(width: 16),
                        
                        // Next/Submit button
                        Expanded(
                          child: AnimatedGlassmorphicButton(
                            height: 50,
                            color: _currentQuestionIndex == widget.quiz.questions.length - 1
                                ? theme.colorScheme.secondary
                                : null,
                            onPressed: () {
                              if (_currentQuestionIndex == widget.quiz.questions.length - 1) {
                                // Last question - submit quiz
                                _submitQuiz(false);
                              } else {
                                // Move to next question
                                _moveToNextQuestion();
                              }
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _currentQuestionIndex == widget.quiz.questions.length - 1
                                      ? 'Submit'
                                      : 'Next',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  _currentQuestionIndex == widget.quiz.questions.length - 1
                                      ? Icons.check
                                      : Icons.arrow_forward_ios,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // Feedback overlay
              if (_showFeedback)
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      color: Colors.black.withOpacity(0.5),
                      child: Center(
                        child: GlassmorphicCard(
                          width: 300,
                          height: 200,
                          color: _isCorrect
                              ? Colors.green.withOpacity(0.3)
                              : Colors.red.withOpacity(0.3),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isCorrect ? Icons.check_circle : Icons.cancel,
                                color: _isCorrect ? Colors.green : Colors.red,
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _isCorrect ? 'Correct!' : 'Incorrect',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  _feedbackMessage,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              
              // Loading overlay
              if (_isSubmitting && !_showFeedback)
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      color: Colors.black.withOpacity(0.5),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Submitting quiz...',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTimerDisplay(ThemeData theme) {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    
    // Determine color based on remaining time
    Color timerColor = Colors.white;
    if (_remainingSeconds < _totalTimeSeconds * 0.25) {
      timerColor = Colors.red;
    } else if (_remainingSeconds < _totalTimeSeconds * 0.5) {
      timerColor = Colors.orange;
    }
    
    return Row(
      children: [
        Icon(
          Icons.timer,
          color: timerColor,
          size: 20,
        ),
        const SizedBox(width: 4),
        Text(
          '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
          style: theme.textTheme.titleMedium?.copyWith(
            color: timerColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  Widget _buildQuestionWidget(QuizQuestion question, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question card
          GlassmorphicCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question type badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getQuestionTypeText(question.type),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Question text
                  widget.isYoungerChild
                      ? DancingLetters(
                          text: question.text,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : Text(
                          question.text,
                          style: theme.textTheme.titleLarge?.copyWith(
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
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 200,
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
                  
                  if (question.description != null && question.description!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      question.description!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Answer options based on question type
          _buildAnswerOptions(question, theme),
        ],
      ),
    );
  }
  
  Widget _buildAnswerOptions(QuizQuestion question, ThemeData theme) {
    switch (question.type) {
      case QuestionType.multipleChoice:
      case QuestionType.trueFalse:
        return _buildMultipleChoiceOptions(question, theme);
      case QuestionType.multipleAnswer:
        return _buildMultipleAnswerOptions(question, theme);
      case QuestionType.fillInBlank:
        return _buildFillInBlankInput(question, theme);
      case QuestionType.matching:
        return _buildMatchingOptions(question, theme);
      case QuestionType.ordering:
        return _buildOrderingOptions(question, theme);
      default:
        return Center(
          child: Text(
            'Unsupported question type',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white70,
            ),
          ),
        );
    }
  }
  
  Widget _buildMultipleChoiceOptions(QuizQuestion question, ThemeData theme) {
    final currentAnswer = _userAnswers[_currentQuestionIndex];
    
    return Column(
      children: question.options.map((option) {
        final isSelected = currentAnswer.selectedOptionIds.contains(option.id);
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () {
              _answerQuestion(selectedOptionIds: [option.id]);
            },
            child: GlassmorphicCard(
              height: 70,
              color: isSelected
                  ? theme.colorScheme.secondary.withOpacity(0.3)
                  : Colors.white.withOpacity(0.1),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: isSelected
                        ? theme.colorScheme.secondary
                        : Colors.white,
                  ),
                  const SizedBox(width: 16),
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
            ),
          ),
        );
      }).toList(),
    );
  }
  
  Widget _buildMultipleAnswerOptions(QuizQuestion question, ThemeData theme) {
    final currentAnswer = _userAnswers[_currentQuestionIndex];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select all that apply:',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white70,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 12),
        ...question.options.map((option) {
          final isSelected = currentAnswer.selectedOptionIds.contains(option.id);
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () {
                List<String> updatedSelections = List.from(currentAnswer.selectedOptionIds);
                if (isSelected) {
                  updatedSelections.remove(option.id);
                } else {
                  updatedSelections.add(option.id);
                }
                _answerQuestion(selectedOptionIds: updatedSelections);
              },
              child: GlassmorphicCard(
                height: 70,
                color: isSelected
                    ? theme.colorScheme.secondary.withOpacity(0.3)
                    : Colors.white.withOpacity(0.1),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    Icon(
                      isSelected
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      color: isSelected
                          ? theme.colorScheme.secondary
                          : Colors.white,
                    ),
                    const SizedBox(width: 16),
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
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
  
  Widget _buildFillInBlankInput(QuizQuestion question, ThemeData theme) {
    final currentAnswer = _userAnswers[_currentQuestionIndex];
    final TextEditingController textController = TextEditingController(text: currentAnswer.textAnswer);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Type your answer:',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white70,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 12),
        GlassmorphicCard(
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: TextField(
              controller: textController,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.white,
              ),
              decoration: InputDecoration(
                hintText: 'Enter your answer here...',
                hintStyle: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white54,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                _answerQuestion(textAnswer: value);
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        AnimatedGlassmorphicButton(
          onPressed: () {
            // Check answer
            final isCorrect = textController.text.trim().toLowerCase() ==
                (question.correctAnswer ?? '').toLowerCase();
            _answerQuestion(
              textAnswer: textController.text,
              isCorrect: isCorrect,
            );
          },
          child: Text(
            'Check Answer',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildMatchingOptions(QuizQuestion question, ThemeData theme) {
    // In a real app, this would be a more complex matching UI
    // For this example, we'll use a simplified version
    return Center(
      child: Column(
        children: [
          Text(
            'Matching questions would have a drag-and-drop interface here',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          AnimatedGlassmorphicButton(
            onPressed: () {
              // Simulate matching answer
              _answerQuestion(
                isCorrect: math.Random().nextBool(),
              );
            },
            child: Text(
              'Simulate Answer',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildOrderingOptions(QuizQuestion question, ThemeData theme) {
    // In a real app, this would be a reorderable list
    // For this example, we'll use a simplified version
    return Center(
      child: Column(
        children: [
          Text(
            'Ordering questions would have a drag-to-reorder interface here',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          AnimatedGlassmorphicButton(
            onPressed: () {
              // Simulate ordering answer
              _answerQuestion(
                isCorrect: math.Random().nextBool(),
              );
            },
            child: Text(
              'Simulate Answer',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _getQuestionTypeText(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoice:
        return 'Multiple Choice';
      case QuestionType.trueFalse:
        return 'True/False';
      case QuestionType.multipleAnswer:
        return 'Multiple Answer';
      case QuestionType.fillInBlank:
        return 'Fill in the Blank';
      case QuestionType.matching:
        return 'Matching';
      case QuestionType.ordering:
        return 'Ordering';
      default:
        return 'Question';
    }
  }
  
  void _showExitConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        title: const Text(
          'Exit Quiz?',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Your progress will be lost. Are you sure you want to exit?',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Exit quiz
            },
            child: const Text(
              'Exit',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
