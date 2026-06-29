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
    if (!_hasSigned) return;

    try {
      final boundary = _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/customer_signature_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes);

      widget.onSignatureChanged(file);
    } catch (e) {
      if (kDebugMode) {
        print('Error exporting signature: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border.all(color: AppColors.border, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                if (!_hasSigned)
                  Center(
                    child: Text(
                      widget.placeholderText,
                      style: const TextStyle(color: AppColors.textLight, fontSize: 13),
                    ),
                  ),
                RepaintBoundary(
                  key: _boundaryKey,
                  child: GestureDetector(
                    onPanStart: (details) {
                      final box = context.findRenderObject() as RenderBox?;
                      if (box != null) {
                        final localPos = box.globalToLocal(details.globalPosition);
                        setState(() {
                          _points.add(localPos);
                          _hasSigned = true;
                        });
                      }
                    },
                    onPanUpdate: (details) {
                      final box = context.findRenderObject() as RenderBox?;
                      if (box != null) {
                        final localPos = box.globalToLocal(details.globalPosition);
                        setState(() {
                          _points.add(localPos);
                        });
                      }
                    },
                    onPanEnd: (details) {
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
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
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
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      } else if (points[i] != null && points[i + 1] == null) {
        canvas.drawCircle(points[i]!, 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
