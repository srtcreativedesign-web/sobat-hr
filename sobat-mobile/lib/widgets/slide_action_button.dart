import 'package:flutter/material.dart';

class SlideActionWidget extends StatefulWidget {
  final String text;
  final VoidCallback onSubmit;
  final Color backgroundColor;
  final Color thumbColor;
  final IconData thumbIcon;
  final bool isReversed;

  const SlideActionWidget({
    Key? key,
    required this.text,
    required this.onSubmit,
    this.backgroundColor = const Color(0xFF419CC3),
    this.thumbColor = Colors.white,
    this.thumbIcon = Icons.arrow_forward_ios_rounded,
    this.isReversed = false,
  }) : super(key: key);

  @override
  _SlideActionWidgetState createState() => _SlideActionWidgetState();
}

class _SlideActionWidgetState extends State<SlideActionWidget>
    with SingleTickerProviderStateMixin {
  double _dragPosition = 0.0;
  bool _submitted = false;
  final GlobalKey _containerKey = GlobalKey();
  double _containerWidth = 0.0;
  static const double _thumbSize = 48.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _containerKey.currentContext;
      if (context != null) {
        setState(() {
          _containerWidth = context.size!.width;
        });
      }
    });
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_submitted || _containerWidth == 0.0) return;
    
    setState(() {
      _dragPosition += details.delta.dx;
      // Clamp the position
      if (_dragPosition < 0) _dragPosition = 0;
      if (_dragPosition > _containerWidth - _thumbSize) {
        _dragPosition = _containerWidth - _thumbSize;
      }
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (_submitted || _containerWidth == 0.0) return;

    if (_dragPosition > (_containerWidth - _thumbSize) * 0.8) {
      // Threshold reached, submit!
      setState(() {
        _dragPosition = _containerWidth - _thumbSize;
        _submitted = true;
      });
      widget.onSubmit();
      
      // Reset after a delay if needed
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _submitted = false;
            _dragPosition = 0;
          });
        }
      });
    } else {
      // Snap back
      setState(() {
        _dragPosition = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: _containerKey,
      height: 56,
      decoration: BoxDecoration(
        color: widget.backgroundColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: widget.backgroundColor.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          // Background Text
          Center(
            child: AnimatedOpacity(
              opacity: _submitted ? 0.0 : 1.0 - (_dragPosition / (_containerWidth > 0 ? _containerWidth : 1)),
              duration: const Duration(milliseconds: 100),
              child: Text(
                widget.text,
                style: TextStyle(
                  color: widget.backgroundColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          // Draggable Thumb
          Positioned(
            left: _dragPosition,
            child: GestureDetector(
              onHorizontalDragUpdate: _onDragUpdate,
              onHorizontalDragEnd: _onDragEnd,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                width: _thumbSize,
                height: _thumbSize,
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: widget.backgroundColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.backgroundColor.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Center(
                  child: _submitted
                      ? Icon(Icons.check, color: widget.thumbColor)
                      : Icon(widget.thumbIcon, color: widget.thumbColor, size: 20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
