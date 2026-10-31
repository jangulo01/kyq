import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'document_scanner.dart';
import 'image_tools.dart';

/// Recorte manual (010, FR-013) para teléfonos sin escáner: el conductor arrastra las cuatro
/// esquinas sobre los bordes del documento y la foto se endereza. Devuelve el JPEG o null.
class ManualCropPage extends StatefulWidget {
  const ManualCropPage({super.key, required this.photo, required this.scanner});

  final Uint8List photo;
  final DocumentScanner scanner;

  @override
  State<ManualCropPage> createState() => _ManualCropPageState();
}

class _ManualCropPageState extends State<ManualCropPage> {
  final _corners = [...defaultCorners];
  Size? _size;
  bool _working = false;

  @override
  void initState() {
    super.initState();
    _measure();
  }

  Future<void> _measure() async {
    try {
      final codec = await ui.instantiateImageCodec(widget.photo);
      final frame = await codec.getNextFrame();
      final size = Size(frame.image.width.toDouble(), frame.image.height.toDouble());
      frame.image.dispose();
      codec.dispose();
      if (mounted) setState(() => _size = size);
    } on Object {
      // Sin tamaño se usa un documento horizontal típico; el recorte sigue funcionando.
      if (mounted) setState(() => _size = const Size(1.6, 1));
    }
  }

  Future<void> _done() async {
    setState(() => _working = true);
    final navigator = Navigator.of(context);
    final out = await widget.scanner.rectify(widget.photo, List.unmodifiable(_corners));
    if (!mounted) return;
    if (out == null) {
      setState(() => _working = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No pudimos recortar la foto.')));
      return;
    }
    navigator.pop(out);
  }

  @override
  Widget build(BuildContext context) {
    final size = _size;
    return Scaffold(
      appBar: AppBar(title: const Text('Ajusta los bordes')),
      body: Column(
        children: [
          const Padding(padding: EdgeInsets.all(12), child: Text('Arrastra cada punto a una esquina del documento.')),
          Expanded(
            child: size == null
                ? const Center(child: CircularProgressIndicator())
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final fitted = applyBoxFit(BoxFit.contain, size, constraints.biggest).destination;
                      final rect = Alignment.center.inscribe(fitted, Offset.zero & constraints.biggest);
                      Offset toScreen(Offset c) => rect.topLeft + Offset(c.dx * rect.width, c.dy * rect.height);
                      return Stack(
                        children: [
                          Positioned.fromRect(
                            rect: rect,
                            child: Image.memory(widget.photo, fit: BoxFit.fill),
                          ),
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _QuadPainter([
                                for (final c in _corners) toScreen(c),
                              ], Theme.of(context).colorScheme.primary),
                            ),
                          ),
                          for (var i = 0; i < 4; i++)
                            Positioned(
                              left: toScreen(_corners[i]).dx - 22,
                              top: toScreen(_corners[i]).dy - 22,
                              child: GestureDetector(
                                key: Key('crop.corner.$i'),
                                onPanUpdate: (d) => setState(() {
                                  final c = _corners[i] + Offset(d.delta.dx / rect.width, d.delta.dy / rect.height);
                                  _corners[i] = Offset(c.dx.clamp(0, 1), c.dy.clamp(0, 1));
                                }),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  alignment: Alignment.center,
                                  child: Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.85),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: OverflowBar(
                alignment: MainAxisAlignment.end,
                spacing: 8,
                children: [
                  TextButton(
                    onPressed: () => setState(() => _corners.setAll(0, defaultCorners)),
                    child: const Text('Reiniciar'),
                  ),
                  FilledButton(
                    key: const Key('crop.done'),
                    onPressed: _working || size == null ? null : _done,
                    child: const Text('Usar recorte'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuadPainter extends CustomPainter {
  _QuadPainter(this.points, this.color);

  final List<Offset> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..addPolygon(points, true);
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.15));
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_QuadPainter old) => old.points != points || old.color != color;
}
