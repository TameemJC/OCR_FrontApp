import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tammemp/trace_line.dart';
import 'dart:math' as math;



class PathSegment {
  final List<Offset> points;
  final bool isClosed;
  final Color color;
  final double strokeWidth;

  const PathSegment({
    required this.points,
    required this.isClosed,
    required this.color,
    required this.strokeWidth,
  });

  List<TraceLine> toTraceLines() {
    final List<TraceLine> lines = [];

    for (int i = 0; i < points.length - 1; i++) {
      lines.add(TraceLine.straight(
        points[i],
        points[i + 1],
        color: color,
        width: strokeWidth,
      ));
    }

    if (isClosed && points.length > 2) {
      lines.add(TraceLine.straight(
        points.last,
        points.first,
        color: color,
        width: strokeWidth,
      ));
    }

    return lines;
  }
}

class SVGPathParser {
  static List<TraceLine> parseSVG(String svgContent, {Color defaultColor = Colors.white, double defaultWidth = 4.0}) {
    final List<TraceLine> allLines = [];

    final pathRegex = RegExp(r'<path\s+([^>]*)>', dotAll: true);
    final matches = pathRegex.allMatches(svgContent);

    for (final match in matches) {
      final fullTag = match.group(1) ?? '';

      final dRegex = RegExp(r'd="([^"]*)"');
      final dMatch = dRegex.firstMatch(fullTag);
      if (dMatch == null) continue;

      final pathData = dMatch.group(1) ?? '';
      if (pathData.isEmpty) continue;

      final color = _extractColor(fullTag, defaultColor);
      final strokeWidth = _extractStrokeWidth(fullTag, defaultWidth);
      final fillColor = _extractFillColor(fullTag);
      final hasStroke = _hasStroke(fullTag);

      if (hasStroke || fillColor != null) {
        final lines = _parsePathData(pathData, color, strokeWidth);
        allLines.addAll(lines);
      }
    }

    allLines.addAll(_parseOtherElements(svgContent, defaultColor, defaultWidth));

    return allLines;
  }

  static Color _extractColor(String tag, Color defaultColor) {
    final styleRegex = RegExp(r'style="[^"]*stroke:([^;"]+)"');
    final styleMatch = styleRegex.firstMatch(tag);
    if (styleMatch != null) {
      return _parseColorString(styleMatch.group(1)!, defaultColor);
    }

    final strokeRegex = RegExp(r'stroke="([^"]+)"');
    final strokeMatch = strokeRegex.firstMatch(tag);
    if (strokeMatch != null) {
      return _parseColorString(strokeMatch.group(1)!, defaultColor);
    }

    return defaultColor;
  }

  static double _extractStrokeWidth(String tag, double defaultWidth) {
    final styleRegex = RegExp(r'style="[^"]*stroke-width:([^;"]+)"');
    final styleMatch = styleRegex.firstMatch(tag);
    if (styleMatch != null) {
      return double.tryParse(styleMatch.group(1)!) ?? defaultWidth;
    }

    final widthRegex = RegExp(r'stroke-width="([^"]+)"');
    final widthMatch = widthRegex.firstMatch(tag);
    if (widthMatch != null) {
      return double.tryParse(widthMatch.group(1)!) ?? defaultWidth;
    }

    return defaultWidth;
  }

  static Color? _extractFillColor(String tag) {
    final styleRegex = RegExp(r'style="[^"]*fill:([^;"]+)"');
    final styleMatch = styleRegex.firstMatch(tag);
    if (styleMatch != null) {
      final fillValue = styleMatch.group(1)!;
      if (fillValue != 'none') {
        return _parseColorString(fillValue, Colors.transparent);
      }
    }

    final fillRegex = RegExp(r'fill="([^"]+)"');
    final fillMatch = fillRegex.firstMatch(tag);
    if (fillMatch != null) {
      final fillValue = fillMatch.group(1)!;
      if (fillValue != 'none') {
        return _parseColorString(fillValue, Colors.transparent);
      }
    }

    return null;
  }

  static bool _hasStroke(String tag) {
    if (tag.contains('stroke:none') || tag.contains('stroke="none"')) {
      return false;
    }

    return tag.contains('stroke:') || tag.contains('stroke="');
  }

  static Color _parseColorString(String colorStr, Color defaultColor) {
    colorStr = colorStr.trim().toLowerCase();

    if (colorStr.startsWith('#')) {
      try {
        final hex = colorStr.substring(1);
        if (hex.length == 3) {
          final r = int.parse(hex[0] + hex[0], radix: 16);
          final g = int.parse(hex[1] + hex[1], radix: 16);
          final b = int.parse(hex[2] + hex[2], radix: 16);
          return Color.fromRGBO(r, g, b, 1.0);
        } else if (hex.length == 6) {
          return Color(int.parse('FF$hex', radix: 16));
        } else if (hex.length == 8) {
          return Color(int.parse(hex, radix: 16));
        }
      } catch (_) {}
    }

    if (colorStr.startsWith('rgb')) {
      final regex = RegExp(r'(\d+),\s*(\d+),\s*(\d+)');
      final match = regex.firstMatch(colorStr);
      if (match != null) {
        return Color.fromRGBO(
          int.parse(match.group(1)!),
          int.parse(match.group(2)!),
          int.parse(match.group(3)!),
          1.0,
        );
      }
    }

    switch (colorStr) {
      case 'black': return Colors.black;
      case 'white': return Colors.white;
      case 'red': return Colors.red;
      case 'green': return Colors.green;
      case 'blue': return Colors.blue;
      case 'yellow': return Colors.yellow;
      case 'cyan': return Colors.cyan;
      case 'magenta': return Colors.pink;
      case 'gray': return Colors.grey;
      case 'grey': return Colors.grey;
      case 'transparent': return Colors.transparent;
    }

    return defaultColor;
  }

  static List<TraceLine> _parseOtherElements(String svgContent, Color defaultColor, double defaultWidth) {
    final List<TraceLine> lines = [];

    final circleRegex = RegExp(r'<circle\s+([^>]*)>', dotAll: true);
    final circleMatches = circleRegex.allMatches(svgContent);
    for (final match in circleMatches) {
      final tag = match.group(1) ?? '';
      lines.addAll(_parseCircle(tag, defaultColor, defaultWidth));
    }

    final ellipseRegex = RegExp(r'<ellipse\s+([^>]*)>', dotAll: true);
    final ellipseMatches = ellipseRegex.allMatches(svgContent);
    for (final match in ellipseMatches) {
      final tag = match.group(1) ?? '';
      lines.addAll(_parseEllipse(tag, defaultColor, defaultWidth));
    }

    final rectRegex = RegExp(r'<rect\s+([^>]*)>', dotAll: true);
    final rectMatches = rectRegex.allMatches(svgContent);
    for (final match in rectMatches) {
      final tag = match.group(1) ?? '';
      lines.addAll(_parseRect(tag, defaultColor, defaultWidth));
    }

    final lineRegex = RegExp(r'<line\s+([^>]*)>', dotAll: true);
    final lineMatches = lineRegex.allMatches(svgContent);
    for (final match in lineMatches) {
      final tag = match.group(1) ?? '';
      lines.addAll(_parseLine(tag, defaultColor, defaultWidth));
    }

    final polylineRegex = RegExp(r'<polyline\s+([^>]*)>', dotAll: true);
    final polylineMatches = polylineRegex.allMatches(svgContent);
    for (final match in polylineMatches) {
      final tag = match.group(1) ?? '';
      lines.addAll(_parsePolyline(tag, defaultColor, defaultWidth));
    }

    final polygonRegex = RegExp(r'<polygon\s+([^>]*)>', dotAll: true);
    final polygonMatches = polygonRegex.allMatches(svgContent);
    for (final match in polygonMatches) {
      final tag = match.group(1) ?? '';
      lines.addAll(_parsePolygon(tag, defaultColor, defaultWidth));
    }

    return lines;
  }

  static List<TraceLine> _parseCircle(String tag, Color defaultColor, double defaultWidth) {
    final List<TraceLine> lines = [];

    final cx = _extractDouble(tag, 'cx');
    final cy = _extractDouble(tag, 'cy');
    final r = _extractDouble(tag, 'r');
    final color = _extractColor(tag, defaultColor);
    final width = _extractStrokeWidth(tag, defaultWidth);

    if (cx != null && cy != null && r != null && r > 0) {

      final k = 0.5522847498;

      lines.add(TraceLine.sCurve(
        Offset(cx + r, cy),
        Offset(cx, cy + r),
        Offset(cx + r, cy + r * k),
        Offset(cx + r * k, cy + r),
        color: color,
        width: width,
      ));

      lines.add(TraceLine.sCurve(
        Offset(cx, cy + r),
        Offset(cx - r, cy),
        Offset(cx - r * k, cy + r),
        Offset(cx - r, cy + r * k),
        color: color,
        width: width,
      ));

      lines.add(TraceLine.sCurve(
        Offset(cx - r, cy),
        Offset(cx, cy - r),
        Offset(cx - r, cy - r * k),
        Offset(cx - r * k, cy - r),
        color: color,
        width: width,
      ));

      lines.add(TraceLine.sCurve(
        Offset(cx, cy - r),
        Offset(cx + r, cy),
        Offset(cx + r * k, cy - r),
        Offset(cx + r, cy - r * k),
        color: color,
        width: width,
      ));
    }

    return lines;
  }

  static List<TraceLine> _parseEllipse(String tag, Color defaultColor, double defaultWidth) {
    final List<TraceLine> lines = [];

    final cx = _extractDouble(tag, 'cx');
    final cy = _extractDouble(tag, 'cy');
    final rx = _extractDouble(tag, 'rx');
    final ry = _extractDouble(tag, 'ry');
    final color = _extractColor(tag, defaultColor);
    final width = _extractStrokeWidth(tag, defaultWidth);

    if (cx != null && cy != null && rx != null && ry != null && rx > 0 && ry > 0) {
      final kx = 0.5522847498 * rx;
      final ky = 0.5522847498 * ry;

      lines.add(TraceLine.sCurve(
        Offset(cx + rx, cy),
        Offset(cx, cy + ry),
        Offset(cx + rx, cy + ky),
        Offset(cx + kx, cy + ry),
        color: color,
        width: width,
      ));

      lines.add(TraceLine.sCurve(
        Offset(cx, cy + ry),
        Offset(cx - rx, cy),
        Offset(cx - kx, cy + ry),
        Offset(cx - rx, cy + ky),
        color: color,
        width: width,
      ));

      lines.add(TraceLine.sCurve(
        Offset(cx - rx, cy),
        Offset(cx, cy - ry),
        Offset(cx - rx, cy - ky),
        Offset(cx - kx, cy - ry),
        color: color,
        width: width,
      ));

      lines.add(TraceLine.sCurve(
        Offset(cx, cy - ry),
        Offset(cx + rx, cy),
        Offset(cx + kx, cy - ry),
        Offset(cx + rx, cy - ky),
        color: color,
        width: width,
      ));
    }

    return lines;
  }

  static List<TraceLine> _parseRect(String tag, Color defaultColor, double defaultWidth) {
    final List<TraceLine> lines = [];

    final x = _extractDouble(tag, 'x') ?? 0;
    final y = _extractDouble(tag, 'y') ?? 0;
    final width = _extractDouble(tag, 'width') ?? 0;
    final height = _extractDouble(tag, 'height') ?? 0;
    final rx = _extractDouble(tag, 'rx');
    final ry = _extractDouble(tag, 'ry');
    final color = _extractColor(tag, defaultColor);
    final strokeWidth = _extractStrokeWidth(tag, defaultWidth);

    if (width > 0 && height > 0) {
      if (rx != null && ry != null && rx > 0 && ry > 0) {


        lines.add(TraceLine.sCurve(
          Offset(x + rx, y),
          Offset(x + width - rx, y),
          Offset(x + rx, y - ry * 0.5),
          Offset(x + width - rx, y - ry * 0.5),
          color: color,
          width: strokeWidth,
        ));

        lines.add(TraceLine.sCurve(
          Offset(x + width, y + ry),
          Offset(x + width, y + height - ry),
          Offset(x + width + rx * 0.5, y + ry),
          Offset(x + width + rx * 0.5, y + height - ry),
          color: color,
          width: strokeWidth,
        ));

        lines.add(TraceLine.sCurve(
          Offset(x + width - rx, y + height),
          Offset(x + rx, y + height),
          Offset(x + width - rx, y + height + ry * 0.5),
          Offset(x + rx, y + height + ry * 0.5),
          color: color,
          width: strokeWidth,
        ));

        lines.add(TraceLine.sCurve(
          Offset(x, y + height - ry),
          Offset(x, y + ry),
          Offset(x - rx * 0.5, y + height - ry),
          Offset(x - rx * 0.5, y + ry),
          color: color,
          width: strokeWidth,
        ));
      } else {
        lines.add(TraceLine.straight(
          Offset(x, y),
          Offset(x + width, y),
          color: color,
          width: strokeWidth,
        ));
        lines.add(TraceLine.straight(
          Offset(x + width, y),
          Offset(x + width, y + height),
          color: color,
          width: strokeWidth,
        ));
        lines.add(TraceLine.straight(
          Offset(x + width, y + height),
          Offset(x, y + height),
          color: color,
          width: strokeWidth,
        ));
        lines.add(TraceLine.straight(
          Offset(x, y + height),
          Offset(x, y),
          color: color,
          width: strokeWidth,
        ));
      }
    }

    return lines;
  }

  static List<TraceLine> _parseLine(String tag, Color defaultColor, double defaultWidth) {
    final List<TraceLine> lines = [];

    final x1 = _extractDouble(tag, 'x1');
    final y1 = _extractDouble(tag, 'y1');
    final x2 = _extractDouble(tag, 'x2');
    final y2 = _extractDouble(tag, 'y2');
    final color = _extractColor(tag, defaultColor);
    final width = _extractStrokeWidth(tag, defaultWidth);

    if (x1 != null && y1 != null && x2 != null && y2 != null) {
      lines.add(TraceLine.straight(
        Offset(x1, y1),
        Offset(x2, y2),
        color: color,
        width: width,
      ));
    }

    return lines;
  }

  static List<TraceLine> _parsePolyline(String tag, Color defaultColor, double defaultWidth) {
    final List<TraceLine> lines = [];

    final pointsStr = _extractAttribute(tag, 'points');
    final color = _extractColor(tag, defaultColor);
    final width = _extractStrokeWidth(tag, defaultWidth);

    if (pointsStr != null) {
      final points = _parsePoints(pointsStr);
      for (int i = 0; i < points.length - 1; i++) {
        lines.add(TraceLine.straight(
          points[i],
          points[i + 1],
          color: color,
          width: width,
        ));
      }
    }

    return lines;
  }

  static List<TraceLine> _parsePolygon(String tag, Color defaultColor, double defaultWidth) {
    final List<TraceLine> lines = [];

    final pointsStr = _extractAttribute(tag, 'points');
    final color = _extractColor(tag, defaultColor);
    final width = _extractStrokeWidth(tag, defaultWidth);

    if (pointsStr != null) {
      final points = _parsePoints(pointsStr);
      for (int i = 0; i < points.length - 1; i++) {
        lines.add(TraceLine.straight(
          points[i],
          points[i + 1],
          color: color,
          width: width,
        ));
      }
      if (points.length > 2) {
        lines.add(TraceLine.straight(
          points.last,
          points.first,
          color: color,
          width: width,
        ));
      }
    }

    return lines;
  }

  static List<Offset> _parsePoints(String pointsStr) {
    final List<Offset> points = [];
    final numbers = pointsStr.trim().split(RegExp(r'[\s,]+'));

    for (int i = 0; i < numbers.length - 1; i += 2) {
      final x = double.tryParse(numbers[i]);
      final y = double.tryParse(numbers[i + 1]);
      if (x != null && y != null) {
        points.add(Offset(x, y));
      }
    }

    return points;
  }

  static double? _extractDouble(String tag, String attribute) {
    final regex = RegExp('$attribute="([^"]*)"');
    final match = regex.firstMatch(tag);
    if (match != null) {
      return double.tryParse(match.group(1)!);
    }
    return null;
  }

  static String? _extractAttribute(String tag, String attribute) {
    final regex = RegExp('$attribute="([^"]*)"');
    final match = regex.firstMatch(tag);
    return match?.group(1);
  }

  static List<TraceLine> _parsePathData(String pathData, Color color, double width) {
    final List<TraceLine> lines = [];
    final commands = _tokenizePath(pathData);

    Offset? currentPoint;
    Offset? startPoint;
    Offset? controlPoint;

    for (int i = 0; i < commands.length; i++) {
      final cmd = commands[i];

      switch (cmd.command) {
        case 'M':
        case 'm':
          if (cmd.parameters.length >= 2) {
            for (int j = 0; j < cmd.parameters.length; j += 2) {
              if (j + 1 < cmd.parameters.length) {
                final point = Offset(
                    cmd.parameters[j].toDouble(),
                    cmd.parameters[j + 1].toDouble()
                );

                if (cmd.command == 'm' && currentPoint != null) {
                  currentPoint = Offset(
                      currentPoint.dx + point.dx,
                      currentPoint.dy + point.dy
                  );
                } else {
                  currentPoint = point;
                }

                if (j == 0) {
                  startPoint = currentPoint;
                }
              }
            }
          }
          break;

        case 'L':
        case 'l':
          if (currentPoint != null && cmd.parameters.length >= 2) {
            for (int j = 0; j < cmd.parameters.length; j += 2) {
              if (j + 1 < cmd.parameters.length) {
                final end = Offset(
                    cmd.parameters[j].toDouble(),
                    cmd.parameters[j + 1].toDouble()
                );

                final actualEnd = cmd.command == 'l'
                    ? Offset(currentPoint!.dx + end.dx, currentPoint.dy + end.dy)
                    : end;

                lines.add(TraceLine.straight(currentPoint!, actualEnd, color: color, width: width));
                currentPoint = actualEnd;
              }
            }
          }
          break;

        case 'H':
          if (currentPoint != null && cmd.parameters.isNotEmpty) {
            for (final param in cmd.parameters) {
              final x = param.toDouble();
              final actualEnd = Offset(x, currentPoint!.dy);
              lines.add(TraceLine.straight(currentPoint, actualEnd, color: color, width: width));
              currentPoint = actualEnd;
            }
          }
          break;

        case 'h':
          if (currentPoint != null && cmd.parameters.isNotEmpty) {
            for (final param in cmd.parameters) {
              final dx = param.toDouble();
              final actualEnd = Offset(currentPoint!.dx + dx, currentPoint.dy);
              lines.add(TraceLine.straight(currentPoint, actualEnd, color: color, width: width));
              currentPoint = actualEnd;
            }
          }
          break;

        case 'V':
          if (currentPoint != null && cmd.parameters.isNotEmpty) {
            for (final param in cmd.parameters) {
              final y = param.toDouble();
              final actualEnd = Offset(currentPoint!.dx, y);
              lines.add(TraceLine.straight(currentPoint, actualEnd, color: color, width: width));
              currentPoint = actualEnd;
            }
          }
          break;

        case 'v':
          if (currentPoint != null && cmd.parameters.isNotEmpty) {
            for (final param in cmd.parameters) {
              final dy = param.toDouble();
              final actualEnd = Offset(currentPoint!.dx, currentPoint.dy + dy);
              lines.add(TraceLine.straight(currentPoint, actualEnd, color: color, width: width));
              currentPoint = actualEnd;
            }
          }
          break;

        case 'C':
        case 'c':
          if (currentPoint != null && cmd.parameters.length >= 6) {
            for (int j = 0; j < cmd.parameters.length; j += 6) {
              if (j + 5 < cmd.parameters.length) {
                final control1 = Offset(
                    cmd.parameters[j].toDouble(),
                    cmd.parameters[j + 1].toDouble()
                );
                final control2 = Offset(
                    cmd.parameters[j + 2].toDouble(),
                    cmd.parameters[j + 3].toDouble()
                );
                final end = Offset(
                    cmd.parameters[j + 4].toDouble(),
                    cmd.parameters[j + 5].toDouble()
                );

                final actualControl1 = cmd.command == 'c'
                    ? Offset(currentPoint!.dx + control1.dx, currentPoint.dy + control1.dy)
                    : control1;
                final actualControl2 = cmd.command == 'c'
                    ? Offset(currentPoint!.dx + control2.dx, currentPoint.dy + control2.dy)
                    : control2;
                final actualEnd = cmd.command == 'c'
                    ? Offset(currentPoint!.dx + end.dx, currentPoint.dy + end.dy)
                    : end;

                lines.add(TraceLine.sCurve(
                    currentPoint!,
                    actualEnd,
                    actualControl1,
                    actualControl2,
                    color: color,
                    width: width
                ));
                currentPoint = actualEnd;
                controlPoint = actualControl2;
              }
            }
          }
          break;

        case 'S':
        case 's':
          if (currentPoint != null && cmd.parameters.length >= 4) {
            for (int j = 0; j < cmd.parameters.length; j += 4) {
              if (j + 3 < cmd.parameters.length) {
                final control2 = Offset(
                    cmd.parameters[j].toDouble(),
                    cmd.parameters[j + 1].toDouble()
                );
                final end = Offset(
                    cmd.parameters[j + 2].toDouble(),
                    cmd.parameters[j + 3].toDouble()
                );

                final control1 = controlPoint != null
                    ? Offset(
                    currentPoint!.dx * 2 - controlPoint.dx,
                    currentPoint.dy * 2 - controlPoint.dy
                )
                    : currentPoint;

                final actualControl1 = cmd.command == 's'
                    ? Offset(currentPoint!.dx + control1!.dx, currentPoint.dy + control1.dy)
                    : control1;
                final actualControl2 = cmd.command == 's'
                    ? Offset(currentPoint!.dx + control2.dx, currentPoint.dy + control2.dy)
                    : control2;
                final actualEnd = cmd.command == 's'
                    ? Offset(currentPoint!.dx + end.dx, currentPoint.dy + end.dy)
                    : end;

                lines.add(TraceLine.sCurve(
                    currentPoint!,
                    actualEnd,
                    actualControl1!,
                    actualControl2,
                    color: color,
                    width: width
                ));
                currentPoint = actualEnd;
                controlPoint = actualControl2;
              }
            }
          }
          break;

        case 'Q':
        case 'q':
          if (currentPoint != null && cmd.parameters.length >= 4) {
            for (int j = 0; j < cmd.parameters.length; j += 4) {
              if (j + 3 < cmd.parameters.length) {
                final control = Offset(
                    cmd.parameters[j].toDouble(),
                    cmd.parameters[j + 1].toDouble()
                );
                final end = Offset(
                    cmd.parameters[j + 2].toDouble(),
                    cmd.parameters[j + 3].toDouble()
                );

                final actualControl = cmd.command == 'q'
                    ? Offset(currentPoint!.dx + control.dx, currentPoint.dy + control.dy)
                    : control;
                final actualEnd = cmd.command == 'q'
                    ? Offset(currentPoint!.dx + end.dx, currentPoint.dy + end.dy)
                    : end;

                lines.add(TraceLine.curve(
                    currentPoint!,
                    actualEnd,
                    actualControl,
                    color: color,
                    width: width
                ));
                currentPoint = actualEnd;
                controlPoint = actualControl;
              }
            }
          }
          break;

        case 'T':
        case 't':
          if (currentPoint != null && cmd.parameters.length >= 2) {
            for (int j = 0; j < cmd.parameters.length; j += 2) {
              if (j + 1 < cmd.parameters.length) {
                final end = Offset(
                    cmd.parameters[j].toDouble(),
                    cmd.parameters[j + 1].toDouble()
                );

                final control = controlPoint != null
                    ? Offset(
                    currentPoint!.dx * 2 - controlPoint.dx,
                    currentPoint.dy * 2 - controlPoint.dy
                )
                    : currentPoint;

                final actualControl = cmd.command == 't'
                    ? Offset(currentPoint!.dx + control!.dx, currentPoint.dy + control.dy)
                    : control;
                final actualEnd = cmd.command == 't'
                    ? Offset(currentPoint!.dx + end.dx, currentPoint.dy + end.dy)
                    : end;

                lines.add(TraceLine.curve(
                    currentPoint!,
                    actualEnd,
                    actualControl!,
                    color: color,
                    width: width
                ));
                currentPoint = actualEnd;
                controlPoint = actualControl;
              }
            }
          }
          break;

        case 'A':
        case 'a':
          if (currentPoint != null && cmd.parameters.length >= 7) {

            final x = cmd.parameters[5].toDouble();
            final y = cmd.parameters[6].toDouble();

            final actualEnd = cmd.command == 'a'
                ? Offset(currentPoint.dx + x, currentPoint.dy + y)
                : Offset(x, y);

            lines.add(TraceLine.straight(currentPoint, actualEnd, color: color, width: width));
            currentPoint = actualEnd;
          }
          break;

        case 'Z':
        case 'z':
          if (currentPoint != null && startPoint != null && currentPoint != startPoint) {
            lines.add(TraceLine.straight(currentPoint, startPoint, color: color, width: width));
            currentPoint = startPoint;
          }
          break;
      }
    }

    return lines;
  }

  static List<PathCommand> _tokenizePath(String pathData) {
    final List<PathCommand> commands = [];

    final RegExp tokenRegex = RegExp(
        r'([MLHVCSQTAZmlhvcsqtaz]|[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?)'
    );

    final matches = tokenRegex.allMatches(pathData);

    String? currentCommand;
    List<num> currentParams = [];

    for (final match in matches) {
      final token = match.group(0)!;

      if (RegExp(r'[MLHVCSQTAZmlhvcsqtaz]').hasMatch(token)) {
        if (currentCommand != null && currentParams.isNotEmpty) {
          commands.add(PathCommand(currentCommand, List.from(currentParams)));
        }
        currentCommand = token;
        currentParams = [];
      } else {
        final numValue = num.tryParse(token) ?? 0;
        currentParams.add(numValue);
      }
    }

    if (currentCommand != null && currentParams.isNotEmpty) {
      commands.add(PathCommand(currentCommand, currentParams));
    }

    return commands;
  }
}

class PathCommand {
  final String command;
  final List<num> parameters;

  PathCommand(this.command, this.parameters);
}

class SVGLoader extends ChangeNotifier {
  static final SVGLoader _instance = SVGLoader._internal();
  factory SVGLoader() => _instance;
  SVGLoader._internal();

  final Map<String, List<TraceLine>> _loadedSVGs = {};
  final Map<String, List<PathSegment>> _loadedSegments = {};

  Future<List<TraceLine>> loadSVG(String assetPath, {Color defaultColor = Colors.white, double defaultWidth = 4.0}) async {
    if (_loadedSVGs.containsKey(assetPath)) {
      return _loadedSVGs[assetPath]!;
    }

    try {
      final svgContent = await rootBundle.loadString(assetPath);

      final lines = SVGPathParser.parseSVG(
          svgContent,
          defaultColor: defaultColor,
          defaultWidth: defaultWidth
      );

      if (lines.isEmpty) {
        debugPrint('No path lines found in SVG: $assetPath');
        return [];
      }

      final scaledLines = _centerAndScaleLines(lines);

      _loadedSVGs[assetPath] = scaledLines;
      notifyListeners();
      return scaledLines;
    } catch (e) {
      debugPrint('Error loading SVG $assetPath: $e');
      return [];
    }
  }

  List<TraceLine> _centerAndScaleLines(List<TraceLine> lines) {
    if (lines.isEmpty) return lines;

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = -double.infinity;
    double maxY = -double.infinity;

    for (final line in lines) {
      for (int i = 0; i <= 10; i++) {
        final t = i / 10;
        final point = line.pointAt(t);
        minX = math.min(minX, point.dx);
        minY = math.min(minY, point.dy);
        maxX = math.max(maxX, point.dx);
        maxY = math.max(maxY, point.dy);
      }
    }

    final width = maxX - minX;
    final height = maxY - minY;
    final scale = (width > 0 && height > 0)
        ? 350.0 / math.max(width, height)
        : 1.0;

    final offsetX = (500 - width * scale) / 2 - minX * scale;
    final offsetY = (500 - height * scale) / 2 - minY * scale;

    return lines.map((line) {
      return TraceLine(
        start: Offset(
            line.start.dx * scale + offsetX,
            line.start.dy * scale + offsetY
        ),
        end: Offset(
            line.end.dx * scale + offsetX,
            line.end.dy * scale + offsetY
        ),
        control1: line.control1 != null
            ? Offset(
            line.control1!.dx * scale + offsetX,
            line.control1!.dy * scale + offsetY
        )
            : null,
        control2: line.control2 != null
            ? Offset(
            line.control2!.dx * scale + offsetX,
            line.control2!.dy * scale + offsetY
        )
            : null,
        color: line.color,
        width: line.width,
      );
    }).toList();
  }

  void clearCache() {
    _loadedSVGs.clear();
    _loadedSegments.clear();
    notifyListeners();
  }
}