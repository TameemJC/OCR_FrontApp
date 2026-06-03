import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'svg_parser.dart';
import 'trace_line.dart';
import 'ocr_tool_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Samaritan Scribe',
      debugShowCheckedModeBanner: false,
      home: EasyTraceScreen(),
    );
  }
}



class TraceShape {
  final String name;
  final Color color;
  final IconData icon;
  final List<TraceLine> lines;
  final String? svgAsset;

  const TraceShape({
    required this.name,
    required this.color,
    required this.icon,
    required this.lines,
    this.svgAsset,
  });

  factory TraceShape.fromSVG({
    required String name,
    required Color color,
    required IconData icon,
    required String svgAsset,
    double lineWidth = 4.0,
  }) {
    return TraceShape(
      name: name,
      color: color,
      icon: icon,
      lines: [],
      svgAsset: svgAsset,
    );
  }

  static final TraceShape wave = TraceShape.fromSVG(
    name: 'aleph',
    color: Colors.pink,
    icon: Icons.brush,
    svgAsset: 'assets/golden_shapes/aleph.svg',
  );

  static final TraceShape beth = TraceShape.fromSVG(
    name: 'beth',
    color: Colors.pink,
    icon: Icons.brush,
    svgAsset: 'assets/golden_shapes/beth.svg',
  );

  static final TraceShape star = TraceShape.fromSVG(
    name: 'gimel',
    color: Colors.pink,
    icon: Icons.brush,
    svgAsset: 'assets/golden_shapes/gimel.svg',
  );

  static final TraceShape circle = TraceShape.fromSVG(
    name: 'daleth',
    color: Colors.pink,
    icon: Icons.brush,
    svgAsset: 'assets/golden_shapes/daleth.svg',
  );

  static final TraceShape square = TraceShape.fromSVG(
    name: 'he',
    color: Colors.pink,
    icon: Icons.brush,
    svgAsset: 'assets/golden_shapes/he.svg',
  );

  static final TraceShape bah = TraceShape.fromSVG(
    name: 'bah',
    color: Colors.pink,
    icon: Icons.brush,
    svgAsset: 'assets/golden_shapes/bah.svg',
  );

  static final TraceShape zen = TraceShape.fromSVG(
    name: 'zen',
    color: Colors.pink,
    icon: Icons.brush,
    svgAsset: 'assets/golden_shapes/zen.svg',
  );

  static final TraceShape it = TraceShape.fromSVG(
    name: 'it',
    color: Colors.pink,
    icon: Icons.brush,
    svgAsset: 'assets/golden_shapes/it.svg',
  );

  static final TraceShape tit = TraceShape.fromSVG(
    name: 'tit',
    color: Colors.pink,
    icon: Icons.brush,
    svgAsset: 'assets/golden_shapes/tit.svg',
  );

  static final TraceShape yeat = TraceShape.fromSVG(
    name: 'yeat',
    color: Colors.pink,
    icon: Icons.brush,
    svgAsset: 'assets/golden_shapes/yeat.svg',
  );

  static final TraceShape kaf = TraceShape.fromSVG(
    name: 'kaf',
    color: Colors.pink,
    icon: Icons.brush,
    svgAsset: 'assets/golden_shapes/kaf.svg',
  );

  static final TraceShape labat = TraceShape.fromSVG(
    name: 'labat',
    color: Colors.pink,
    icon: Icons.brush,
    svgAsset: 'assets/golden_shapes/labat.svg',
  );

  static final TraceShape mim = TraceShape.fromSVG(
    name: 'mim',
    color: Colors.pink,
    icon: Icons.brush,
    svgAsset: 'assets/golden_shapes/mim.svg',
  );

  static final TraceShape nun = TraceShape.fromSVG(
    name: 'nun',
    color: Colors.pink,
    icon: Icons.brush,
    svgAsset: 'assets/golden_shapes/nun.svg',
  );

  static final TraceShape singat = TraceShape.fromSVG(
    name: 'singat',
    color: Colors.pink,
    icon: Icons.brush,
    svgAsset: 'assets/golden_shapes/singat.svg',
  );

  static final TraceShape ion = TraceShape.fromSVG(
    name: 'ion',
    color: Colors.pink,
    icon: Icons.brush,
    svgAsset: 'assets/golden_shapes/ion.svg',
  );

  static final TraceShape fi = TraceShape.fromSVG(
    name: 'fi',
    color: Colors.pink,
    icon: Icons.brush,
    svgAsset: 'assets/golden_shapes/fi.svg',
  );

  static final TraceShape sadiy = TraceShape.fromSVG(
    name: 'sadiy',
    color: Colors.pink,
    icon: Icons.brush,
    svgAsset: 'assets/golden_shapes/sadiy.svg',
  );

  static final TraceShape quf = TraceShape.fromSVG(
    name: 'quf',
    color: Colors.pink,
    icon: Icons.brush,
    svgAsset: 'assets/golden_shapes/quf.svg',
  );

  static final TraceShape ris = TraceShape.fromSVG(
    name: 'ris',
    color: Colors.pink,
    icon: Icons.brush,
    svgAsset: 'assets/golden_shapes/ris.svg',
  );

  static final TraceShape san = TraceShape.fromSVG(
    name: 'san',
    color: Colors.pink,
    icon: Icons.brush,
    svgAsset: 'assets/golden_shapes/san.svg',
  );

  static final TraceShape taf = TraceShape.fromSVG(
    name: 'taf',
    color: Colors.pink,
    icon: Icons.brush,
    svgAsset: 'assets/golden_shapes/taf.svg',
  );

  static final TraceShape cav = TraceShape.fromSVG(
    name: '??',
    color: Colors.pink,
    icon: Icons.brush,
    svgAsset: 'assets/golden_shapes/cav.svg',
  );

  static final List<TraceShape> preMadeShapes = [
    wave, beth, star, circle, square, bah, zen, it, tit, yeat, labat, mim,
    kaf, nun, singat, ion, fi, sadiy, quf, ris, san, taf, cav
  ];
}

class TraceProgress {
  int currentLineIndex = 0;
  final Map<int, Set<int>> drawnSegments = {};
  final Map<int, bool> completedLines = {};
  double totalProgress = 0.0;
  String message = '';
  bool isTooFar = false;

  TraceProgress(int lineCount) {
    for (int i = 0; i < lineCount; i++) {
      drawnSegments[i] = {};
      completedLines[i] = false;
    }
  }

  void update(int lineIndex, double t, double distance) {
    isTooFar = distance > 50;
    if (isTooFar) {
      message = '👆 Get closer!';
      return;
    }

    if (lineIndex != currentLineIndex) {
      if (completedLines[currentLineIndex] == true) {
        currentLineIndex = lineIndex;
        message = '✅ Good! Next line';
      } else {
        message = '⚠️ Draw line ${currentLineIndex + 1} first';
        return;
      }
    }

    final segmentIndex = (t * 100).round();
    final segments = drawnSegments[lineIndex]!;
    for (int i = -5; i <= 5; i++) {
      segments.add((segmentIndex + i).clamp(0, 100));
    }

    final lineProgress = segments.length / 101.0;
    if (lineProgress > 0.85 && !completedLines[lineIndex]!) {
      completedLines[lineIndex] = true;
      message = '🎉 Line ${lineIndex + 1} done!';

      if (lineIndex + 1 < completedLines.length) {
        currentLineIndex = lineIndex + 1;
      }
    }

    double total = 0;
    for (int i = 0; i < completedLines.length; i++) {
      total += (drawnSegments[i]?.length ?? 0) / 101.0;
    }
    totalProgress = total / completedLines.length;
  }

  double lineProgress(int lineIndex) {
    return ((drawnSegments[lineIndex]?.length ?? 0) / 101.0).clamp(0.0, 1.0);
  }

  bool isLineComplete(int lineIndex) {
    return completedLines[lineIndex] ?? false;
  }

  void reset() {
    currentLineIndex = 0;
    for (var segments in drawnSegments.values) {
      segments.clear();
    }
    for (var key in completedLines.keys) {
      completedLines[key] = false;
    }
    totalProgress = 0.0;
    message = '';
    isTooFar = false;
  }
}

class TracePainter extends CustomPainter {
  final TraceShape shape;
  final TraceProgress progress;
  final double animation;
  final Offset? fingerPosition;
  final Size canvasSize;
  final double shapeScale;

  const TracePainter({
    required this.shape,
    required this.progress,
    required this.animation,
    this.fingerPosition,
    required this.canvasSize,
    this.shapeScale = 0.6,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();

    final scale = shapeScale;
    final scaledWidth = size.width * scale;
    final scaledHeight = size.height * scale;
    final offsetX = (size.width - scaledWidth) / 2;
    final offsetY = (size.height - scaledHeight) / 2;

    canvas.translate(offsetX, offsetY);
    canvas.scale(scale);

    _drawBackground(canvas, Size(scaledWidth, scaledHeight));

    for (int i = 0; i < shape.lines.length; i++) {
      _drawLine(canvas, shape.lines[i], i, Size(scaledWidth, scaledHeight));
    }

    if (fingerPosition != null) {
      final transformedFinger = Offset(
        (fingerPosition!.dx - offsetX) / scale,
        (fingerPosition!.dy - offsetY) / scale,
      );
      _drawFingerGuide(canvas, transformedFinger);
    }

    if (progress.message.isNotEmpty) {
      _drawMessage(canvas, progress.message, Size(scaledWidth, scaledHeight));
    }

    canvas.restore();
  }

  void _drawBackground(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withAlpha(5)
      ..strokeWidth = 0.5;

    for (double x = 0; x < size.width; x += 25) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 25) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  void _drawLine(Canvas canvas, TraceLine line, int index, Size size) {
    final points = _getLinePoints(line, 40);
    if (points.isEmpty) return;

    final isCurrent = index == progress.currentLineIndex;
    final isComplete = progress.isLineComplete(index);

    for (int i = 0; i < points.length - 1; i++) {
      final isDrawn = progress.drawnSegments[index]?.contains(i) ?? false;

      Paint paint;
      if (isDrawn) {
        paint = Paint()
          ..color = line.color
          ..strokeWidth = line.width * 1.5
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
      } else if (isComplete) {
        paint = Paint()
          ..color = line.color.withAlpha(100)
          ..strokeWidth = line.width
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
      } else if (isCurrent) {
        final pulse = 0.3 + 0.2 * math.sin(animation * 5);
        paint = Paint()
          ..color = line.color.withAlpha((255/pulse).round())
          ..strokeWidth = line.width
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
      } else {
        paint = Paint()
          ..color = line.color.withAlpha(25)
          ..strokeWidth = line.width
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
      }

      canvas.drawLine(points[i], points[i + 1], paint);
    }

    _drawLineNumber(canvas, line.start, index + 1, isCurrent, isComplete);
  }

  void _drawLineNumber(Canvas canvas, Offset pos, int number, bool isCurrent, bool isComplete) {
    final bgPaint = Paint()
      ..color = isComplete ? Colors.green : (isCurrent ? Colors.blue : Colors.grey)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(pos, 16, bgPaint);

    final textSpan = TextSpan(
      text: number.toString(),
      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
    );
    final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
    textPainter.layout();
    textPainter.paint(canvas, Offset(pos.dx - 7, pos.dy - 9));
  }

  void _drawFingerGuide(Canvas canvas, Offset position) {
    final ringPaint = Paint()
      ..color = progress.isTooFar ? Colors.red : Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawCircle(position, 35, ringPaint);

    final pulsePaint = Paint()
      ..color = (progress.isTooFar ? Colors.red : Colors.blue).withAlpha(100)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(position, 28 + 5 * math.sin(animation * 5), pulsePaint);
  }

  void _drawMessage(Canvas canvas, String message, Size size) {
    final textSpan = TextSpan(
      text: message,
      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
    );
    final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
    textPainter.layout();

    final rect = Rect.fromLTWH(
      (size.width - textPainter.width) / 2 - 15,
      20,
      textPainter.width + 30,
      textPainter.height + 16,
    );

    final bgPaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(12)),
      bgPaint,
    );

    textPainter.paint(canvas, Offset(rect.left + 15, rect.top + 8));
  }

  List<Offset> _getLinePoints(TraceLine line, int segments) {
    return line.getPointsAtSegments(segments);
  }

  @override
  bool shouldRepaint(covariant TracePainter oldDelegate) => true;
}


class EasyTraceWidget extends StatefulWidget {
  final TraceShape shape;
  final VoidCallback? onComplete;

  const EasyTraceWidget({
    super.key,
    required this.shape,
    this.onComplete,
  });

  @override
  State<EasyTraceWidget> createState() => _EasyTraceWidgetState();
}

class _EasyTraceWidgetState extends State<EasyTraceWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late TraceProgress _progress;
  Offset? _fingerPosition;
  bool _isLoading = false;
  List<TraceLine> _loadedLines = [];
  final GlobalKey _paintKey = GlobalKey();

  final double _shapeScale = 0.55;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..repeat();
    _initializeShape();
  }

  Future<void> _initializeShape() async {
    if (widget.shape.svgAsset != null) {
      setState(() => _isLoading = true);

      try {
        final lines = await SVGLoader().loadSVG(
          widget.shape.svgAsset!,
          defaultColor: widget.shape.color,
          defaultWidth: 5.0,
        );

        setState(() {
          _loadedLines = lines;
          _isLoading = false;
          _progress = TraceProgress(lines.length);
        });
      } catch (e) {
        setState(() => _isLoading = false);
      }
    } else {
      _progress = TraceProgress(widget.shape.lines.length);
    }
  }

  @override
  void didUpdateWidget(EasyTraceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shape != widget.shape) {
      _initializeShape();
    }
  }

  void _handlePanStart(DragStartDetails details) {
    HapticFeedback.lightImpact();
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    final lines = _getCurrentLines();
    if (lines.isEmpty) return;

    final RenderBox? renderBox = _paintKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final rawPos = renderBox.globalToLocal(details.globalPosition);

    final clampedPos = Offset(
      rawPos.dx.clamp(0.0, renderBox.size.width),
      rawPos.dy.clamp(0.0, renderBox.size.height),
    );

    final transformedPos = _transformToScaledCoordinates(clampedPos, renderBox.size);

    int bestLine = -1;
    double bestT = 0;
    double bestDistance = double.infinity;

    for (int i = 0; i < lines.length; i++) {
      if (_progress.isLineComplete(i)) continue;

      final line = lines[i];
      final t = line.closestT(transformedPos, samples: 30);
      final point = line.pointAt(t);
      final distance = (transformedPos - point).distance;

      if (distance < bestDistance) {
        bestDistance = distance;
        bestT = t;
        bestLine = i;
      }
    }

    if (bestLine != -1 && bestDistance < 60) {
      _progress.update(bestLine, bestT, bestDistance);
      if (_progress.lineProgress(bestLine) > 0 && bestDistance < 30) {
        HapticFeedback.selectionClick();
      }
    }

    setState(() {
      _fingerPosition = clampedPos;
    });

    if (_progress.totalProgress > 0.95) {
      widget.onComplete?.call();
    }
  }

  Offset _transformToScaledCoordinates(Offset touchPoint, Size canvasSize) {
    final scale = _shapeScale;
    final scaledWidth = canvasSize.width * scale;
    final scaledHeight = canvasSize.height * scale;
    final offsetX = (canvasSize.width - scaledWidth) / 2;
    final offsetY = (canvasSize.height - scaledHeight) / 2;

    if (touchPoint.dx >= offsetX &&
        touchPoint.dx <= offsetX + scaledWidth &&
        touchPoint.dy >= offsetY &&
        touchPoint.dy <= offsetY + scaledHeight) {

      return Offset(
        (touchPoint.dx - offsetX) / scale,
        (touchPoint.dy - offsetY) / scale,
      );
    }

    return Offset(
      (touchPoint.dx - offsetX) / scale,
      (touchPoint.dy - offsetY) / scale,
    );
  }

  void _handlePanEnd(DragEndDetails details) {
    setState(() => _fingerPosition = null);
  }

  List<TraceLine> _getCurrentLines() {
    return _loadedLines.isNotEmpty ? _loadedLines : widget.shape.lines;
  }

  void _resetDrawing() {
    setState(() {
      _progress.reset();
      _fingerPosition = null;
    });
    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lines = _getCurrentLines();
    final screenSize = MediaQuery.of(context).size;
    final canvasSize = math.min(screenSize.width - 32, screenSize.height - 200);
    final canvasDimension = canvasSize.clamp(300.0, 500.0);

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (lines.isEmpty) {
      return const Center(
        child: Text('No shape loaded', style: TextStyle(color: Colors.white)),
      );
    }

    return GestureDetector(
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      child: Container(
        color: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: SizedBox(
                width: canvasDimension,
                height: canvasDimension*1.1,
                child: RepaintBoundary(
                  child: CustomPaint(
                    key: _paintKey,
                    painter: TracePainter(
                      shape: TraceShape(
                        name: widget.shape.name,
                        color: widget.shape.color,
                        icon: widget.shape.icon,
                        lines: lines,
                      ),
                      progress: _progress,
                      animation: _controller.value,
                      fingerPosition: _fingerPosition,
                      canvasSize: Size(canvasDimension, canvasDimension),
                      shapeScale: _shapeScale,
                    ),
                    size: Size(canvasDimension, canvasDimension),
                  ),
                ),
              ),
            ),

            Positioned(
              top: 8,
              left: 16,
              right: 16,
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Stack(
                  children: [
                    FractionallySizedBox(
                      widthFactor: _progress.totalProgress,
                      child: Container(
                        decoration: BoxDecoration(
                          color: widget.shape.color,
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        '${(_progress.totalProgress * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Positioned(
              bottom: 8,
              left: 16,
              child: GestureDetector(
                onTap: _resetDrawing,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.refresh, color: Colors.white, size: 20),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class EasyTraceScreen extends StatefulWidget {
  const EasyTraceScreen({super.key});

  @override
  State<EasyTraceScreen> createState() => _EasyTraceScreenState();
}

class _EasyTraceScreenState extends State<EasyTraceScreen> {
  TraceShape _currentShape = TraceShape.wave;
  final List<TraceShape> _allShapes = TraceShape.preMadeShapes;

  void _showComplete() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎉 Beautiful ${_currentShape.name}!'),
        backgroundColor: _currentShape.color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                'Samaritan Scribe',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: screenSize.width < 400 ? 20 : 24,
                                    fontWeight: FontWeight.bold
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.amber.withAlpha(50),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.amber),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.document_scanner, color: Colors.amber),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const OCRToolPage()),
                                  );
                                },
                                tooltip: 'Samaritan OCR Tool',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _currentShape.color.withAlpha(50),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: _currentShape.color),
                              ),
                              child: Row(
                                children: [
                                  Icon(_currentShape.icon, color: _currentShape.color, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    _currentShape.name,
                                    style: TextStyle(
                                      color: _currentShape.color,
                                      fontWeight: FontWeight.bold,
                                      fontSize: screenSize.width < 400 ? 12 : 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(
                        height: 50,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _allShapes.length,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemBuilder: (context, index) {
                            final shape = _allShapes[index];
                            final isSelected = shape == _currentShape;

                            return GestureDetector(
                              onTap: () => setState(() => _currentShape = shape),
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSelected ? shape.color : Colors.grey[800],
                                  borderRadius: BorderRadius.circular(20),
                                  border: isSelected ? Border.all(color: Colors.white, width: 1.5) : null,
                                ),
                                child: Row(
                                  children: [
                                    Icon(shape.icon, color: Colors.white, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      shape.name,
                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 16),

                      Container(
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _currentShape.color.withAlpha(100)),
                          boxShadow: [
                            BoxShadow(
                              color: _currentShape.color.withAlpha(25),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: EasyTraceWidget(
                            shape: _currentShape,
                            onComplete: _showComplete,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.touch_app, color: _currentShape.color, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'Trace with your finger',
                              style: TextStyle(color: Colors.grey[400], fontSize: 12),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              width: 1,
                              height: 12,
                              color: Colors.grey[700],
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.document_scanner, color: Colors.amber, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'OCR tool',
                              style: TextStyle(color: Colors.amber[300], fontSize: 12),
                            ),
                          ],
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
    );
  }
}