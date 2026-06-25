import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sbiv2/core/theme/app_theme.dart';
import 'package:sbiv2/ai/agent/agent_state.dart';
import 'package:sbiv2/ai/voice/voice_state.dart';

enum AIAvatarState {
  idle,
  listening,
  thinking,
  speaking,
}

class AIAvatar extends ConsumerStatefulWidget {
  final double size;
  const AIAvatar({
    super.key,
    this.size = 100.0,
  });

  @override
  ConsumerState<AIAvatar> createState() => _AIAvatarState();
}

class _AIAvatarState extends ConsumerState<AIAvatar> with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _pulseController;
  late AnimationController _spinController;
  late AnimationController _blinkController;
  bool _isBlinking = false;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _startBlinkLoop();
  }

  void _startBlinkLoop() async {
    while (mounted) {
      await Future.delayed(Duration(seconds: 3 + Random().nextInt(4)));
      if (!mounted) return;

      final agentState = ref.read(agentStateProvider);
      final voiceState = ref.read(voiceStateProvider);
      final isIdle = voiceState.status == VoiceStatus.idle && agentState.status == AgentStatus.idle;
      final isSpeaking = voiceState.status == VoiceStatus.speaking;

      if (isIdle || isSpeaking) {
        if (mounted) {
          setState(() {
            _isBlinking = true;
          });
          await _blinkController.forward();
          await _blinkController.reverse();
          if (mounted) {
            setState(() {
              _isBlinking = false;
            });
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _floatController.dispose();
    _pulseController.dispose();
    _spinController.dispose();
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final agentState = ref.watch(agentStateProvider);
    final voiceState = ref.watch(voiceStateProvider);

    AIAvatarState state = AIAvatarState.idle;

    if (agentState.status == AgentStatus.thinking || voiceState.status == VoiceStatus.processing) {
      state = AIAvatarState.thinking;
    } else if (voiceState.status == VoiceStatus.listening || agentState.status == AgentStatus.listening) {
      state = AIAvatarState.listening;
    } else if (voiceState.status == VoiceStatus.speaking || agentState.status == AgentStatus.speaking || agentState.isSpeaking) {
      state = AIAvatarState.speaking;
    }

    return AnimatedBuilder(
      animation: Listenable.merge([_floatController, _pulseController, _spinController, _blinkController]),
      builder: (context, child) {
        final floatOffset = sin(_floatController.value * 2 * pi) * 4.0;

        return Transform.translate(
          offset: Offset(0, floatOffset),
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: AIAvatarPainter(
              state: state,
              pulseValue: _pulseController.value,
              spinValue: _spinController.value,
              blinkValue: _isBlinking ? _blinkController.value : 0.0,
              floatValue: _floatController.value,
            ),
          ),
        );
      },
    );
  }
}

class AIAvatarPainter extends CustomPainter {
  final AIAvatarState state;
  final double pulseValue;
  final double spinValue;
  final double blinkValue;
  final double floatValue;

  AIAvatarPainter({
    required this.state,
    required this.pulseValue,
    required this.spinValue,
    required this.blinkValue,
    required this.floatValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final headSize = size.width * 0.72;
    final headRadius = headSize / 2;

    // 1. Draw outer pulsing waves if speaking
    if (state == AIAvatarState.speaking) {
      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      for (int i = 0; i < 2; i++) {
        final phase = (pulseValue + i / 2.0) % 1.0;
        final radius = headRadius + phase * (size.width / 2 - headRadius);
        final opacity = (1.0 - phase) * 0.4;
        ringPaint.color = AppTheme.accentGreen.withValues(alpha: opacity);
        canvas.drawCircle(Offset(centerX, centerY), radius, ringPaint);
      }
    }

    // 2. Draw ears
    final earPaint = Paint()
      ..color = AppTheme.primary.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    final earWidth = headSize * 0.08;
    final earHeight = headSize * 0.25;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - headRadius - earWidth, centerY - earHeight / 2, earWidth + 2, earHeight),
        Radius.circular(earWidth * 0.5),
      ),
      earPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX + headRadius - 2, centerY - earHeight / 2, earWidth + 2, earHeight),
        Radius.circular(earWidth * 0.5),
      ),
      earPaint,
    );

    // 3. Draw head antenna
    final antennaStemPaint = Paint()
      ..color = AppTheme.primary.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(centerX, centerY - headRadius),
      Offset(centerX, centerY - headRadius - headSize * 0.15),
      antennaStemPaint,
    );

    final antennaLightPaint = Paint()
      ..style = PaintingStyle.fill;

    Color lightColor;
    switch (state) {
      case AIAvatarState.idle:
        lightColor = AppTheme.aiTeal;
        break;
      case AIAvatarState.listening:
        lightColor = Colors.blueAccent;
        break;
      case AIAvatarState.thinking:
        lightColor = Color.lerp(AppTheme.aiTeal, Colors.amber, sin(pulseValue * 2 * pi) * 0.5 + 0.5)!;
        break;
      case AIAvatarState.speaking:
        lightColor = AppTheme.accentGreen;
        break;
    }

    antennaLightPaint.color = lightColor;

    final glowPaint = Paint()
      ..color = lightColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final lightCenter = Offset(centerX, centerY - headRadius - headSize * 0.15);
    final lightRadius = headSize * 0.06;

    canvas.drawCircle(lightCenter, lightRadius * (1.0 + 0.3 * sin(pulseValue * 2 * pi)), glowPaint);
    canvas.drawCircle(lightCenter, lightRadius, antennaLightPaint);

    // 4. Draw head faceplate
    final headRect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: headSize,
      height: headSize,
    );
    final rrect = RRect.fromRectAndRadius(headRect, Radius.circular(headRadius * 0.7));

    final shadowPaint = Paint()
      ..color = lightColor.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 8.0);
    canvas.drawRRect(rrect, shadowPaint);

    final headBgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF1E1E3A),
          Color(0xFF0F0F1E),
        ],
      ).createShader(headRect);
    canvas.drawRRect(rrect, headBgPaint);

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = AppTheme.primary.withValues(alpha: 0.4);
    canvas.drawRRect(rrect, borderPaint);

    final innerFaceRect = headRect.deflate(headSize * 0.08);
    final innerRRect = RRect.fromRectAndRadius(innerFaceRect, Radius.circular(headRadius * 0.5));
    final innerFacePaint = Paint()
      ..color = const Color(0xFF080811)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(innerRRect, innerFacePaint);

    // 5. Draw eyes
    final eyeY = centerY - headSize * 0.08;
    final leftEyeX = centerX - headSize * 0.20;
    final rightEyeX = centerX + headSize * 0.20;

    switch (state) {
      case AIAvatarState.idle:
        final baseRadius = headSize * 0.09;
        final breatheRadius = baseRadius * (1.0 + 0.08 * sin(floatValue * 2 * pi));

        final eyePaint = Paint()
          ..color = AppTheme.aiTeal
          ..style = PaintingStyle.fill;

        final glowPaint = Paint()
          ..color = AppTheme.aiTeal.withValues(alpha: 0.3)
          ..style = PaintingStyle.fill;

        final leftEyeCenter = Offset(leftEyeX, eyeY);
        canvas.drawCircle(leftEyeCenter, breatheRadius * 1.3, glowPaint);
        canvas.drawOval(
          Rect.fromCenter(center: leftEyeCenter, width: breatheRadius * 2, height: breatheRadius * 2 * (1.0 - blinkValue)),
          eyePaint,
        );

        final rightEyeCenter = Offset(rightEyeX, eyeY);
        canvas.drawCircle(rightEyeCenter, breatheRadius * 1.3, glowPaint);
        canvas.drawOval(
          Rect.fromCenter(center: rightEyeCenter, width: breatheRadius * 2, height: breatheRadius * 2 * (1.0 - blinkValue)),
          eyePaint,
        );
        break;

      case AIAvatarState.listening:
        final baseRadius = headSize * 0.13;
        final pulseRadius = baseRadius * (1.0 + 0.1 * sin(pulseValue * 2 * pi));

        final outerPaint = Paint()
          ..color = Colors.blueAccent.withValues(alpha: 0.2)
          ..style = PaintingStyle.fill;

        final borderPaint = Paint()
          ..color = Colors.blueAccent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;

        final micPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;

        final leftEyeCenter = Offset(leftEyeX, eyeY);
        canvas.drawCircle(leftEyeCenter, pulseRadius, outerPaint);
        canvas.drawCircle(leftEyeCenter, pulseRadius, borderPaint);
        _drawMicrophone(canvas, leftEyeCenter, pulseRadius * 1.1, micPaint);

        final rightEyeCenter = Offset(rightEyeX, eyeY);
        canvas.drawCircle(rightEyeCenter, pulseRadius, outerPaint);
        canvas.drawCircle(rightEyeCenter, pulseRadius, borderPaint);
        _drawMicrophone(canvas, rightEyeCenter, pulseRadius * 1.1, micPaint);
        break;

      case AIAvatarState.thinking:
        final loaderRadius = headSize * 0.11;

        final bgRingPaint = Paint()
          ..color = Colors.white10
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

        canvas.drawCircle(Offset(leftEyeX, eyeY), loaderRadius, bgRingPaint);
        canvas.drawCircle(Offset(rightEyeX, eyeY), loaderRadius, bgRingPaint);

        final leftArcPaint = Paint()
          ..color = AppTheme.aiTeal
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0
          ..strokeCap = StrokeCap.round;

        final leftAngle = spinValue * 2 * pi;
        canvas.drawArc(
          Rect.fromCenter(center: Offset(leftEyeX, eyeY), width: loaderRadius * 2, height: loaderRadius * 2),
          leftAngle,
          1.2 * pi,
          false,
          leftArcPaint,
        );

        final rightArcPaint = Paint()
          ..color = Colors.amber
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0
          ..strokeCap = StrokeCap.round;

        final rightAngle = -spinValue * 2 * pi;
        canvas.drawArc(
          Rect.fromCenter(center: Offset(rightEyeX, eyeY), width: loaderRadius * 2, height: loaderRadius * 2),
          rightAngle,
          1.2 * pi,
          false,
          rightArcPaint,
        );
        break;

      case AIAvatarState.speaking:
        final arcWidth = headSize * 0.18;
        final arcHeight = headSize * 0.12 * (1.0 - blinkValue);

        final smilePaint = Paint()
          ..color = AppTheme.accentGreen
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round;

        canvas.drawArc(
          Rect.fromCenter(center: Offset(leftEyeX, eyeY), width: arcWidth, height: arcHeight),
          pi,
          pi,
          false,
          smilePaint,
        );

        canvas.drawArc(
          Rect.fromCenter(center: Offset(rightEyeX, eyeY), width: arcWidth, height: arcHeight),
          pi,
          pi,
          false,
          smilePaint,
        );
        break;
    }

    // 6. Draw mouth/equalizer
    final mouthY = centerY + headSize * 0.18;

    if (state == AIAvatarState.speaking) {
      final barWidth = headSize * 0.035;
      final spacing = headSize * 0.025;
      final heights = [
        4.0 + 10.0 * sin(pulseValue * 2 * pi),
        4.0 + 14.0 * cos(pulseValue * 2 * pi),
        6.0 + 18.0 * sin(pulseValue * 2 * pi + 1.0),
        4.0 + 14.0 * cos(pulseValue * 2 * pi + 2.0),
        4.0 + 10.0 * sin(pulseValue * 2 * pi + 3.0),
      ];

      final eqPaint = Paint()
        ..color = AppTheme.accentGreen
        ..style = PaintingStyle.fill;

      for (int i = 0; i < 5; i++) {
        final barX = centerX + (i - 2) * (barWidth + spacing) - barWidth / 2;
        final barHeight = heights[i];
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(barX, mouthY - barHeight / 2, barWidth, barHeight),
            Radius.circular(barWidth / 2),
          ),
          eqPaint,
        );
      }
    } else if (state == AIAvatarState.listening) {
      final wavePaint = Paint()
        ..color = Colors.blueAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;

      final path = Path();
      final waveWidth = headSize * 0.3;
      final startX = centerX - waveWidth / 2;
      path.moveTo(startX, mouthY);
      for (double dx = 0; dx <= waveWidth; dx += 1.0) {
        final dy = 3.0 * sin((dx / waveWidth) * 4 * pi + pulseValue * 2 * pi);
        path.lineTo(startX + dx, mouthY + dy);
      }
      canvas.drawPath(path, wavePaint);
    } else if (state == AIAvatarState.thinking) {
      final dotPaint = Paint()
        ..color = Colors.amber.withValues(alpha: 0.8)
        ..style = PaintingStyle.fill;

      final spacing = headSize * 0.05;
      const numDots = 3;
      final double dotRadius = 3.0 + 1.0 * sin(pulseValue * 2 * pi);

      for (int i = 0; i < numDots; i++) {
        final dotX = centerX + (i - 1) * spacing;
        canvas.drawCircle(Offset(dotX, mouthY), dotRadius, dotPaint);
      }
    } else {
      final smilePaint = Paint()
        ..color = AppTheme.aiTeal.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;

      final smileWidth = headSize * 0.22;
      canvas.drawArc(
        Rect.fromCenter(center: Offset(centerX, mouthY - 3), width: smileWidth, height: headSize * 0.08),
        0.1 * pi,
        0.8 * pi,
        false,
        smilePaint,
      );
    }
  }

  void _drawMicrophone(Canvas canvas, Offset center, double height, Paint paint) {
    final micWidth = height * 0.35;
    final micHeight = height * 0.6;

    final capsuleRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center.translate(0, -height * 0.06),
        width: micWidth,
        height: micHeight,
      ),
      Radius.circular(micWidth / 2),
    );
    canvas.drawRRect(capsuleRect, paint);

    final standPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final standPath = Path()
      ..addArc(
        Rect.fromCenter(
          center: center.translate(0, -height * 0.04),
          width: micWidth * 1.8,
          height: micHeight * 1.05,
        ),
        0,
        pi,
      );
    canvas.drawPath(standPath, standPaint);

    canvas.drawLine(
      center.translate(0, micHeight * 0.45),
      center.translate(0, micHeight * 0.72),
      standPaint,
    );
    canvas.drawLine(
      center.translate(-micWidth * 0.6, micHeight * 0.72),
      center.translate(micWidth * 0.6, micHeight * 0.72),
      standPaint,
    );
  }

  @override
  bool shouldRepaint(covariant AIAvatarPainter oldDelegate) {
    return oldDelegate.state != state ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.spinValue != spinValue ||
        oldDelegate.blinkValue != blinkValue ||
        oldDelegate.floatValue != floatValue;
  }
}
