import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class MediaPickerService {
  static final ImagePicker _picker = ImagePicker();

  /// Requests runtime permission for Gallery or Camera on physical mobile devices.
  /// Shows a direct configuration dialog if permission was permanently denied.
  static Future<bool> requestMediaPermission({
    required ImageSource source,
    BuildContext? context,
  }) async {
    // If not mobile platform, allow directly
    if (!Platform.isAndroid && !Platform.isIOS) {
      return true;
    }

    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (status.isGranted) {
        return true;
      }
      if (status.isPermanentlyDenied && context != null && context.mounted) {
        _showPermissionSettingsDialog(
          context,
          title: 'Camera Permission Required',
          message: 'Connectzy requires camera access to capture site progress photos, KYC documents, and profile pictures. Please grant permission in App Settings.',
        );
      }
      return false;
    } else {
      // ImageSource.gallery
      if (Platform.isAndroid) {
        try {
          final androidInfo = await DeviceInfoPlugin().androidInfo;
          if (androidInfo.version.sdkInt >= 33) {
            // Android 13+ (API 33+) requires READ_MEDIA_IMAGES
            final status = await Permission.photos.request();
            if (status.isGranted || status.isLimited) {
              return true;
            }
            if (status.isPermanentlyDenied && context != null && context.mounted) {
              _showPermissionSettingsDialog(
                context,
                title: 'Gallery Access Required',
                message: 'Connectzy requires access to your photo gallery to upload blueprints, portfolio works, and profile photos. Please grant Photos permission in App Settings.',
              );
              return false;
            }
            // Even if denied on Android 13+, system photo picker can still be invoked
            return true;
          } else {
            // Android 12 and below (API <= 32) requires READ_EXTERNAL_STORAGE
            final status = await Permission.storage.request();
            if (status.isGranted) {
              return true;
            }
            if (status.isPermanentlyDenied && context != null && context.mounted) {
              _showPermissionSettingsDialog(
                context,
                title: 'Storage Permission Required',
                message: 'Connectzy requires storage access to choose photos from your gallery. Please grant Storage permission in App Settings.',
              );
            }
            return false;
          }
        } catch (e) {
          debugPrint('Error checking Android gallery permission: $e');
          return true; // Fallback to let system attempt image picker
        }
      } else if (Platform.isIOS) {
        final status = await Permission.photos.request();
        if (status.isGranted || status.isLimited) {
          return true;
        }
        if (status.isPermanentlyDenied && context != null && context.mounted) {
          _showPermissionSettingsDialog(
            context,
            title: 'Photo Library Permission Required',
            message: 'Connectzy requires access to your photo library to select photos. Please enable Photos access in Settings.',
          );
        }
        return false;
      }
      return true;
    }
  }

  /// Picks an image after verifying and requesting physical device permissions.
  static Future<XFile?> pickImage({
    required ImageSource source,
    BuildContext? context,
    double? maxWidth = 1000,
    double? maxHeight = 1000,
    int? imageQuality = 75,
  }) async {
    final hasPermission = await requestMediaPermission(source: source, context: context);
    if (!hasPermission) {
      return null;
    }

    try {
      return await _picker.pickImage(
        source: source,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      );
    } catch (e) {
      debugPrint('MediaPickerService error picking image: $e');
      return null;
    }
  }

  static void _showPermissionSettingsDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.photo_library_rounded, color: Color(0xFF0F766E)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F766E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
