import 'package:flutter/material.dart';
import 'package:app_guia_ar/core/errors/app_exceptions.dart';

enum NotificationType { success, error, warning, info }

class AppNotifications {
  AppNotifications._();

  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason>?
      _currentSnackBar;

  static void showSuccess(
    BuildContext context, {
    required String title,
    required String description,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onDismiss,
  }) {
    _showNotification(
      context,
      type: NotificationType.success,
      title: title,
      description: description,
      icon: Icons.check_circle,
      duration: duration,
      onDismiss: onDismiss,
    );
  }

  static void showError(
    BuildContext context, {
    required String title,
    required String description,
    String? retryLabel,
    VoidCallback? onRetry,
    Duration duration = const Duration(seconds: 5),
    VoidCallback? onDismiss,
  }) {
    _showNotification(
      context,
      type: NotificationType.error,
      title: title,
      description: description,
      icon: Icons.error_outline,
      duration: duration,
      retryLabel: retryLabel,
      onRetry: onRetry,
      onDismiss: onDismiss,
    );
  }

  static void showWarning(
    BuildContext context, {
    required String title,
    required String description,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onDismiss,
  }) {
    _showNotification(
      context,
      type: NotificationType.warning,
      title: title,
      description: description,
      icon: Icons.warning_amber,
      duration: duration,
      onDismiss: onDismiss,
    );
  }

  static void showInfo(
    BuildContext context, {
    required String title,
    required String description,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onDismiss,
  }) {
    _showNotification(
      context,
      type: NotificationType.info,
      title: title,
      description: description,
      icon: Icons.info_outline,
      duration: duration,
      onDismiss: onDismiss,
    );
  }

  static void showFromException(
    BuildContext context, {
    required AppException exception,
    String? retryLabel,
    VoidCallback? onRetry,
  }) {
    final type = _getNotificationTypeFromException(exception);
    final icon = _getIconFromType(type);

    _showNotification(
      context,
      type: type,
      title: _getTitleFromException(exception),
      description: exception.message,
      icon: icon,
      duration: type == NotificationType.error
          ? const Duration(seconds: 5)
          : const Duration(seconds: 3),
      retryLabel: retryLabel,
      onRetry: onRetry,
    );
  }

  static void _showNotification(
    BuildContext context, {
    required NotificationType type,
    required String title,
    required String description,
    required IconData icon,
    required Duration duration,
    String? retryLabel,
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
  }) {
    if (_currentSnackBar != null) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }

    final backgroundColor = _getBackgroundColor(type);
    final iconColor = _getIconColor(type);

    final snackBar = SnackBar(
      duration: duration,
      backgroundColor: Colors.transparent,
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      content: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  onRetry();
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  retryLabel ?? 'Reintentar',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    _currentSnackBar = ScaffoldMessenger.of(context).showSnackBar(snackBar);
    _currentSnackBar!.closed.then((_) {
      _currentSnackBar = null;
      onDismiss?.call();
    });
  }

  static Color _getBackgroundColor(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return const Color(0xFF2E7D32);
      case NotificationType.error:
        return const Color(0xFFC62828);
      case NotificationType.warning:
        return const Color(0xFFEF6C00);
      case NotificationType.info:
        return const Color(0xFF1565C0);
    }
  }

  static Color _getIconColor(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return const Color(0xFF81C784);
      case NotificationType.error:
        return const Color(0xFFEF5350);
      case NotificationType.warning:
        return const Color(0xFFFFB74D);
      case NotificationType.info:
        return const Color(0xFF64B5F6);
    }
  }

  static NotificationType _getNotificationTypeFromException(
      AppException exception) {
    if (exception is PermissionException) {
      return NotificationType.warning;
    }
    if (exception is NetworkException) {
      return NotificationType.error;
    }
    if (exception is LocationException) {
      return NotificationType.warning;
    }
    return NotificationType.error;
  }

  static IconData _getIconFromType(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return Icons.check_circle;
      case NotificationType.error:
        return Icons.error_outline;
      case NotificationType.warning:
        return Icons.warning_amber;
      case NotificationType.info:
        return Icons.info_outline;
    }
  }

  static String _getTitleFromException(AppException exception) {
    if (exception is NodeNotFoundException) {
      return 'Nodo no encontrado';
    }
    if (exception is NoRouteFoundException) {
      return 'Sin ruta disponible';
    }
    if (exception is PermissionException) {
      return 'Permiso requerido';
    }
    if (exception is NetworkException) {
      return 'Error de conexión';
    }
    if (exception is LocationException) {
      return 'Error de ubicación';
    }
    if (exception is ServerException) {
      return 'Error del servidor';
    }
    if (exception is CacheException) {
      return 'Error de almacenamiento';
    }
    if (exception is ParseException) {
      return 'Error de formato';
    }
    return 'Error';
  }

  static void dismiss(BuildContext context) {
    if (_currentSnackBar != null) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _currentSnackBar = null;
    }
  }
}
