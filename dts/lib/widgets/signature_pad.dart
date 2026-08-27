import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/rendering.dart';
import '../core/constants/app_colors.dart';

class SignaturePad extends StatefulWidget {
  final Function(File? file) onSignatureChanged;
  final String placeholderText;

  const SignaturePad({
    super.key,
    required this.onSignatureChanged,
    this.placeholderText = 'Sign here with your finger',
  });

  @override
  State<SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<SignaturePad> {
  final GlobalKey _boundaryKey = GlobalKey();
  final List<Offset?> _points = [];
  bool _hasSigned = false;

  void _clear() {
    setState(() {
      _points.clear();
      _hasSigned = false;
    });
    widget.onSignatureChanged(null);
  }

  Future<void> _exportSignature() async {
    if (!_hasSigned || _points.isEmpty) return;

    try {
      final boundary = _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/technician_signature_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes);

      widget.onSignatureChanged(file);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error exporting signature: $e');
      }
    }
  }

  void _addPoint(Offset localPosition) {
    setState(() {
      _points.add(localPosition);
      _hasSigned = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.border, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                Positioned.fill(
                  child: RepaintBoundary(
                    key: _boundaryKey,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onVerticalDragStart: (_) {},
                      onVerticalDragUpdate: (_) {},
                      onHorizontalDragStart: (_) {},
                      onHorizontalDragUpdate: (_) {},
                      child: Listener(
                        behavior: HitTestBehavior.opaque,
                        onPointerDown: (event) {
                          _addPoint(event.localPosition);
                        },
                        onPointerMove: (event) {
                          _addPoint(event.localPosition);
                        },
                        onPointerUp: (event) {
                          setState(() {
                            _points.add(null);
                          });
                          _exportSignature();
                        },
                        onPointerCancel: (event) {
                          setState(() {
                            _points.add(null);
                          });
                          _exportSignature();
                        },
                        child: CustomPaint(
                          painter: _SignaturePainter(points: _points),
                          size: Size.infinite,
                        ),
                      ),
                    ),
                  ),
                ),
                if (!_hasSigned)
                  IgnorePointer(
                    child: Center(
                      child: Text(
                        widget.placeholderText,
                        style: const TextStyle(color: AppColors.textLight, fontSize: 13),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_hasSigned)
              Row(
                children: const [
                  Icon(Icons.check_circle, color: AppColors.success, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Signature captured',
                    style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              )
            else
              const SizedBox(),
            TextButton.icon(
              onPressed: _clear,
              icon: const Icon(Icons.clear, size: 16),
              label: const Text('Clear / Re-sign'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<Offset?> points;

  _SignaturePainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Fill background with crisp white
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(Offset.zero & size, bgPaint);

    if (points.isEmpty) return;

    // 2. Draw signature strokes
    final strokePaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 3.5;

    final dotPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    // Render single dots for quick taps
    for (int i = 0; i < points.length; i++) {
      if (points[i] != null) {
        if ((i == 0 || points[i - 1] == null) &&
            (i + 1 >= points.length || points[i + 1] == null)) {
          canvas.drawCircle(points[i]!, 1.75, dotPaint);
        }
      }
    }

    // Render smooth quadratic bezier curve paths
    Path? path;
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];

      if (p1 != null && p2 != null) {
        if (path == null) {
          path = Path();
          path.moveTo(p1.dx, p1.dy);
        }
        final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
        path.quadraticBezierTo(p1.dx, p1.dy, mid.dx, mid.dy);
      } else {
        if (path != null) {
          canvas.drawPath(path, strokePaint);
          path = null;
        }
      }
    }
    if (path != null) {
      canvas.drawPath(path, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
