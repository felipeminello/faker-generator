import 'dart:math';
import 'dart:typed_data';

/// The random choices behind one psychedelic picture, all drawn from a seed.
///
/// Each pixel is colored in four steps:
///
/// 1. **Swirl** — its polar angle around a random center turns in
///    proportion to the distance, twisting the whole picture into a spiral.
/// 2. **Kaleidoscope** — half of the recipes fold that angle into 3 to 8
///    mirrored slices, which makes a mandala.
/// 3. **Domain warp** — the point is pushed around twice by sine waves of
///    its own coordinates, which melts straight stripes into liquid shapes.
/// 4. **Plasma + palette** — three plane waves and one circular wave are
///    added up into a single number, which a cosine palette (one cosine per
///    color channel, each with its own frequency and phase) turns into a
///    color. Every rise and fall of the sum runs through the whole rainbow.
///
/// Coordinates are measured against the longer side of the image, so the
/// picture does not depend on the resolution: a small preview and the
/// full-size PNG show the same thing.
class PsychedelicRecipe {
  PsychedelicRecipe._({
    required this.swirlCenterX,
    required this.swirlCenterY,
    required this.swirl,
    required this.slices,
    required this.zoom,
    required this.warp,
    required this.warpFrequencyX,
    required this.warpFrequencyY,
    required this.warpPhases,
    required this.waves,
    required this.ringX,
    required this.ringY,
    required this.ringFrequency,
    required this.ringPhase,
    required this.bands,
    required this.shift,
    required this.colorFrequencies,
    required this.colorPhases,
  });

  /// Draws every choice from `Random(seed)`, so a seed always gives the
  /// same recipe.
  factory PsychedelicRecipe.fromSeed(int seed) {
    final random = Random(seed);
    double between(double low, double high) =>
        low + random.nextDouble() * (high - low);
    double angle() => random.nextDouble() * 2 * pi;
    // The channels' phases are kept about a third of a turn apart, so the
    // palette always runs through every hue instead of two or three colors.
    final hue = random.nextDouble();

    return PsychedelicRecipe._(
      swirlCenterX: between(-0.4, 0.4),
      swirlCenterY: between(-0.4, 0.4),
      swirl: between(0.8, 2.6) * (random.nextBool() ? 1 : -1),
      slices: random.nextBool() ? 0 : 3 + random.nextInt(6),
      zoom: between(1.4, 2.6),
      warp: between(0.3, 0.9),
      warpFrequencyX: between(1.5, 4),
      warpFrequencyY: between(1.5, 4),
      warpPhases: [for (var i = 0; i < 4; i++) angle()],
      waves: [
        for (var i = 0; i < 3; i++)
          (direction: angle(), frequency: between(1.5, 4.5), phase: angle()),
      ],
      ringX: between(-1, 1),
      ringY: between(-1, 1),
      ringFrequency: between(3, 8),
      ringPhase: angle(),
      bands: between(1, 2),
      shift: random.nextDouble(),
      colorFrequencies: [for (var i = 0; i < 3; i++) between(0.8, 1.2)],
      colorPhases: [
        for (var i = 0; i < 3; i++) hue + i / 3 + between(-0.08, 0.08),
      ],
    );
  }

  final double swirlCenterX;
  final double swirlCenterY;

  /// Radians the angle turns per unit of distance from the swirl center.
  final double swirl;

  /// Kaleidoscope slices; 0 is no kaleidoscope.
  final int slices;

  /// How many units of the pattern fit across the image.
  final double zoom;

  /// How far the domain warp pushes a point.
  final double warp;
  final double warpFrequencyX;
  final double warpFrequencyY;
  final List<double> warpPhases;

  final List<({double direction, double frequency, double phase})> waves;

  /// Center, frequency and phase of the circular wave.
  final double ringX;
  final double ringY;
  final double ringFrequency;
  final double ringPhase;

  /// How many times the palette repeats across the range of the plasma.
  final double bands;

  /// Where on the palette the plasma starts.
  final double shift;

  /// Frequency and phase of the cosine of each channel (red, green, blue).
  final List<double> colorFrequencies;
  final List<double> colorPhases;

  /// The picture as RGB bytes, row-major, [width]×[height] pixels.
  Uint8List renderRgb(int width, int height) {
    final pixels = Uint8List(width * height * 3);
    final side = max(width, height).toDouble();
    final slice = slices == 0 ? 0.0 : 2 * pi / slices;
    final waveCos = [for (final wave in waves) cos(wave.direction)];
    final waveSin = [for (final wave in waves) sin(wave.direction)];
    final w0 = waves[0], w1 = waves[1], w2 = waves[2];
    final [p0, p1, p2, p3] = warpPhases;
    final [fr, fg, fb] = colorFrequencies;
    final [dr, dg, db] = colorPhases;
    const tau = 2 * pi;

    var offset = 0;
    for (var y = 0; y < height; y++) {
      // The longer side runs from -1 to 1, the shorter one proportionally.
      final v = ((y + 0.5) * 2 - height) / side - swirlCenterY;
      for (var x = 0; x < width; x++) {
        final u = ((x + 0.5) * 2 - width) / side - swirlCenterX;

        // 1. Swirl, and 2. kaleidoscope, in polar coordinates.
        final radius = sqrt(u * u + v * v);
        var theta = atan2(v, u) + swirl * radius;
        if (slices > 0) {
          theta %= slice;
          if (theta > slice / 2) theta = slice - theta;
        }
        var px = radius * cos(theta) * zoom;
        var py = radius * sin(theta) * zoom;

        // 3. Domain warp, twice.
        px += warp * sin(warpFrequencyY * py + p0);
        py += warp * sin(warpFrequencyX * px + p1);
        px += warp * sin(warpFrequencyY * py + p2);
        py += warp * sin(warpFrequencyX * px + p3);

        // 4. Plasma: three plane waves plus a circular one, in -4..4.
        final rx = px - ringX, ry = py - ringY;
        final plasma =
            sin(w0.frequency * (px * waveCos[0] + py * waveSin[0]) + w0.phase) +
            sin(w1.frequency * (px * waveCos[1] + py * waveSin[1]) + w1.phase) +
            sin(w2.frequency * (px * waveCos[2] + py * waveSin[2]) + w2.phase) +
            sin(ringFrequency * sqrt(rx * rx + ry * ry) + ringPhase);
        final t = plasma * 0.25 * bands + shift;

        pixels[offset++] = _channel(cos(tau * (fr * t + dr)));
        pixels[offset++] = _channel(cos(tau * (fg * t + dg)));
        pixels[offset++] = _channel(cos(tau * (fb * t + db)));
      }
    }
    return pixels;
  }

  /// -1..1 → 0..255.
  static int _channel(double cosine) => (127.5 + 127.5 * cosine).round();
}
