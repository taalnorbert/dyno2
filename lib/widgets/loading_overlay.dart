import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:go_router/go_router.dart';
import '../localization/app_localizations.dart';
class LoadingOverlay extends StatefulWidget {
  final Duration timeout;
  final VoidCallback? onTimeout;
  final Color spinnerColor;
  final double opacity;
  final double blur;
  final double strokeWidth;

  const LoadingOverlay({
    super.key,
    this.timeout = const Duration(seconds: 7),
    this.onTimeout,
    this.spinnerColor = Colors.red,
    this.opacity = 0.7,
    this.blur = 5.0,
    this.strokeWidth = 3.0,
  });

  @override
  State<LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<LoadingOverlay> {
  Timer? _timeoutTimer;
  bool _hasTimedOut = false;

  @override
  void initState() {
    super.initState();
    if (widget.timeout.inMilliseconds > 0) {
      _timeoutTimer = Timer(widget.timeout, _handleTimeout);
    }
  }

  void _handleTimeout() {
    if (mounted) {
      setState(() {
        _hasTimedOut = true;
      });
      if (widget.onTimeout != null) {
        widget.onTimeout!();
      }
    }
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        // ignore: deprecated_member_use
        color: Colors.black.withOpacity(widget.opacity),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: widget.blur, sigmaY: widget.blur),
          child: Center(
            child: _hasTimedOut
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, color: Colors.white, size: 48),
                      SizedBox(height: 16),
                      Text(
                        'A művelet túllépte az időkorlátot.',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          // Ha van onTimeout callback, azt hívjuk meg
                          if (widget.onTimeout != null) {
                            widget.onTimeout!();
                          }
                          // Ha nincs callback, akkor alapértelmezés szerint lépjünk vissza
                          else {
                            if (Navigator.of(context).canPop()) {
                              context.pop();
                            } else {
                              context.go('/');
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        // Helyettesítsük AppLocalizations.back-kel:
                        child: Text(AppLocalizations.back),
                      ),
                    ],
                  )
                : CircularProgressIndicator(
                    color: widget.spinnerColor,
                    strokeWidth: widget.strokeWidth,
                  ),
          ),
        ),
      ),
    );
  }
}
