import 'dart:math';
import 'package:flutter/material.dart';

class CelebrationOverlay extends StatefulWidget {
  final Widget child;
  final bool isPlaying;
  final VoidCallback? onFinished;

  const CelebrationOverlay({
    super.key,
    required this.child,
    required this.isPlaying,
    this.onFinished,
  });

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_ConfettiParticle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _controller.addListener(() {
      setState(() {
        for (var particle in _particles) {
          particle.update();
        }
      });
    });
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onFinished?.call();
        _particles.clear();
      }
    });
  }

  @override
  void didUpdateWidget(CelebrationOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !oldWidget.isPlaying) {
      _startCelebration();
    }
  }

  void _startCelebration() {
    _particles.clear();
    for (int i = 0; i < 50; i++) {
      _particles.add(_ConfettiParticle(_random));
    }
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.isPlaying || _controller.isAnimating)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _ConfettiPainter(_particles)),
            ),
          ),
      ],
    );
  }
}

class _ConfettiParticle {
  late double x;
  late double y;
  late double size;
  late Color color;
  late double speedX;
  late double speedY;
  late double rotation;
  late double rotationSpeed;

  _ConfettiParticle(Random random) {
    x = random.nextDouble(); // 0 to 1
    y = -0.1 - random.nextDouble() * 0.5; // Start above screen
    size = 5 + random.nextDouble() * 10;
    color = Colors.primaries[random.nextInt(Colors.primaries.length)];
    speedX = (random.nextDouble() - 0.5) * 0.01;
    speedY = 0.01 + random.nextDouble() * 0.02;
    rotation = random.nextDouble() * 2 * pi;
    rotationSpeed = (random.nextDouble() - 0.5) * 0.1;
  }

  void update() {
    x += speedX;
    y += speedY;
    rotation += rotationSpeed;
    speedY += 0.0005; // Gravity
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;

  _ConfettiPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint = Paint()..color = particle.color;
      final dx = particle.x * size.width;
      final dy = particle.y * size.height;

      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(particle.rotation);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: particle.size,
          height: particle.size * 0.6,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
