import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../core/constants.dart';
import '../../common/widgets/glassmorphic_widgets.dart';
import '../../common/widgets/kids_animation_widgets.dart';

/// Defines the types of interactive content available in lessons
enum InteractionType {
  dragDrop,
  matching,
  fillBlanks,
  multipleChoice,
  sorting,
  flashcards,
  puzzle,
  wordSearch,
  memoryGame,
  simulation,
}

/// A widget that displays interactive content for lessons.
///
/// This widget can render different types of educational interactions
/// based on the [interactionType] provided.
class InteractiveContentWidget extends StatefulWidget {
  /// The type of interaction to display
  final InteractionType interactionType;
  
  /// The title of the interactive content
  final String title;
  
  /// The instructions for the interaction
  final String instructions;
  
  /// The data for the interaction (varies by type)
  final Map<String, dynamic> interactionData;
  
  /// Whether this is for a younger child (simplified UI)
  final bool isYoungerChild;
  
  /// Callback when the interaction is completed
  final Function(bool success, int score, Duration duration)? onComplete;
  
  const InteractiveContentWidget({
    Key? key,
    required this.interactionType,
    required this.title,
    required this.instructions,
    required this.interactionData,
    this.isYoungerChild = false,
    this.onComplete,
  }) : super(key: key);

  @override
  State<InteractiveContentWidget> createState() => _InteractiveContentWidgetState();
}

class _InteractiveContentWidgetState extends State<InteractiveContentWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isCompleted = false;
  int _score = 0;
  int _maxScore = 0;
  DateTime? _startTime;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..forward();
    
    _startTime = DateTime.now();
    
    // Set max score based on interaction type and data
    _setMaxScore();
  }
  
  void _setMaxScore() {
    switch (widget.interactionType) {
      case InteractionType.dragDrop:
      case InteractionType.matching:
        _maxScore = (widget.interactionData['items'] as List?)?.length ?? 0;
        break;
      case InteractionType.multipleChoice:
        _maxScore = (widget.interactionData['questions'] as List?)?.length ?? 0;
        break;
      case InteractionType.fillBlanks:
        _maxScore = (widget.interactionData['blanks'] as List?)?.length ?? 0;
        break;
      case InteractionType.sorting:
        _maxScore = (widget.interactionData['items'] as List?)?.length ?? 0;
        break;
      case InteractionType.flashcards:
        _maxScore = (widget.interactionData['cards'] as List?)?.length ?? 0;
        break;
      case InteractionType.puzzle:
      case InteractionType.wordSearch:
      case InteractionType.memoryGame:
      case InteractionType.simulation:
        _maxScore = 100; // Default for complex interactions
        break;
    }
  }
  
  void _completeInteraction(bool success, int score) {
    if (_isCompleted) return;
    
    setState(() {
      _isCompleted = true;
      _score = score;
    });
    
    final duration = DateTime.now().difference(_startTime!);
    
    // Call the completion callback
    widget.onComplete?.call(success, score, duration);
    
    // Show completion feedback
    _showCompletionFeedback(success);
  }
  
  void _showCompletionFeedback(bool success) {
    final theme = Theme.of(context);
    
    if (widget.isYoungerChild) {
      // Show fun celebration for younger kids
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 250,
                height: 250,
                child: success
                    ? ConfettiCelebration(
                        onComplete: () {
                          Navigator.of(context).pop();
                        },
                      )
                    : Lottie.asset(
                        'assets/animations/try_again.json',
                        onLoaded: (composition) {
                          Future.delayed(composition.duration, () {
                            Navigator.of(context).pop();
                          });
                        },
                        errorBuilder: (context, error, stackTrace) => 
                          const Icon(Icons.sentiment_dissatisfied, color: Colors.amber, size: 100),
                      ),
              ),
              const SizedBox(height: 20),
              GlassmorphicCard(
                width: 300,
                height: 120,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      success ? 'Great Job! 🎉' : 'Try Again! 🤔',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      success 
                          ? 'You earned $_score points!' 
                          : 'You can do better next time!',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AnimatedGlassmorphicButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        success ? 'Continue' : 'Try Again',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Show more mature feedback for older students
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                success ? Icons.check_circle : Icons.info,
                color: Colors.white,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      success ? 'Activity Completed' : 'Keep Practicing',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      success 
                          ? 'Score: $_score out of $_maxScore' 
                          : 'Try again to improve your score',
                      style: const TextStyle(
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: success ? Colors.green : Colors.amber,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: success ? 'Continue' : 'Retry',
            textColor: Colors.white,
            onPressed: () {
              if (!success) {
                // Reset the interaction
                setState(() {
                  _isCompleted = false;
                  _score = 0;
                  _startTime = DateTime.now();
                });
              }
            },
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and instructions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.instructions,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          
          // Interactive content based on type
          Expanded(
            child: _buildInteractiveContent(theme),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInteractiveContent(ThemeData theme) {
    switch (widget.interactionType) {
      case InteractionType.dragDrop:
        return _buildDragDropInteraction(theme);
      case InteractionType.matching:
        return _buildMatchingInteraction(theme);
      case InteractionType.fillBlanks:
        return _buildFillBlanksInteraction(theme);
      case InteractionType.multipleChoice:
        return _buildMultipleChoiceInteraction(theme);
      case InteractionType.sorting:
        return _buildSortingInteraction(theme);
      case InteractionType.flashcards:
        return _buildFlashcardsInteraction(theme);
      case InteractionType.puzzle:
        return _buildPuzzleInteraction(theme);
      case InteractionType.wordSearch:
        return _buildWordSearchInteraction(theme);
      case InteractionType.memoryGame:
        return _buildMemoryGameInteraction(theme);
      case InteractionType.simulation:
        return _buildSimulationInteraction(theme);
      default:
        return Center(
          child: Text(
            'Interactive content type not supported',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white70,
            ),
          ),
        );
    }
  }
  
  // DRAG & DROP INTERACTION
  Widget _buildDragDropInteraction(ThemeData theme) {
    final items = (widget.interactionData['items'] as List?)?.map((item) {
      return {
        'id': item['id'],
        'text': item['text'],
        'correctTarget': item['correctTarget'],
      };
    }).toList() ?? [];
    
    final targets = (widget.interactionData['targets'] as List?)?.map((target) {
      return {
        'id': target['id'],
        'text': target['text'],
      };
    }).toList() ?? [];
    
    if (items.isEmpty || targets.isEmpty) {
      return Center(
        child: Text(
          'No drag & drop data available',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: Colors.white70,
          ),
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Draggable items
          Expanded(
            flex: 1,
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: widget.isYoungerChild ? 2 : 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 2.5,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Draggable<Map<String, dynamic>>(
                  data: item,
                  feedback: Material(
                    color: Colors.transparent,
                    child: GlassmorphicCard(
                      width: 150,
                      height: 60,
                      color: theme.colorScheme.primary.withOpacity(0.5),
                      child: Center(
                        child: Text(
                          item['text'],
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  childWhenDragging: GlassmorphicCard(
                    color: Colors.grey.withOpacity(0.3),
                    child: Center(
                      child: Text(
                        item['text'],
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.5),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  child: GlassmorphicCard(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    child: Center(
                      child: Text(
                        item['text'],
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Drop targets
          Expanded(
            flex: 2,
            child: ListView.builder(
              itemCount: targets.length,
              itemBuilder: (context, index) {
                final target = targets[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: DragTarget<Map<String, dynamic>>(
                    builder: (context, candidateData, rejectedData) {
                      final isHovering = candidateData.isNotEmpty;
                      return GlassmorphicCard(
                        height: 80,
                        color: isHovering
                            ? theme.colorScheme.secondary.withOpacity(0.3)
                            : Colors.white.withOpacity(0.1),
                        child: Center(
                          child: Text(
                            target['text'],
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                    onWillAccept: (data) => true,
                    onAccept: (data) {
                      // Check if correct match
                      final isCorrect = data['correctTarget'] == target['id'];
                      
                      // Show feedback
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isCorrect 
                                ? 'Correct! ${data['text']} belongs to ${target['text']}' 
                                : 'Try again! ${data['text']} does not belong to ${target['text']}',
                          ),
                          backgroundColor: isCorrect ? Colors.green : Colors.red,
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      
                      // Update score
                      if (isCorrect) {
                        setState(() {
                          _score++;
                        });
                        
                        // Check if all items are correctly placed
                        if (_score >= _maxScore) {
                          _completeInteraction(true, _score);
                        }
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  // MATCHING INTERACTION
  Widget _buildMatchingInteraction(ThemeData theme) {
    final items = (widget.interactionData['items'] as List?)?.map((item) {
      return {
        'id': item['id'],
        'text': item['text'],
        'matchId': item['matchId'],
      };
    }).toList() ?? [];
    
    final matches = (widget.interactionData['matches'] as List?)?.map((match) {
      return {
        'id': match['id'],
        'text': match['text'],
      };
    }).toList() ?? [];
    
    if (items.isEmpty || matches.isEmpty) {
      return Center(
        child: Text(
          'No matching data available',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: Colors.white70,
          ),
        ),
      );
    }
    
    // Shuffle the matches for randomization
    final shuffledMatches = List.from(matches)..shuffle();
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Left column (items)
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: GlassmorphicCard(
                    height: 70,
                    child: Center(
                      child: Text(
                        item['text'],
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Connection lines would go here in a real implementation
          const SizedBox(width: 16),
          
          // Right column (matches)
          Expanded(
            child: ReorderableListView.builder(
              itemCount: shuffledMatches.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (oldIndex < newIndex) {
                    newIndex -= 1;
                  }
                  final item = shuffledMatches.removeAt(oldIndex);
                  shuffledMatches.insert(newIndex, item);
                });
                
                // Check if all matches are correct
                bool allCorrect = true;
                for (int i = 0; i < items.length; i++) {
                  if (i < shuffledMatches.length && 
                      items[i]['matchId'] != shuffledMatches[i]['id']) {
                    allCorrect = false;
                    break;
                  }
                }
                
                if (allCorrect) {
                  _completeInteraction(true, _maxScore);
                }
              },
              itemBuilder: (context, index) {
                final match = shuffledMatches[index];
                return Padding(
                  key: ValueKey(match['id']),
                  padding: const EdgeInsets.only(bottom: 16),
                  child: GlassmorphicCard(
                    height: 70,
                    color: theme.colorScheme.secondary.withOpacity(0.3),
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            match['text'],
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Icon(
                            Icons.drag_handle,
                            color: Colors.white.withOpacity(0.5),
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  // FILL IN THE BLANKS INTERACTION
  Widget _buildFillBlanksInteraction(ThemeData theme) {
    final text = widget.interactionData['text'] as String? ?? '';
    final blanks = (widget.interactionData['blanks'] as List?)?.map((blank) {
      return {
        'id': blank['id'],
        'correctAnswer': blank['correctAnswer'],
        'placeholder': blank['placeholder'] ?? 'Fill in the blank',
      };
    }).toList() ?? [];
    
    if (text.isEmpty || blanks.isEmpty) {
      return Center(
        child: Text(
          'No fill-in-the-blanks data available',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: Colors.white70,
          ),
        ),
      );
    }
    
    // Split text by blanks
    final textParts = text.split('___');
    
    // Controllers for each blank
    final List<TextEditingController> controllers = List.generate(
      blanks.length,
      (index) => TextEditingController(),
    );
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                alignment: WrapAlignment.start,
                runSpacing: 8,
                children: List.generate(
                  textParts.length + blanks.length,
                  (index) {
                    if (index.isEven && index ~/ 2 < textParts.length) {
                      // Text part
                      return Text(
                        textParts[index ~/ 2],
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.white,
                        ),
                      );
                    } else if (index.isOdd && index ~/ 2 < blanks.length) {
                      // Blank input
                      final blankIndex = index ~/ 2;
                      final blank = blanks[blankIndex];
                      
                      return Container(
                        width: 120,
                        height: 40,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: controllers[blankIndex],
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                          ),
                          decoration: InputDecoration(
                            hintText: blank['placeholder'],
                            hintStyle: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            border: InputBorder.none,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Check answers button
          Center(
            child: AnimatedGlassmorphicButton(
              onPressed: () {
                // Check answers
                int correctCount = 0;
                for (int i = 0; i < blanks.length; i++) {
                  if (controllers[i].text.trim().toLowerCase() == 
                      blanks[i]['correctAnswer'].toString().toLowerCase()) {
                    correctCount++;
                  }
                }
                
                // Update score
                setState(() {
                  _score = correctCount;
                });
                
                // Complete interaction
                final success = correctCount == blanks.length;
                _completeInteraction(success, correctCount);
              },
              child: Text(
                'Check Answers',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // MULTIPLE CHOICE INTERACTION
  Widget _buildMultipleChoiceInteraction(ThemeData theme) {
    final questions = (widget.interactionData['questions'] as List?)?.map((question) {
      return {
        'id': question['id'],
        'text': question['text'],
        'options': question['options'],
        'correctAnswer': question['correctAnswer'],
      };
    }).toList() ?? [];
    
    if (questions.isEmpty) {
      return Center(
        child: Text(
          'No multiple choice data available',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: Colors.white70,
          ),
        ),
      );
    }
    
    // Track selected answers
    final selectedAnswers = List<String?>.filled(questions.length, null);
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              itemCount: questions.length,
              itemBuilder: (context, questionIndex) {
                final question = questions[questionIndex];
                final options = question['options'] as List;
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question number
                    Text(
                      'Question ${questionIndex + 1} of ${questions.length}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Question text
                    Text(
                      question['text'],
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Options
                    Expanded(
                      child: ListView.builder(
                        itemCount: options.length,
                        itemBuilder: (context, optionIndex) {
                          final option = options[optionIndex];
                          final isSelected = selectedAnswers[questionIndex] == option['id'];
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedAnswers[questionIndex] = option['id'];
                                });
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
                                        option['text'],
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
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Submit button
          AnimatedGlassmorphicButton(
            onPressed: () {
              // Check answers
              int correctCount = 0;
              for (int i = 0; i < questions.length; i++) {
                if (selectedAnswers[i] == questions[i]['correctAnswer']) {
                  correctCount++;
                }
              }
              
              // Update score
              setState(() {
                _score = correctCount;
              });
              
              // Complete interaction
              final success = correctCount >= questions.length * 0.7; // 70% to pass
              _completeInteraction(success, correctCount);
            },
            child: Text(
              'Submit Answers',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // SORTING INTERACTION
  Widget _buildSortingInteraction(ThemeData theme) {
    final items = (widget.interactionData['items'] as List?)?.map((item) {
      return {
        'id': item['id'],
        'text': item['text'],
        'correctPosition': item['correctPosition'],
      };
    }).toList() ?? [];
    
    if (items.isEmpty) {
      return Center(
        child: Text(
          'No sorting data available',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: Colors.white70,
          ),
        ),
      );
    }
    
    // Shuffle items for initial state
    final shuffledItems = List.from(items)..shuffle();
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: ReorderableListView.builder(
              itemCount: shuffledItems.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (oldIndex < newIndex) {
                    newIndex -= 1;
                  }
                  final item = shuffledItems.removeAt(oldIndex);
                  shuffledItems.insert(newIndex, item);
                });
                
                // Check if all items are in correct order
                bool allCorrect = true;
                for (int i = 0; i < shuffledItems.length; i++) {
                  if (shuffledItems[i]['correctPosition'] != i + 1) {
                    allCorrect = false;
                    break;
                  }
                }
                
                if (allCorrect) {
                  _completeInteraction(true, _maxScore);
                }
              },
              itemBuilder: (context, index) {
                final item = shuffledItems[index];
                return Padding(
                  key: ValueKey(item['id']),
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlassmorphicCard(
                    height: 70,
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            item['text'],
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.drag_handle,
                          color: Colors.white.withOpacity(0.5),
                        ),
                        const SizedBox(width: 16),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Check order button
          AnimatedGlassmorphicButton(
            onPressed: () {
              // Check if all items are in correct order
              int correctCount = 0;
              for (int i = 0; i < shuffledItems.length; i++) {
                if (shuffledItems[i]['correctPosition'] == i + 1) {
                  correctCount++;
                }
              }
              
              // Update score
              setState(() {
                _score = correctCount;
              });
              
              // Complete interaction
              final success = correctCount == shuffledItems.length;
              _completeInteraction(success, correctCount);
            },
            child: Text(
              'Check Order',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // FLASHCARDS INTERACTION
  Widget _buildFlashcardsInteraction(ThemeData theme) {
    final cards = (widget.interactionData['cards'] as List?)?.map((card) {
      return {
        'id': card['id'],
        'front': card['front'],
        'back': card['back'],
      };
    }).toList() ?? [];
    
    if (cards.isEmpty) {
      return Center(
        child: Text(
          'No flashcard data available',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: Colors.white70,
          ),
        ),
      );
    }
    
    // Track current card and flip state
    final currentCardIndex = 0;
    final isFlipped = false;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Card count indicator
          Text(
            'Card ${currentCardIndex + 1} of ${cards.length}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 24),
          
          // Flashcard
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  // Toggle flip state
                });
              },
              child: GlassmorphicCard(
                color: theme.colorScheme.primary.withOpacity(0.2),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      isFlipped
                          ? cards[currentCardIndex]['back']
                          : cards[currentCardIndex]['front'],
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Navigation buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Previous button
              AnimatedGlassmorphicButton(
                width: 120,
                onPressed: currentCardIndex > 0
                    ? () {
                        setState(() {
                          // Go to previous card
                        });
                      }
                    : null,
                color: currentCardIndex > 0
                    ? null
                    : Colors.grey.withOpacity(0.3),
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
                      ),
                    ),
                  ],
                ),
              ),
              
              // Flip button
              AnimatedGlassmorphicButton(
                width: 100,
                color: theme.colorScheme.secondary.withOpacity(0.3),
                onPressed: () {
                  setState(() {
                    // Toggle flip state
                  });
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.flip,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Flip',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Next button
              AnimatedGlassmorphicButton(
                width: 120,
                onPressed: currentCardIndex < cards.length - 1
                    ? () {
                        setState(() {
                          // Go to next card
                        });
                      }
                    : () {
                        // Complete interaction when reached the end
                        _completeInteraction(true, _maxScore);
                      },
                color: currentCardIndex < cards.length - 1
                    ? null
                    : theme.colorScheme.secondary,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      currentCardIndex < cards.length - 1 ? 'Next' : 'Finish',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      currentCardIndex < cards.length - 1
                          ? Icons.arrow_forward_ios
                          : Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // PUZZLE INTERACTION (Placeholder)
  Widget _buildPuzzleInteraction(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.extension,
            color: theme.colorScheme.secondary,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Puzzle Game',
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'This would contain an interactive puzzle game.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  // WORD SEARCH INTERACTION (Placeholder)
  Widget _buildWordSearchInteraction(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            color: theme.colorScheme.secondary,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Word Search',
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'This would contain an interactive word search puzzle.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  // MEMORY GAME INTERACTION (Placeholder)
  Widget _buildMemoryGameInteraction(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.grid_view,
            color: theme.colorScheme.secondary,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Memory Game',
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'This would contain a memory matching game.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  // SIMULATION INTERACTION (Placeholder)
  Widget _buildSimulationInteraction(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.science,
            color: theme.colorScheme.secondary,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Interactive Simulation',
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'This would contain an interactive simulation for experiential learning.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
