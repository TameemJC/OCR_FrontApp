import 'package:flutter/material.dart';
import 'dart:math' as math;

class TraceLine {
  final List<Offset> points;
  final Offset start;
  final Offset end;
  final Offset? control1;
  final Offset? control2;
  final Color color;
  final double width;
  final bool isMultiPoint;

  const TraceLine({
    required this.start,
    required this.end,
    this.control1,
    this.control2,
    this.color = Colors.white,
    this.width = 4.0,
    List<Offset>? points,
  }) : points = points ?? const [],
        isMultiPoint = points != null && points.length > 2;

  factory TraceLine.straight(Offset start, Offset end, {Color color = Colors.white, double width = 4.0}) {
    return TraceLine(start: start, end: end, color: color, width: width);
  }

  factory TraceLine.curve(Offset start, Offset end, Offset control, {Color color = Colors.white, double width = 4.0}) {
    return TraceLine(start: start, end: end, control1: control, color: color, width: width);
  }

  factory TraceLine.sCurve(Offset start, Offset end, Offset control1, Offset control2, {Color color = Colors.white, double width = 4.0}) {
    return TraceLine(start: start, end: end, control1: control1, control2: control2, color: color, width: width);
  }

  factory TraceLine.multiPoint(List<Offset> points, {Color color = Colors.white, double width = 4.0}) {
    if (points.isEmpty) {
      throw ArgumentError('Points list cannot be empty');
    }
    return TraceLine(
      start: points.first,
      end: points.last,
      points: points,
      color: color,
      width: width,
    );
  }

  Offset pointAt(double t) {
    if (isMultiPoint) {
      final segmentCount = points.length - 1;
      final segmentIndex = (t * segmentCount).floor();
      final segmentT = (t * segmentCount) - segmentIndex;

      if (segmentIndex >= points.length - 1) {
        return points.last;
      }

      final p1 = points[segmentIndex];
      final p2 = points[segmentIndex + 1];

      return Offset(
        p1.dx + (p2.dx - p1.dx) * segmentT,
        p1.dy + (p2.dy - p1.dy) * segmentT,
      );
    }

    if (control1 == null) {
      return Offset(
        start.dx + (end.dx - start.dx) * t,
        start.dy + (end.dy - start.dy) * t,
      );
    }

    if (control2 == null) {
      final p0 = start;
      final p1 = control1!;
      final p2 = end;
      final mt = 1 - t;
      return Offset(
        mt * mt * p0.dx + 2 * mt * t * p1.dx + t * t * p2.dx,
        mt * mt * p0.dy + 2 * mt * t * p1.dy + t * t * p2.dy,
      );
    }

    final p0 = start;
    final p1 = control1!;
    final p2 = control2!;
    final p3 = end;
    final mt = 1 - t;
    return Offset(
      mt * mt * mt * p0.dx + 3 * mt * mt * t * p1.dx + 3 * mt * t * t * p2.dx + t * t * t * p3.dx,
      mt * mt * mt * p0.dy + 3 * mt * mt * t * p1.dy + 3 * mt * t * t * p2.dy + t * t * t * p3.dy,
    );
  }

  double distanceTo(Offset point, {int samples = 20}) {
    if (isMultiPoint) {
      double minDistance = double.infinity;
      for (int i = 0; i < points.length - 1; i++) {
        final p1 = points[i];
        final p2 = points[i + 1];

        final segmentDistance = _distanceToSegment(point, p1, p2);
        minDistance = math.min(minDistance, segmentDistance);
      }
      return minDistance;
    }

    double minDistance = double.infinity;
    for (int i = 0; i <= samples; i++) {
      final t = i / samples;
      final linePoint = pointAt(t);
      final distance = (point - linePoint).distance;
      if (distance < minDistance) {
        minDistance = distance;
      }
    }
    return minDistance;
  }

  double _distanceToSegment(Offset point, Offset p1, Offset p2) {
    final lengthSquared = (p2 - p1).distanceSquared;
    if (lengthSquared == 0) return (point - p1).distance;

    final t = ((point.dx - p1.dx) * (p2.dx - p1.dx) +
        (point.dy - p1.dy) * (p2.dy - p1.dy)) / lengthSquared;

    if (t < 0) return (point - p1).distance;
    if (t > 1) return (point - p2).distance;

    final projection = Offset(
      p1.dx + t * (p2.dx - p1.dx),
      p1.dy + t * (p2.dy - p1.dy),
    );
    return (point - projection).distance;
  }

  double closestT(Offset point, {int samples = 20}) {
    if (isMultiPoint) {
      double minDistance = double.infinity;
      int bestSegment = 0;
      double bestSegmentT = 0;

      for (int i = 0; i < points.length - 1; i++) {
        final p1 = points[i];
        final p2 = points[i + 1];

        final segmentLength = (p2 - p1).distance;
        if (segmentLength == 0) continue;

        final t = ((point.dx - p1.dx) * (p2.dx - p1.dx) +
            (point.dy - p1.dy) * (p2.dy - p1.dy)) /
            (segmentLength * segmentLength);

        final clampedT = t.clamp(0.0, 1.0);
        final projection = Offset(
          p1.dx + clampedT * (p2.dx - p1.dx),
          p1.dy + clampedT * (p2.dy - p1.dy),
        );
        final distance = (point - projection).distance;

        if (distance < minDistance) {
          minDistance = distance;
          bestSegment = i;
          bestSegmentT = clampedT;
        }
      }

      return (bestSegment + bestSegmentT) / (points.length - 1);
    }

    double minDistance = double.infinity;
    double closestT = 0;
    for (int i = 0; i <= samples; i++) {
      final t = i / samples;
      final linePoint = pointAt(t);
      final distance = (point - linePoint).distance;
      if (distance < minDistance) {
        minDistance = distance;
        closestT = t;
      }
    }
    return closestT;
  }

  List<Offset> getPointsAtSegments(int segments) {
    if (isMultiPoint) {
      return points;
    }

    final result = <Offset>[];
    for (int i = 0; i <= segments; i++) {
      result.add(pointAt(i / segments));
    }
    return result;
  }
}