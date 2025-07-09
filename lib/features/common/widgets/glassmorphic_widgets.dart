import 'dart:ui';
import 'package:flutter/material.dart';

/// A card with glassmorphism effect that provides a frosted glass appearance
class GlassmorphicCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final double opacity;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final Border? border;

  const GlassmorphicCard({
    Key? key,
    required this.child,
    this.borderRadius = 16,
    this.blur = 10,
    this.opacity = 0.2,
    this.color,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.onTap,
    this.border,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = color ?? theme.colorScheme.surface.withOpacity(opacity);

    return Container(
      width: width,
      height: height,
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(borderRadius),
              border: border ?? Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(borderRadius),
                child: Container(
                  padding: padding ?? const EdgeInsets.all(16),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// An animated button with glassmorphism effect and interactive feedback
class AnimatedGlassmorphicButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double borderRadius;
  final double width;
  final double height;
  final Color? color;
  final bool isLoading;
  final Duration animationDuration;

  const AnimatedGlassmorphicButton({
    Key? key,
    required this.child,
    this.onPressed,
    this.borderRadius = 16,
    this.width = double.infinity,
    this.height = 56,
    this.color,
    this.isLoading = false,
    this.animationDuration = const Duration(milliseconds: 200),
  }) : super(key: key);

  @override
  State<AnimatedGlassmorphicButton> createState() => _AnimatedGlassmorphicButtonState();
}

class _AnimatedGlassmorphicButtonState extends State<AnimatedGlassmorphicButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _opacityAnimation = Tween<double>(
      begin: 0.2,
      end: 0.4,
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

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonColor = widget.color ?? theme.colorScheme.primary;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: widget.onPressed != null ? _handleTapDown : null,
            onTapUp: widget.onPressed != null ? _handleTapUp : null,
            onTapCancel: widget.onPressed != null ? _handleTapCancel : null,
            onTap: widget.onPressed,
            child: Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                gradient: LinearGradient(
                  colors: [
                    buttonColor.withOpacity(_opacityAnimation.value),
                    buttonColor.withOpacity(_opacityAnimation.value * 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: buttonColor.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    alignment: Alignment.center,
                    child: widget.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : widget.child,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A floating action button with glassmorphism effect and spring animation
class FloatingActionGlass extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double size;
  final Color? color;

  const FloatingActionGlass({
    Key? key,
    required this.child,
    this.onPressed,
    this.size = 56,
    this.color,
  }) : super(key: key);

  @override
  State<FloatingActionGlass> createState() => _FloatingActionGlassState();
}

class _FloatingActionGlassState extends State<FloatingActionGlass>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.05,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.reverse().then((_) {
      _controller.forward();
      widget.onPressed?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fabColor = widget.color ?? theme.colorScheme.primary;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: GestureDetector(
              onTap: _handleTap,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      fabColor.withOpacity(0.3),
                      fabColor.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: fabColor.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(widget.size / 2),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      alignment: Alignment.center,
                      child: widget.child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// An app bar with glassmorphism effect that blurs the content behind it
class GlassmorphicAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final double height;
  final bool centerTitle;

  const GlassmorphicAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.leading,
    this.height = 80,
    this.centerTitle = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);

    return Container(
      height: height + mediaQuery.padding.top,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withOpacity(0.2),
                  width: 0.5,
                ),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    if (leading != null) leading!,
                    if (centerTitle) const Spacer(),
                    Text(
                      title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (centerTitle) const Spacer(),
                    if (actions != null) ...actions!,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}

/// A widget that applies a bouncing animation when tapped
class BouncingWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Duration duration;

  const BouncingWidget({
    Key? key,
    required this.child,
    this.onTap,
    this.duration = const Duration(milliseconds: 100),
  }) : super(key: key);

  @override
  State<BouncingWidget> createState() => _BouncingWidgetState();
}

class _BouncingWidgetState extends State<BouncingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 1.0,
      end: 0.9,
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

  void _handleTap() {
    _controller.forward().then((_) {
      _controller.reverse();
      widget.onTap?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.scale(
            scale: _animation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}

/// A widget that applies a pulsating animation, useful for attracting attention
class PulseAnimationWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double minScale;
  final double maxScale;

  const PulseAnimationWidget({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
    this.minScale = 0.97,
    this.maxScale = 1.03,
  }) : super(key: key);

  @override
  State<PulseAnimationWidget> createState() => _PulseAnimationWidgetState();
}

class _PulseAnimationWidgetState extends State<PulseAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat(reverse: true);
    
    _animation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
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
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: widget.child,
        );
      },
    );
  }
}

/// A special glassmorphic container for younger children with more vibrant colors
class KidsGlassmorphicContainer extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final Color? color;
  final double width;
  final double height;

  const KidsGlassmorphicContainer({
    Key? key,
    required this.child,
    this.borderRadius = 24,
    this.color,
    this.width = double.infinity,
    this.height = 200,
  }) : super(key: key);

  @override
  State<KidsGlassmorphicContainer> createState() => _KidsGlassmorphicContainerState();
}

class _KidsGlassmorphicContainerState extends State<KidsGlassmorphicContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _borderAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);
    
    _borderAnimation = Tween<double>(
      begin: 1.0,
      end: 3.0,
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
    final theme = Theme.of(context);
    final containerColor = widget.color ?? theme.colorScheme.primary;
    
    final List<Color> rainbowColors = [
      Colors.red.withOpacity(0.3),
      Colors.orange.withOpacity(0.3),
      Colors.yellow.withOpacity(0.3),
      Colors.green.withOpacity(0.3),
      Colors.blue.withOpacity(0.3),
      Colors.purple.withOpacity(0.3),
    ];

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: Colors.white.withOpacity(0.5),
              width: _borderAnimation.value,
            ),
            gradient: LinearGradient(
              colors: [
                containerColor.withOpacity(0.2),
                containerColor.withOpacity(0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              for (int i = 0; i < rainbowColors.length; i++)
                BoxShadow(
                  color: rainbowColors[i],
                  blurRadius: 15,
                  spreadRadius: -5,
                  offset: Offset(
                    sin((_controller.value * 2 * 3.14) + (i * 0.5)) * 5,
                    cos((_controller.value * 2 * 3.14) + (i * 0.5)) * 5,
                  ),
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                ),
                child: widget.child,
              ),
            ),
          ),
        );
      },
    );
  }
}
