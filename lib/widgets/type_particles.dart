import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class TypeParticles extends StatefulWidget {
  final List<String> types;

  const TypeParticles({super.key, required this.types});

  @override
  State<TypeParticles> createState() => _TypeParticlesState();
}

class _TypeParticlesState extends State<TypeParticles>
    with SingleTickerProviderStateMixin {
  final _particles = <_Particle>[];
  late Ticker _ticker;
  final _notifier = _PaintNotifier();
  Duration _prev = Duration.zero;
  final _rng = Random();
  double _w = 0, _h = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _notifier.dispose();
    super.dispose();
  }

  void _tick(Duration now) {
    final dt = _prev == Duration.zero
        ? 0.016
        : (now - _prev).inMicroseconds / 1e6;
    _prev = now;
    if (_w == 0) return;

    for (final p in _particles) {
      p.update(dt);
    }
    _particles.removeWhere((p) => p.dead);

    final cfgs = widget.types.map(_cfgFor).toList();
    for (final cfg in cfgs) {
      final rate = 12.0 / cfgs.length;
      if (_particles.length < 60 && _rng.nextDouble() < rate * dt) {
        _particles.add(cfg.spawn(_rng, _w, _h));
      }
    }

    _notifier.ping();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, c) {
      _w = c.maxWidth;
      _h = c.maxHeight;
      return CustomPaint(
        painter: _ParticlePainter(_particles, _notifier),
        size: Size(_w, _h),
      );
    });
  }
}

class _PaintNotifier extends ChangeNotifier {
  void ping() => notifyListeners();
}

class _Particle {
  double x, y, vx, vy, size, opacity, age;
  final double gravity, maxAge, phase, wobble, alphaScale;
  final Color color;
  final _PShape shape;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.gravity,
    required this.size,
    required this.maxAge,
    required this.color,
    required this.shape,
    required this.phase,
    required this.wobble,
    required this.alphaScale,
  })  : age = 0,
        opacity = 0;

  void update(double dt) {
    age += dt;
    vy += gravity * dt;
    x += (vx + sin(phase + age * 6) * wobble) * dt;
    y += vy * dt;
    final t = (age / maxAge).clamp(0.0, 1.0);
    opacity = (t < 0.15 ? t / 0.15 : 1.0 - t) * alphaScale;
  }

  bool get dead => age >= maxAge;
}

enum _PShape { circle, bubble, spark, crystal, star }

class _Cfg {
  final List<Color> colors;
  final double vxMin, vxMax, vyMin, vyMax;
  final double gravity;
  final double sizeMin, sizeMax;
  final double lifeMin, lifeMax;
  final double sxMin, sxMax, syMin, syMax;
  final _PShape shape;
  final double wobble;
  final double alphaScale;

  const _Cfg({
    required this.colors,
    required this.vxMin,
    required this.vxMax,
    required this.vyMin,
    required this.vyMax,
    required this.gravity,
    required this.sizeMin,
    required this.sizeMax,
    required this.lifeMin,
    required this.lifeMax,
    required this.sxMin,
    required this.sxMax,
    required this.syMin,
    required this.syMax,
    required this.shape,
    this.wobble = 0,
    this.alphaScale = 0.8,
  });

  _Particle spawn(Random rng, double w, double h) {
    return _Particle(
      x: (sxMin + rng.nextDouble() * (sxMax - sxMin)) * w,
      y: (syMin + rng.nextDouble() * (syMax - syMin)) * h,
      vx: vxMin + rng.nextDouble() * (vxMax - vxMin),
      vy: vyMin + rng.nextDouble() * (vyMax - vyMin),
      gravity: gravity,
      size: sizeMin + rng.nextDouble() * (sizeMax - sizeMin),
      maxAge: lifeMin + rng.nextDouble() * (lifeMax - lifeMin),
      color: colors[rng.nextInt(colors.length)],
      shape: shape,
      phase: rng.nextDouble() * 2 * pi,
      wobble: wobble,
      alphaScale: alphaScale,
    );
  }
}

_Cfg _cfgFor(String type) {
  switch (type) {
    case 'fire':
      return const _Cfg(
        colors: [Color(0xFFFF3300), Color(0xFFFF6600), Color(0xFFFF9900), Color(0xFFFFCC00)],
        vxMin: -20, vxMax: 20, vyMin: -110, vyMax: -35,
        gravity: 20, sizeMin: 4, sizeMax: 11,
        lifeMin: 0.9, lifeMax: 2.0,
        sxMin: 0.2, sxMax: 0.8, syMin: 0.7, syMax: 1.0,
        shape: _PShape.circle, wobble: 40, alphaScale: 0.9,
      );
    case 'water':
      return const _Cfg(
        colors: [Color(0xFF1E90FF), Color(0xFF00BFFF), Color(0xFF87CEEB), Color(0xFFB0E0FF)],
        vxMin: -12, vxMax: 12, vyMin: 25, vyMax: 80,
        gravity: 55, sizeMin: 3, sizeMax: 8,
        lifeMin: 0.7, lifeMax: 1.5,
        sxMin: 0.05, sxMax: 0.95, syMin: 0.0, syMax: 0.15,
        shape: _PShape.circle, wobble: 6, alphaScale: 0.85,
      );
    case 'electric':
      return const _Cfg(
        colors: [Color(0xFFFFE100), Color(0xFFFFCC00), Color(0xFFFFF176), Color(0xFFFFFFFF)],
        vxMin: -130, vxMax: 130, vyMin: -130, vyMax: 130,
        gravity: 0, sizeMin: 2, sizeMax: 5,
        lifeMin: 0.15, lifeMax: 0.45,
        sxMin: 0.3, sxMax: 0.7, syMin: 0.3, syMax: 0.7,
        shape: _PShape.spark, alphaScale: 1.0,
      );
    case 'grass':
      return const _Cfg(
        colors: [Color(0xFF4CAF50), Color(0xFF8BC34A), Color(0xFFCDDC39), Color(0xFF66BB6A)],
        vxMin: -25, vxMax: 25, vyMin: -55, vyMax: -15,
        gravity: 12, sizeMin: 3, sizeMax: 8,
        lifeMin: 1.2, lifeMax: 2.5,
        sxMin: 0.0, sxMax: 1.0, syMin: 0.5, syMax: 1.0,
        shape: _PShape.circle, wobble: 8, alphaScale: 0.75,
      );
    case 'ice':
      return const _Cfg(
        colors: [Color(0xFFE0F7FA), Color(0xFFB2EBF2), Color(0xFF80DEEA), Color(0xFFFFFFFF)],
        vxMin: -18, vxMax: 18, vyMin: 10, vyMax: 45,
        gravity: 8, sizeMin: 5, sizeMax: 13,
        lifeMin: 1.5, lifeMax: 3.2,
        sxMin: 0.0, sxMax: 1.0, syMin: 0.0, syMax: 0.1,
        shape: _PShape.crystal, alphaScale: 0.85,
      );
    case 'poison':
      return const _Cfg(
        colors: [Color(0xFF9C27B0), Color(0xFFBA68C8), Color(0xFF7B1FA2), Color(0xFFCE93D8)],
        vxMin: -12, vxMax: 12, vyMin: -50, vyMax: -12,
        gravity: 0, sizeMin: 5, sizeMax: 14,
        lifeMin: 1.2, lifeMax: 2.5,
        sxMin: 0.05, sxMax: 0.95, syMin: 0.5, syMax: 1.0,
        shape: _PShape.bubble, wobble: 8, alphaScale: 0.75,
      );
    case 'psychic':
      return const _Cfg(
        colors: [Color(0xFFF06292), Color(0xFFE91E63), Color(0xFFFF80AB), Color(0xFFFFCDD2)],
        vxMin: -35, vxMax: 35, vyMin: -35, vyMax: 35,
        gravity: -5, sizeMin: 4, sizeMax: 9,
        lifeMin: 1.0, lifeMax: 2.2,
        sxMin: 0.1, sxMax: 0.9, syMin: 0.1, syMax: 0.9,
        shape: _PShape.star, alphaScale: 0.8,
      );
    case 'ghost':
      return const _Cfg(
        colors: [Color(0xFF7B1FA2), Color(0xFF512DA8), Color(0xFF9C27B0), Color(0xFF4A148C)],
        vxMin: -15, vxMax: 15, vyMin: -25, vyMax: -5,
        gravity: -3, sizeMin: 8, sizeMax: 22,
        lifeMin: 2.0, lifeMax: 4.0,
        sxMin: 0.05, sxMax: 0.95, syMin: 0.1, syMax: 0.95,
        shape: _PShape.bubble, wobble: 18, alphaScale: 0.4,
      );
    case 'dragon':
      return const _Cfg(
        colors: [Color(0xFF1565C0), Color(0xFF1976D2), Color(0xFF42A5F5), Color(0xFF82B1FF)],
        vxMin: -45, vxMax: 45, vyMin: -45, vyMax: 45,
        gravity: 0, sizeMin: 4, sizeMax: 10,
        lifeMin: 1.0, lifeMax: 2.2,
        sxMin: 0.1, sxMax: 0.9, syMin: 0.1, syMax: 0.9,
        shape: _PShape.circle, alphaScale: 0.8,
      );
    case 'dark':
      return const _Cfg(
        colors: [Color(0xFF212121), Color(0xFF424242), Color(0xFF37474F), Color(0xFF263238)],
        vxMin: -25, vxMax: 25, vyMin: -15, vyMax: 30,
        gravity: 8, sizeMin: 4, sizeMax: 9,
        lifeMin: 1.0, lifeMax: 2.0,
        sxMin: 0.05, sxMax: 0.95, syMin: 0.05, syMax: 0.95,
        shape: _PShape.circle, alphaScale: 0.55,
      );
    case 'steel':
      return const _Cfg(
        colors: [Color(0xFFB0BEC5), Color(0xFF90A4AE), Color(0xFFECEFF1), Color(0xFFFFFFFF)],
        vxMin: -90, vxMax: 90, vyMin: -90, vyMax: 90,
        gravity: 30, sizeMin: 1.5, sizeMax: 5,
        lifeMin: 0.25, lifeMax: 0.7,
        sxMin: 0.2, sxMax: 0.8, syMin: 0.2, syMax: 0.8,
        shape: _PShape.spark, alphaScale: 1.0,
      );
    case 'fairy':
      return const _Cfg(
        colors: [Color(0xFFF8BBD9), Color(0xFFF48FB1), Color(0xFFE91E63), Color(0xFFFFFFFF)],
        vxMin: -22, vxMax: 22, vyMin: -38, vyMax: -8,
        gravity: -4, sizeMin: 3, sizeMax: 8,
        lifeMin: 1.2, lifeMax: 2.8,
        sxMin: 0.0, sxMax: 1.0, syMin: 0.3, syMax: 1.0,
        shape: _PShape.star, alphaScale: 0.85,
      );
    case 'rock':
      return const _Cfg(
        colors: [Color(0xFF795548), Color(0xFF8D6E63), Color(0xFFA1887F), Color(0xFF9E9E9E)],
        vxMin: -18, vxMax: 18, vyMin: 15, vyMax: 65,
        gravity: 75, sizeMin: 3, sizeMax: 8,
        lifeMin: 0.5, lifeMax: 1.1,
        sxMin: 0.0, sxMax: 1.0, syMin: 0.0, syMax: 0.15,
        shape: _PShape.circle, alphaScale: 0.8,
      );
    case 'ground':
      return const _Cfg(
        colors: [Color(0xFFD7CCC8), Color(0xFFBCAAA4), Color(0xFFA1887F), Color(0xFF8D6E63)],
        vxMin: -45, vxMax: 45, vyMin: -12, vyMax: 5,
        gravity: 18, sizeMin: 2, sizeMax: 6,
        lifeMin: 0.8, lifeMax: 1.8,
        sxMin: 0.0, sxMax: 1.0, syMin: 0.75, syMax: 1.0,
        shape: _PShape.circle, wobble: 5, alphaScale: 0.7,
      );
    case 'flying':
      return const _Cfg(
        colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB), Color(0xFF90CAF9), Color(0xFFFFFFFF)],
        vxMin: 25, vxMax: 70, vyMin: -18, vyMax: 18,
        gravity: -4, sizeMin: 5, sizeMax: 16,
        lifeMin: 1.0, lifeMax: 2.5,
        sxMin: 0.0, sxMax: 0.25, syMin: 0.2, syMax: 0.8,
        shape: _PShape.bubble, wobble: 25, alphaScale: 0.45,
      );
    case 'bug':
      return const _Cfg(
        colors: [Color(0xFF8BC34A), Color(0xFFCDDC39), Color(0xFFAFB42B), Color(0xFF9CCC65)],
        vxMin: -55, vxMax: 55, vyMin: -55, vyMax: 55,
        gravity: 5, sizeMin: 2, sizeMax: 5,
        lifeMin: 0.4, lifeMax: 1.0,
        sxMin: 0.0, sxMax: 1.0, syMin: 0.0, syMax: 1.0,
        shape: _PShape.circle, alphaScale: 0.75,
      );
    case 'fighting':
      return const _Cfg(
        colors: [Color(0xFFD32F2F), Color(0xFFE53935), Color(0xFFFF5722), Color(0xFFFF9800)],
        vxMin: -110, vxMax: 110, vyMin: -110, vyMax: 110,
        gravity: 25, sizeMin: 3, sizeMax: 8,
        lifeMin: 0.3, lifeMax: 0.8,
        sxMin: 0.3, sxMax: 0.7, syMin: 0.3, syMax: 0.7,
        shape: _PShape.spark, alphaScale: 0.9,
      );
    default:
      return const _Cfg(
        colors: [Color(0xFFFFFFFF), Color(0xFFE0E0E0), Color(0xFFF5F5F5)],
        vxMin: -18, vxMax: 18, vyMin: -35, vyMax: -8,
        gravity: -2, sizeMin: 2, sizeMax: 6,
        lifeMin: 1.0, lifeMax: 2.2,
        sxMin: 0.0, sxMax: 1.0, syMin: 0.0, syMax: 1.0,
        shape: _PShape.star, alphaScale: 0.6,
      );
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;

  _ParticlePainter(this.particles, Listenable repaint) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in List<_Particle>.from(particles)) {
      if (p.opacity <= 0) continue;
      _draw(canvas, p);
    }
  }

  void _draw(Canvas canvas, _Particle p) {
    final paint = Paint()
      ..color = p.color.withValues(alpha: p.opacity.clamp(0.0, 1.0))
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final o = Offset(p.x, p.y);

    switch (p.shape) {
      case _PShape.circle:
        canvas.drawCircle(o, p.size, paint);

      case _PShape.bubble:
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = (p.size * 0.22).clamp(1.0, 3.0);
        canvas.drawCircle(o, p.size, paint);

      case _PShape.spark:
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = (p.size * 0.6).clamp(1.0, 3.0)
          ..strokeCap = StrokeCap.round;
        final len = p.size * 2.5;
        final angle = p.age * 6.0;
        canvas.drawLine(
          Offset(p.x - cos(angle) * len, p.y - sin(angle) * len),
          Offset(p.x + cos(angle) * len, p.y + sin(angle) * len),
          paint,
        );

      case _PShape.crystal:
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = (p.size * 0.15).clamp(1.0, 2.5)
          ..strokeCap = StrokeCap.round;
        final r = p.size;
        for (var i = 0; i < 3; i++) {
          final a = i * pi / 3;
          canvas.drawLine(
            Offset(p.x + cos(a) * r, p.y + sin(a) * r),
            Offset(p.x - cos(a) * r, p.y - sin(a) * r),
            paint,
          );
        }

      case _PShape.star:
        final path = Path();
        final outer = p.size;
        final inner = p.size * 0.4;
        final rot = p.age * 1.5;
        for (var i = 0; i < 5; i++) {
          final oa = rot + i * 2 * pi / 5 - pi / 2;
          final ia = rot + (i + 0.5) * 2 * pi / 5 - pi / 2;
          final ox = p.x + cos(oa) * outer;
          final oy = p.y + sin(oa) * outer;
          final ix = p.x + cos(ia) * inner;
          final iy = p.y + sin(ia) * inner;
          i == 0 ? path.moveTo(ox, oy) : path.lineTo(ox, oy);
          path.lineTo(ix, iy);
        }
        path.close();
        canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => true;
}
