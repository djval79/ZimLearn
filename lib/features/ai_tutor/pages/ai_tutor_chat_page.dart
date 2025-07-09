import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:lottie/lottie.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/services/ai_tutor_service.dart';
import '../../../core/models/learning_style.dart';
import '../../../data/models/user.dart';
import '../../../data/models/lesson.dart';
import '../../../data/models/quiz.dart';
import '../../common/widgets/glassmorphic_widgets.dart';
import '../../lessons/pages/lesson_detail_page.dart';
import '../../quiz/pages/quiz_detail_page.dart';
import '../bloc/ai_tutor_bloc.dart';
import '../widgets/practice_question_card.dart';
import '../widgets/study_plan_card.dart';

class AiTutorChatPage extends StatefulWidget {
  final String? lessonId;
  final String? quizId;
  final String? subject;
  final User user;
  
  const AiTutorChatPage({
    Key? key,
    this.lessonId,
    this.quizId,
    this.subject,
    required this.user,
  }) : super(key: key);

  @override
  State<AiTutorChatPage> createState() => _AiTutorChatPageState();
}

class _AiTutorChatPageState extends State<AiTutorChatPage> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;
  late AnimationController _typingAnimationController;
  
  String _selectedSubject = '';
  TutorPersonality _selectedPersonality = TutorPersonality.encouraging;
  bool _isTyping = false;
  bool _showSubjectSelector = false;
  bool _showPersonalitySelector = false;
  bool _showQuickActions = true;
  TutoringSession? _activeSession;
  
  // For real-time response streaming simulation
  String _currentStreamingResponse = '';
  Timer? _streamingTimer;
  bool _isStreaming = false;
  
  // Mock user for demonstration
  final User _mockUser = User(
    id: '1',
    username: 'tafadzwa',
    email: 'tafadzwa@example.com',
    firstName: 'Tafadzwa',
    lastName: 'Moyo',
    gradeLevel: 'primary_4_7',
    preferredLanguage: 'en',
    region: 'harare',
    subscription: UserSubscription.basic,
    preferences: const UserPreferences(),
    createdAt: DateTime.now().subtract(const Duration(days: 30)),
    updatedAt: DateTime.now(),
  );
  
  // Mock learning style
  LearningStyle _learningStyle = LearningStyle();
  
  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..forward();
    
    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
    
    // Set initial subject from props or default to mathematics
    _selectedSubject = widget.subject ?? 'mathematics';
    
    // Start session automatically if subject is provided
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSession();
    });
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    _typingAnimationController.dispose();
    _streamingTimer?.cancel();
    super.dispose();
  }
  
  Future<void> _initializeSession() async {
    final aiTutorBloc = context.read<AiTutorBloc>();
    
    // Check if we have an active session
    final state = aiTutorBloc.state;
    
    if (state is AiTutorActiveSession) {
      setState(() {
        _activeSession = state.session;
      });
      return;
    }
    
    // Start new session
    aiTutorBloc.add(StartTutoringSession(
      userId: widget.user.id,
      subject: _selectedSubject,
      lessonId: widget.lessonId,
      quizId: widget.quizId,
      personality: _selectedPersonality,
      language: widget.user.preferredLanguage ?? 'en',
      learningStyle: _learningStyle,
    ));
  }
  
  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty || _activeSession == null) return;
    
    // Clear input
    _messageController.clear();
    
    // Determine request type based on message content
    final requestType = _determineRequestType(message);
    
    // Send message
    context.read<AiTutorBloc>().add(SendTutoringMessage(
      sessionId: _activeSession!.id,
      content: message,
      requestType: requestType,
    ));
    
    // Show typing indicator
    setState(() {
      _isTyping = true;
    });
    
    // Simulate streaming response
    _simulateStreamingResponse();
    
    // Scroll to bottom after a short delay
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollToBottom();
    });
  }
  
  TutorRequestType _determineRequestType(String message) {
    final lowerMessage = message.toLowerCase();
    
    if (lowerMessage.contains('explain') || 
        lowerMessage.contains('what is') || 
        lowerMessage.contains('how does') ||
        lowerMessage.contains('tell me about')) {
      return TutorRequestType.conceptExplanation;
    } else if (lowerMessage.contains('solve') || 
               lowerMessage.contains('calculate') || 
               lowerMessage.contains('find the')) {
      return TutorRequestType.problemSolving;
    } else if (lowerMessage.contains('practice') || 
               lowerMessage.contains('quiz me') || 
               lowerMessage.contains('test me')) {
      return TutorRequestType.practiceQuestions;
    } else if (lowerMessage.contains('study plan') || 
               lowerMessage.contains('schedule') || 
               lowerMessage.contains('timetable')) {
      return TutorRequestType.studyPlanning;
    } else if (lowerMessage.contains('motivate') || 
               lowerMessage.contains('encourage')) {
      return TutorRequestType.motivation;
    } else if (lowerMessage.contains('exam') || 
               lowerMessage.contains('test prep')) {
      return TutorRequestType.examPreparation;
    } else if (lowerMessage.contains('overview') || 
               lowerMessage.contains('summary')) {
      return TutorRequestType.subjectOverview;
    } else if (widget.lessonId != null) {
      return TutorRequestType.lessonHelp;
    } else if (widget.quizId != null) {
      return TutorRequestType.quizHelp;
    } else {
      return TutorRequestType.quickQuestion;
    }
  }
  
  void _simulateStreamingResponse() {
    // Cancel any existing streaming
    _streamingTimer?.cancel();
    
    // Reset streaming state
    setState(() {
      _currentStreamingResponse = '';
      _isStreaming = true;
    });
    
    // Mock response to stream
    const mockResponse = 'I\'ll help you understand this concept. Let\'s break it down step by step so it\'s easier to grasp. First, we need to understand the basic principles involved. Then we can explore how they apply in different contexts. Does that approach work for you?';
    
    // Stream the response character by character
    int index = 0;
    _streamingTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (index < mockResponse.length) {
        setState(() {
          _currentStreamingResponse += mockResponse[index];
        });
        index++;
      } else {
        // End streaming
        setState(() {
          _isStreaming = false;
        });
        timer.cancel();
      }
    });
  }
  
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
  
  void _endSession() {
    if (_activeSession == null) return;
    
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.8),
        title: const Text(
          'End Session',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to end this tutoring session?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AiTutorBloc>().add(EndTutoringSession(
                sessionId: _activeSession!.id,
              ));
              Navigator.pop(context); // Return to previous screen
            },
            child: const Text('End Session'),
          ),
        ],
      ),
    );
  }
  
  void _selectSubject(String subject) {
    setState(() {
      _selectedSubject = subject;
      _showSubjectSelector = false;
    });
    
    // If we have an active session, end it before starting a new one
    if (_activeSession != null) {
      context.read<AiTutorBloc>().add(EndTutoringSession(
        sessionId: _activeSession!.id,
      ));
    }
    
    // Start new session with selected subject
    context.read<AiTutorBloc>().add(StartTutoringSession(
      userId: widget.user.id,
      subject: subject,
      personality: _selectedPersonality,
      language: widget.user.preferredLanguage ?? 'en',
      learningStyle: _learningStyle,
    ));
  }
  
  void _selectPersonality(TutorPersonality personality) {
    setState(() {
      _selectedPersonality = personality;
      _showPersonalitySelector = false;
    });
    
    // If we have an active session, end it before starting a new one
    if (_activeSession != null) {
      context.read<AiTutorBloc>().add(EndTutoringSession(
        sessionId: _activeSession!.id,
      ));
    }
    
    // Start new session with selected personality
    context.read<AiTutorBloc>().add(StartTutoringSession(
      userId: widget.user.id,
      subject: _selectedSubject,
      personality: personality,
      language: widget.user.preferredLanguage ?? 'en',
      learningStyle: _learningStyle,
    ));
  }
  
  void _sendQuickAction(TutorRequestType requestType, String message) {
    if (_activeSession == null) return;
    
    // Send message
    context.read<AiTutorBloc>().add(SendTutoringMessage(
      sessionId: _activeSession!.id,
      content: message,
      requestType: requestType,
    ));
    
    // Show typing indicator
    setState(() {
      _isTyping = true;
    });
    
    // Simulate streaming response
    _simulateStreamingResponse();
    
    // Scroll to bottom after a short delay
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollToBottom();
    });
  }
  
  void _createStudyPlan() {
    if (_activeSession == null) return;
    
    // Show study plan creation dialog
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildStudyPlanCreationSheet(),
    );
  }
  
  Widget _buildStudyPlanCreationSheet() {
    final theme = Theme.of(context);
    
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Create Study Plan',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Subject Distribution',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Subject distribution sliders
                    _buildSubjectDistributionSlider(
                      'Mathematics',
                      Colors.green,
                      0.5,
                    ),
                    _buildSubjectDistributionSlider(
                      'English',
                      Colors.yellow,
                      0.3,
                    ),
                    _buildSubjectDistributionSlider(
                      'Science',
                      Colors.red,
                      0.7,
                    ),
                    _buildSubjectDistributionSlider(
                      'History',
                      Colors.purple,
                      0.2,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    Text(
                      'Plan Duration',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Duration selection
                    Row(
                      children: [
                        _buildDurationOption('1 Week', true),
                        const SizedBox(width: 16),
                        _buildDurationOption('2 Weeks', false),
                        const SizedBox(width: 16),
                        _buildDurationOption('1 Month', false),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    Text(
                      'Daily Study Time',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Study time selection
                    Row(
                      children: [
                        _buildStudyTimeOption('1 Hour', false),
                        const SizedBox(width: 16),
                        _buildStudyTimeOption('2 Hours', true),
                        const SizedBox(width: 16),
                        _buildStudyTimeOption('3 Hours', false),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: AnimatedGlassmorphicButton(
                onPressed: () {
                  Navigator.pop(context);
                  
                  // Create study plan
                  if (_activeSession != null) {
                    _sendQuickAction(
                      TutorRequestType.studyPlanning,
                      'Please create a study plan for me focusing on Mathematics, English, and Science for the next 2 weeks with 2 hours of study per day.',
                    );
                  }
                },
                child: const Text(
                  'Create Plan',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSubjectDistributionSlider(String subject, Color color, double initialValue) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subject,
            style: const TextStyle(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: color,
              inactiveTrackColor: Colors.white.withOpacity(0.2),
              thumbColor: Colors.white,
              trackHeight: 4,
            ),
            child: Slider(
              value: initialValue,
              onChanged: (value) {
                // In a real app, we would update the state
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDurationOption(String text, bool isSelected) {
    return Expanded(
      child: BouncingWidget(
        onTap: () {
          // In a real app, we would update the state
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected 
                ? Theme.of(context).colorScheme.secondary.withOpacity(0.3)
                : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.secondary
                  : Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
  
  Widget _buildStudyTimeOption(String text, bool isSelected) {
    return Expanded(
      child: BouncingWidget(
        onTap: () {
          // In a real app, we would update the state
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected 
                ? Theme.of(context).colorScheme.secondary.withOpacity(0.3)
                : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.secondary
                  : Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isYoungerChild = widget.user.gradeLevel == 'ecd' || 
                           widget.user.gradeLevel == 'primary_1_3';
    
    return BlocConsumer<AiTutorBloc, AiTutorState>(
      listener: (context, state) {
        if (state is AiTutorActiveSession) {
          setState(() {
            _activeSession = state.session;
            _isTyping = false;
          });
          
          // Scroll to bottom after a short delay
          Future.delayed(const Duration(milliseconds: 100), () {
            _scrollToBottom();
          });
        } else if (state is AiTutorMessageSent) {
          setState(() {
            _isTyping = false;
          });
          
          // Scroll to bottom after a short delay
          Future.delayed(const Duration(milliseconds: 100), () {
            _scrollToBottom();
          });
        } else if (state is AiTutorError) {
          // Show error snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: GlassmorphicAppBar(
            title: _getAppBarTitle(),
            centerTitle: true,
            actions: [
              // Subject selector button
              IconButton(
                icon: const Icon(Icons.book_outlined, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _showSubjectSelector = !_showSubjectSelector;
                    _showPersonalitySelector = false;
                  });
                },
              ),
              // Tutor personality button
              IconButton(
                icon: const Icon(Icons.psychology_outlined, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _showPersonalitySelector = !_showPersonalitySelector;
                    _showSubjectSelector = false;
                  });
                },
              ),
              // End session button
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: _endSession,
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
              child: Column(
                children: [
                  // Subject selector
                  if (_showSubjectSelector)
                    _buildSubjectSelector(),
                  
                  // Personality selector
                  if (_showPersonalitySelector)
                    _buildPersonalitySelector(),
                  
                  // Messages list
                  Expanded(
                    child: _buildMessagesList(isYoungerChild),
                  ),
                  
                  // Quick actions
                  if (_showQuickActions)
                    _buildQuickActions(),
                  
                  // Input bar
                  _buildInputBar(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  String _getAppBarTitle() {
    if (_activeSession == null) {
      return 'AI Tutor';
    }
    
    String subjectName = '';
    switch (_activeSession!.subject) {
      case 'mathematics':
        subjectName = 'Mathematics';
        break;
      case 'english':
        subjectName = 'English';
        break;
      case 'science':
        subjectName = 'Science';
        break;
      case 'history':
        subjectName = 'History';
        break;
      case 'geography':
        subjectName = 'Geography';
        break;
      default:
        subjectName = _activeSession!.subject.substring(0, 1).toUpperCase() + 
                      _activeSession!.subject.substring(1);
    }
    
    return '$subjectName Tutor';
  }
  
  Widget _buildSubjectSelector() {
    final theme = Theme.of(context);
    
    final subjects = [
      {'id': 'mathematics', 'name': 'Mathematics', 'icon': Icons.calculate},
      {'id': 'english', 'name': 'English', 'icon': Icons.menu_book},
      {'id': 'science', 'name': 'Science', 'icon': Icons.science},
      {'id': 'history', 'name': 'History', 'icon': Icons.history_edu},
      {'id': 'geography', 'name': 'Geography', 'icon': Icons.public},
      {'id': 'agriculture', 'name': 'Agriculture', 'icon': Icons.grass},
    ];
    
    return Container(
      color: Colors.black.withOpacity(0.5),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: subjects.map((subject) {
            final isSelected = _selectedSubject == subject['id'];
            
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: BouncingWidget(
                onTap: () => _selectSubject(subject['id'] as String),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.secondary.withOpacity(0.3)
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.secondary
                          : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        subject['icon'] as IconData,
                        color: isSelected ? theme.colorScheme.secondary : Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        subject['name'] as String,
                        style: TextStyle(
                          color: isSelected ? theme.colorScheme.secondary : Colors.white70,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
  
  Widget _buildPersonalitySelector() {
    final theme = Theme.of(context);
    
    final personalities = [
      {'id': TutorPersonality.encouraging, 'name': 'Encouraging', 'icon': Icons.sentiment_satisfied},
      {'id': TutorPersonality.analytical, 'name': 'Analytical', 'icon': Icons.analytics},
      {'id': TutorPersonality.patient, 'name': 'Patient', 'icon': Icons.hourglass_bottom},
      {'id': TutorPersonality.challenging, 'name': 'Challenging', 'icon': Icons.fitness_center},
      {'id': TutorPersonality.creative, 'name': 'Creative', 'icon': Icons.palette},
      {'id': TutorPersonality.adaptable, 'name': 'Adaptable', 'icon': Icons.auto_fix_high},
    ];
    
    return Container(
      color: Colors.black.withOpacity(0.5),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: personalities.map((personality) {
            final isSelected = _selectedPersonality == personality['id'];
            
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: BouncingWidget(
                onTap: () => _selectPersonality(personality['id'] as TutorPersonality),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.secondary.withOpacity(0.3)
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.secondary
                          : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        personality['icon'] as IconData,
                        color: isSelected ? theme.colorScheme.secondary : Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        personality['name'] as String,
                        style: TextStyle(
                          color: isSelected ? theme.colorScheme.secondary : Colors.white70,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
  
  Widget _buildMessagesList(bool isYoungerChild) {
    if (_activeSession == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _activeSession!.messages.length + (_isTyping ? 1 : 0) + (_isStreaming ? 1 : 0),
      itemBuilder: (context, index) {
        // Show typing indicator
        if (_isTyping && index == _activeSession!.messages.length) {
          return _buildTypingIndicator();
        }
        
        // Show streaming message
        if (_isStreaming && index == _activeSession!.messages.length + (_isTyping ? 1 : 0)) {
          return _buildStreamingMessage();
        }
        
        // Show regular message
        final message = _activeSession!.messages[index];
        
        if (message.isFromTutor) {
          return _buildTutorMessage(message, isYoungerChild);
        } else {
          return _buildUserMessage(message);
        }
      },
    );
  }
  
  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: FadeTransition(
        opacity: _typingAnimationController,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStreamingMessage() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tutor avatar and name
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  child: const Icon(
                    Icons.smart_toy,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'AI Tutor',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Message content
            Text(
              _currentStreamingResponse,
              style: const TextStyle(
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTutorMessage(TutoringMessage message, bool isYoungerChild) {
    final theme = Theme.of(context);
    
    // Check if message contains practice questions
    final containsPracticeQuestions = message.metadata != null && 
                                     message.metadata!['responseType'] == 'practiceQuestions';
    
    // Check if message contains study plan
    final containsStudyPlan = message.metadata != null && 
                             message.metadata!['responseType'] == 'studyPlanning';
    
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tutor avatar and name
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: theme.colorScheme.secondary,
                    child: const Icon(
                      Icons.smart_toy,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AI Tutor',
                    style: TextStyle(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            // Message content
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: isYoungerChild
                  ? _buildKidFriendlyMessage(message.content)
                  : MarkdownBody(
                      data: message.content,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(color: Colors.white),
                        h1: TextStyle(color: theme.colorScheme.secondary),
                        h2: TextStyle(color: theme.colorScheme.secondary),
                        h3: TextStyle(color: theme.colorScheme.secondary),
                        strong: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        em: const TextStyle(
                          color: Colors.white70,
                          fontStyle: FontStyle.italic,
                        ),
                        blockquote: const TextStyle(
                          color: Colors.white70,
                          fontStyle: FontStyle.italic,
                        ),
                        code: TextStyle(
                          color: theme.colorScheme.secondary,
                          backgroundColor: Colors.black.withOpacity(0.3),
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
            ),
            
            // Practice questions card
            if (containsPracticeQuestions)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: PracticeQuestionCard(
                  message: message,
                  onAnswerSelected: (questionId, answerId) {
                    // Handle answer selection
                  },
                ),
              ),
            
            // Study plan card
            if (containsStudyPlan)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: StudyPlanCard(
                  message: message,
                  onSessionCompleted: (sessionId) {
                    // Handle session completion
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildKidFriendlyMessage(String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          content,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 16),
        // Add some fun elements for kids
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/cartoon_character.png',
              width: 80,
              height: 80,
              errorBuilder: (context, error, stackTrace) => 
                const Icon(Icons.sentiment_very_satisfied, color: Colors.amber, size: 80),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildUserMessage(TutoringMessage message) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          message.content,
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
      ),
    );
  }
  
  Widget _buildQuickActions() {
    final theme = Theme.of(context);
    
    final quickActions = [
      {
        'icon': Icons.help_outline,
        'label': 'Explain',
        'message': 'Can you explain this concept?',
        'type': TutorRequestType.conceptExplanation,
      },
      {
        'icon': Icons.quiz,
        'label': 'Practice',
        'message': 'Give me some practice questions.',
        'type': TutorRequestType.practiceQuestions,
      },
      {
        'icon': Icons.calendar_today,
        'label': 'Study Plan',
        'message': 'Create a study plan',
        'type': TutorRequestType.studyPlanning,
      },
      {
        'icon': Icons.psychology,
        'label': 'Motivate',
        'message': 'I need some motivation.',
        'type': TutorRequestType.motivation,
      },
    ];
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.black.withOpacity(0.3),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: quickActions.map((action) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: BouncingWidget(
                onTap: () {
                  if (action['label'] == 'Study Plan') {
                    _createStudyPlan();
                  } else {
                    _sendQuickAction(
                      action['type'] as TutorRequestType,
                      action['message'] as String,
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        action['icon'] as IconData,
                        color: theme.colorScheme.secondary,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        action['label'] as String,
                        style: TextStyle(
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
  
  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Quick actions toggle button
          IconButton(
            icon: Icon(
              _showQuickActions ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
              color: Colors.white70,
            ),
            onPressed: () {
              setState(() {
                _showQuickActions = !_showQuickActions;
              });
            },
          ),
          
          // Text input
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Ask your tutor...',
                  hintStyle: TextStyle(color: Colors.white60),
                  border: InputBorder.none,
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          
          // Send button
          IconButton(
            icon: const Icon(
              Icons.send,
              color: Colors.white,
            ),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}
