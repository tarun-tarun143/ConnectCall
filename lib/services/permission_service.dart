import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  PermissionService._();

  static Future<bool> notifications() async {
    final status = await Permission.notification.request();
    return status.isGranted || status.isLimited;
  }

  static Future<bool> ensureForCall({
    required BuildContext context,
    required bool video,
  }) async {
    final request = <Permission>[Permission.microphone];
    if (video) request.add(Permission.camera);

    final result = await request.request();
    final mic = result[Permission.microphone]?.isGranted ?? false;
    final camera = !video || (result[Permission.camera]?.isGranted ?? false);
    if (mic && camera) return true;
    if (!context.mounted) return false;

    final permanent = result.values.any((value) => value.isPermanentlyDenied);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Permission required'),
        content: Text(
          video
              ? 'ConnectCall needs microphone and camera access for video calls.'
              : 'ConnectCall needs microphone access for audio calls.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          if (permanent)
            FilledButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
        ],
      ),
    );
    return false;
  }
}
