import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// A collection of animation widgets specifically designed for younger children
/// in the ZimLearn app. These animations are colorful, playful, and engaging
/// for children aged 3-8 years.

/// A bouncing character animation that responds to taps
class BouncingCharacter extends StatefulWidget {
  final String? assetPath;
  final IconData? icon;
  final Color color;
  final double size;
  final VoidCallback? onTap;
  final String? name;
  final bool showName;
  final Duration bounceDuration;

  const BouncingCharacter({
    Key? key,
    this.assetPath,
    this.icon,
    this.color = Colors.blue,
    this.size = 80,
    this.onTap,
    this.name,
    this.showName = true,
    this.bounceDuration = const Duration(milliseconds: 500),
  }) : assert(assetPath != null || icon != null, 'Either assetPath or icon must be provided'),
       super(key: key);

  @override
  State<BouncingCharacter> createState() => _BouncingCharacterState();
}

class _BouncingCharacterState extends State<BouncingCharacter> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  bool _isHappy = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.bounceDuration,
      vsync: this,
    );
    
    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: -20.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: -0.05,
      end: 0.05,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    setState(() {
      _isHappy = !_isHappy;
    });
    _controller.forward(from: 0.0);
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _bounceAnimation.value),
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Transform.rotate(
                    angle: _rotationAnimation.value,
                    child: child,
                  ),
                ),
              );
            },
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.2),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Center(
                child: widget.assetPath != null
                    ? Image.asset(
                        widget.assetPath!,
                        width: widget.size * 0.7,
                        height: widget.size * 0.7,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          _isHappy ? Icons.sentiment_very_satisfied : Icons.face,
                          color: widget.color,
                          size: widget.size * 0.5,
                        ),
                      )
                    : Icon(
                        _isHappy ? Icons.sentiment_very_satisfied : widget.icon,
                        color: widget.color,
                        size: widget.size * 0.5,
                      ),
              ),
            ),
          ),
          if (widget.showName && widget.name != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.name!,
              style: TextStyle(
                color: widget.color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A floating bubble animation that moves around randomly
class FloatingBubble extends StatefulWidget {
  final Widget child;
  final Color color;
  final double size;
  final Duration floatDuration;
  final double floatHeight;
  final VoidCallback? onTap;

  const FloatingBubble({
    Key? key,
    required this.child,
    this.color = Colors.blue,
    this.size = 60,
    this.floatDuration = const Duration(seconds: 3),
    this.floatHeight = 15.0,
    this.onTap,
  }) : super(key: key);

  @override
  State<FloatingBubble> createState() => _FloatingBubbleState();
}

class _FloatingBubbleState extends State<FloatingBubble> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _floatAnimation;
  late Animation<double> _horizontalAnimation;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.floatDuration,
      vsync: this,
    )..repeat(reverse: true);
    
    _floatAnimation = Tween<double>(
      begin: 0.0,
      end: widget.floatHeight,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    _horizontalAnimation = Tween<double>(
      begin: -5.0,
      end: 5.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(
              _horizontalAnimation.value,
              -_floatAnimation.value,
            ),
            child: child,
          );
        },
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.2),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
            gradient: RadialGradient(
              colors: [
                widget.color.withOpacity(0.7),
                widget.color.withOpacity(0.3),
              ],
              center: Alignment.topLeft,
              radius: 1.0,
            ),
          ),
          child: Center(
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// A star burst animation for achievements and rewards
class StarBurst extends StatefulWidget {
  final int numberOfStars;
  final double size;
  final List<Color> colors;
  final Duration duration;
  final Widget? child;
  final VoidCallback? onComplete;

  const StarBurst({
    Key? key,
    this.numberOfStars = 12,
    this.size = 200,
    this.colors = const [
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.red,
      Colors.pink,
    ],
    this.duration = const Duration(seconds: 2),
    this.child,
    this.onComplete,
  }) : super(key: key);

  @override
  State<StarBurst> createState() => _StarBurstState();
}

class _StarBurstState extends State<StarBurst> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  final math.Random _random = math.Random();
  late List<Star> _stars;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    
    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.7, 1.0, curve: Curves.easeInOut),
    ));
    
    _generateStars();
    
    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  void _generateStars() {
    _stars = List.generate(widget.numberOfStars, (index) {
      final angle = (index / widget.numberOfStars) * 2 * math.pi;
      final distance = widget.size / 2 * (0.5 + _random.nextDouble() * 0.5);
      final delay = _random.nextDouble() * 0.5;
      final duration = 0.5 + _random.nextDouble() * 0.5;
      final size = 10.0 + _random.nextDouble() * 15.0;
      final color = widget.colors[_random.nextInt(widget.colors.length)];
      
      return Star(
        angle: angle,
        distance: distance,
        delay: delay,
        duration: duration,
        size: size,
        color: color,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Stars
              ...List.generate(_stars.length, (index) {
                final star = _stars[index];
                final starProgress = _calculateStarProgress(star);
                
                if (starProgress <= 0) return const SizedBox.shrink();
                
                final dx = math.cos(star.angle) * star.distance * starProgress;
                final dy = math.sin(star.angle) * star.distance * starProgress;
                
                return Positioned(
                  left: widget.size / 2 + dx - star.size / 2,
                  top: widget.size / 2 + dy - star.size / 2,
                  child: Opacity(
                    opacity: _controller.value > star.delay + star.duration
                        ? 1.0 - ((_controller.value - star.delay - star.duration) / 0.3).clamp(0.0, 1.0)
                        : 1.0,
                    child: Transform.rotate(
                      angle: star.angle + math.pi / 4,
                      child: Icon(
                        Icons.star,
                        color: star.color,
                        size: star.size,
                      ),
                    ),
                  ),
                );
              }),
              
              // Center child with scale animation
              if (widget.child != null)
                Opacity(
                  opacity: 1.0 - _opacityAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: widget.child,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  double _calculateStarProgress(Star star) {
    if (_controller.value < star.delay) return 0.0;
    if (_controller.value > star.delay + star.duration) return 1.0;
    
    return ((_controller.value - star.delay) / star.duration).clamp(0.0, 1.0);
  }
}

class Star {
  final double angle;
  final double distance;
  final double delay;
  final double duration;
  final double size;
  final Color color;

  Star({
    required this.angle,
    required this.distance,
    required this.delay,
    required this.duration,
    required this.size,
    required this.color,
  });
}

/// A rainbow progress indicator for children
class RainbowProgressIndicator extends StatefulWidget {
  final double progress;
  final double height;
  final double width;
  final bool animate;
  final Duration animationDuration;
  final List<Color> colors;
  final Widget? child;
  final BorderRadius? borderRadius;

  const RainbowProgressIndicator({
    Key? key,
    required this.progress,
    this.height = 20,
    this.width = double.infinity,
    this.animate = true,
    this.animationDuration = const Duration(milliseconds: 500),
    this.colors = const [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.blue,
      Colors.indigo,
      Colors.purple,
    ],
    this.child,
    this.borderRadius,
  }) : assert(progress >= 0.0 && progress <= 1.0, 'Progress must be between 0.0 and 1.0'),
       super(key: key);

  @override
  State<RainbowProgressIndicator> createState() => _RainbowProgressIndicatorState();
}

class _RainbowProgressIndicatorState extends State<RainbowProgressIndicator> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.progress,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
    ));
    
    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(RainbowProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _progressAnimation = Tween<double>(
        begin: oldWidget.progress,
        end: widget.progress,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ));
      
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaultBorderRadius = BorderRadius.circular(widget.height / 2);
    final borderRadius = widget.borderRadius ?? defaultBorderRadius;
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.2),
            borderRadius: borderRadius,
          ),
          child: Stack(
            children: [
              // Progress bar
              ClipRRect(
                borderRadius: borderRadius,
                child: Container(
                  width: widget.width * _progressAnimation.value,
                  height: widget.height,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: widget.colors,
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              ),
              
              // Shimmer effect
              ClipRRect(
                borderRadius: borderRadius,
                child: Container(
                  width: widget.width * _progressAnimation.value,
                  height: widget.height,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.0),
                        Colors.white.withOpacity(0.4),
                        Colors.white.withOpacity(0.0),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      transform: GradientRotation(_shimmerAnimation.value * math.pi),
                    ),
                  ),
                ),
              ),
              
              // Child (like text)
              if (widget.child != null)
                SizedBox(
                  width: widget.width,
                  height: widget.height,
                  child: Center(child: widget.child),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// A confetti animation for celebrations
class ConfettiCelebration extends StatefulWidget {
  final bool play;
  final Duration duration;
  final int numberOfParticles;
  final List<Color> colors;
  final double blastRadius;
  final Widget? child;

  const ConfettiCelebration({
    Key? key,
    this.play = true,
    this.duration = const Duration(seconds: 3),
    this.numberOfParticles = 50,
    this.colors = const [
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
    ],
    this.blastRadius = 100,
    this.child,
  }) : super(key: key);

  @override
  State<ConfettiCelebration> createState() => _ConfettiCelebrationState();
}

class _ConfettiCelebrationState extends State<ConfettiCelebration> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<ConfettiParticle> _particles;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _generateParticles();
    
    if (widget.play) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(ConfettiCelebration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.play != oldWidget.play) {
      if (widget.play) {
        _generateParticles();
        _controller.forward(from: 0.0);
      } else {
        _controller.stop();
      }
    }
  }

  void _generateParticles() {
    _particles = List.generate(widget.numberOfParticles, (index) {
      final angle = _random.nextDouble() * 2 * math.pi;
      final velocity = 0.5 + _random.nextDouble() * 0.5;
      final distance = widget.blastRadius * velocity;
      final delay = _random.nextDouble() * 0.5;
      final duration = 0.5 + _random.nextDouble() * 0.5;
      final rotationSpeed = _random.nextDouble() * 10 - 5;
      final size = 5.0 + _random.nextDouble() * 10.0;
      final color = widget.colors[_random.nextInt(widget.colors.length)];
      final shape = _random.nextInt(3); // 0: circle, 1: square, 2: triangle
      
      return ConfettiParticle(
        angle: angle,
        distance: distance,
        delay: delay,
        duration: duration,
        rotationSpeed: rotationSpeed,
        size: size,
        color: color,
        shape: shape,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            if (widget.child != null) widget.child!,
            ...List.generate(_particles.length, (index) {
              final particle = _particles[index];
              final particleProgress = _calculateParticleProgress(particle);
              
              if (particleProgress <= 0) return const SizedBox.shrink();
              
              // Apply gravity effect
              final gravityEffect = math.pow(particleProgress, 2) * 100;
              
              final dx = math.cos(particle.angle) * particle.distance * particleProgress;
              final dy = math.sin(particle.angle) * particle.distance * particleProgress + gravityEffect;
              
              return Positioned(
                left: MediaQuery.of(context).size.width / 2 + dx - particle.size / 2,
                top: MediaQuery.of(context).size.height / 2 + dy - particle.size / 2,
                child: Opacity(
                  opacity: 1.0 - particleProgress,
                  child: Transform.rotate(
                    angle: particle.rotationSpeed * _controller.value * 2 * math.pi,
                    child: SizedBox(
                      width: particle.size,
                      height: particle.size,
                      child: _buildParticleShape(particle),
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildParticleShape(ConfettiParticle particle) {
    switch (particle.shape) {
      case 0: // Circle
        return Container(
          decoration: BoxDecoration(
            color: particle.color,
            shape: BoxShape.circle,
          ),
        );
      case 1: // Square
        return Container(
          decoration: BoxDecoration(
            color: particle.color,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      case 2: // Triangle
        return CustomPaint(
          painter: TrianglePainter(color: particle.color),
          size: Size(particle.size, particle.size),
        );
      default:
        return Container(
          decoration: BoxDecoration(
            color: particle.color,
            shape: BoxShape.circle,
          ),
        );
    }
  }

  double _calculateParticleProgress(ConfettiParticle particle) {
    if (_controller.value < particle.delay) return 0.0;
    if (_controller.value > particle.delay + particle.duration) return 1.0;
    
    return ((_controller.value - particle.delay) / particle.duration).clamp(0.0, 1.0);
  }
}

class ConfettiParticle {
  final double angle;
  final double distance;
  final double delay;
  final double duration;
  final double rotationSpeed;
  final double size;
  final Color color;
  final int shape;

  ConfettiParticle({
    required this.angle,
    required this.distance,
    required this.delay,
    required this.duration,
    required this.rotationSpeed,
    required this.size,
    required this.color,
    required this.shape,
  });
}

class TrianglePainter extends CustomPainter {
  final Color color;

  TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(TrianglePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

/// An educational feedback animation that shows success or failure
class FeedbackAnimation extends StatefulWidget {
  final bool isSuccess;
  final String? message;
  final VoidCallback? onComplete;
  final Duration duration;
  final Widget? successWidget;
  final Widget? failureWidget;

  const FeedbackAnimation({
    Key? key,
    required this.isSuccess,
    this.message,
    this.onComplete,
    this.duration = const Duration(seconds: 2),
    this.successWidget,
    this.failureWidget,
  }) : super(key: key);

  @override
  State<FeedbackAnimation> createState() => _FeedbackAnimationState();
}

class _FeedbackAnimationState extends State<FeedbackAnimation> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));
    
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
    ));
    
    _controller.forward().then((_) {
      if (widget.onComplete != null) {
        Future.delayed(const Duration(milliseconds: 500), widget.onComplete);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.isSuccess)
                  widget.successWidget ?? Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 60,
                    ),
                  )
                else
                  widget.failureWidget ?? Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.sentiment_dissatisfied,
                      color: Colors.red,
                      size: 60,
                    ),
                  ),
                
                if (widget.message != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    widget.message!,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: widget.isSuccess ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A playful animal character widget for younger children
class AnimalCharacter extends StatefulWidget {
  final String animalType;
  final String? name;
  final double size;
  final VoidCallback? onTap;
  final bool animate;
  final Map<String, IconData> animalIcons;

  const AnimalCharacter({
    Key? key,
    required this.animalType,
    this.name,
    this.size = 100,
    this.onTap,
    this.animate = true,
    this.animalIcons = const {
      'lion': Icons.pets,
      'elephant': Icons.pets,
      'giraffe': Icons.pets,
      'monkey': Icons.pets,
      'zebra': Icons.pets,
      'hippo': Icons.pets,
      'crocodile': Icons.pets,
      'bird': Icons.flutter_dash,
    },
  }) : super(key: key);

  @override
  State<AnimalCharacter> createState() => _AnimalCharacterState();
}

class _AnimalCharacterState extends State<AnimalCharacter> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;
  late Animation<double> _rotationAnimation;
  bool _isHappy = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 10.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: -0.05,
      end: 0.05,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    if (widget.animate) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getAnimalColor() {
    switch (widget.animalType.toLowerCase()) {
      case 'lion':
        return Colors.amber;
      case 'elephant':
        return Colors.grey;
      case 'giraffe':
        return Colors.orange;
      case 'monkey':
        return Colors.brown;
      case 'zebra':
        return Colors.black;
      case 'hippo':
        return Colors.purple;
      case 'crocodile':
        return Colors.green;
      case 'bird':
        return Colors.blue;
      default:
        return Colors.teal;
    }
  }

  IconData _getAnimalIcon() {
    return widget.animalIcons[widget.animalType.toLowerCase()] ?? Icons.pets;
  }

  void _handleTap() {
    setState(() {
      _isHappy = !_isHappy;
    });
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final animalColor = _getAnimalColor();
    final animalIcon = _getAnimalIcon();
    
    return GestureDetector(
      onTap: _handleTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _bounceAnimation.value),
                child: Transform.rotate(
                  angle: _rotationAnimation.value,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      color: animalColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: animalColor.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                      border: Border.all(
                        color: animalColor.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          animalIcon,
                          color: animalColor,
                          size: widget.size * 0.6,
                        ),
                        if (_isHappy)
                          Positioned(
                            top: widget.size * 0.2,
                            child: Icon(
                              Icons.sentiment_very_satisfied,
                              color: animalColor,
                              size: widget.size * 0.3,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          if (widget.name != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.name!,
              style: TextStyle(
                color: animalColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A dancing letters animation for spelling and word learning
class DancingLetters extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration letterDuration;
  final double bounceHeight;
  final bool repeat;
  final List<Color>? letterColors;

  const DancingLetters({
    Key? key,
    required this.text,
    this.style,
    this.letterDuration = const Duration(milliseconds: 300),
    this.bounceHeight = 10.0,
    this.repeat = true,
    this.letterColors,
  }) : super(key: key);

  @override
  State<DancingLetters> createState() => _DancingLettersState();
}

class _DancingLettersState extends State<DancingLetters> 
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  final List<Color> _defaultColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _controllers = List.generate(
      widget.text.length,
      (index) => AnimationController(
        duration: widget.letterDuration,
        vsync: this,
      ),
    );
    
    _animations = List.generate(
      widget.text.length,
      (index) => Tween<double>(
        begin: 0.0,
        end: widget.bounceHeight,
      ).animate(
        CurvedAnimation(
          parent: _controllers[index],
          curve: Curves.easeInOut,
        ),
      ),
    );
    
    // Start animations with staggered delay
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 100), () {
        if (mounted) {
          if (widget.repeat) {
            _controllers[i].repeat(reverse: true);
          } else {
            _controllers[i].forward().then((_) {
              _controllers[i].reverse();
            });
          }
        }
      });
    }
  }

  @override
  void didUpdateWidget(DancingLetters oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text) {
      // Dispose old controllers
      for (var controller in _controllers) {
        controller.dispose();
      }
      
      // Initialize new animations
      _initializeAnimations();
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultStyle = theme.textTheme.headlineMedium?.copyWith(
      fontWeight: FontWeight.bold,
    );
    final textStyle = widget.style ?? defaultStyle;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        widget.text.length,
        (index) {
          final colors = widget.letterColors ?? _defaultColors;
          final color = colors[index % colors.length];
          
          return AnimatedBuilder(
            animation: _controllers[index],
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -_animations[index].value),
                child: Text(
                  widget.text[index],
                  style: textStyle?.copyWith(
                    color: color,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
