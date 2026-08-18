import 'package:flutter/material.dart';
import 'package:app_guia_ar/core/theme/app_theme.dart';

class LoadingOverlay {
  static OverlayEntry? _overlayEntry;

  static void show(BuildContext context, {String? message}) {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => _LoadingOverlayWidget(message: message),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  static void updateMessage(BuildContext context, String message) {
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
    }
  }

  static void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  static bool get isVisible => _overlayEntry != null;
}

class _LoadingOverlayWidget extends StatefulWidget {
  final String? message;

  const _LoadingOverlayWidget({this.message});

  @override
  State<_LoadingOverlayWidget> createState() => _LoadingOverlayWidgetState();
}

class _LoadingOverlayWidgetState extends State<_LoadingOverlayWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeIn,
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: Center(
          child: ScaleTransition(
            scale: _scale,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  if (widget.message != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      widget.message!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LoadingController extends ChangeNotifier {
  bool _isLoading = false;
  String? _message;

  bool get isLoading => _isLoading;
  String? get message => _message;

  void show(BuildContext context, {String? message}) {
    _isLoading = true;
    _message = message;
    notifyListeners();
    LoadingOverlay.show(context, message: message);
  }

  void updateMessage(BuildContext context, String message) {
    _message = message;
    notifyListeners();
    LoadingOverlay.updateMessage(context, message);
  }

  void hide() {
    _isLoading = false;
    _message = null;
    notifyListeners();
    LoadingOverlay.hide();
  }
}
