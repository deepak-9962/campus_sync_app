import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for checking and downloading app updates from GitHub Releases
class AppUpdateService {
  static const String _githubOwner = 'deepak-9962';
  static const String _githubRepo = 'campus_sync_app';
  static const String _githubApiUrl =
      'https://api.github.com/repos/$_githubOwner/$_githubRepo/releases/latest';

  final Dio _dio = Dio();

  /// Get the current app version
  Future<String> getCurrentVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (e) {
      debugPrint('Error getting current version: $e');
      return '0.0.0';
    }
  }

  /// Check for updates from GitHub Releases
  /// Returns a map with 'hasUpdate', 'latestVersion', 'downloadUrl', 'releaseNotes'
  Future<Map<String, dynamic>> checkForUpdate() async {
    try {
      final currentVersion = await getCurrentVersion();

      final response = await _dio.get(
        _githubApiUrl,
        options: Options(
          headers: {
            'Accept': 'application/vnd.github.v3+json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        String tagName = data['tag_name'] ?? '';

        // Remove 'v' prefix if present (e.g., 'v1.0.1' -> '1.0.1')
        if (tagName.startsWith('v') || tagName.startsWith('V')) {
          tagName = tagName.substring(1);
        }

        // Find APK asset in release
        String? apkUrl;
        String? apkFileName;
        final assets = data['assets'] as List<dynamic>? ?? [];
        for (final asset in assets) {
          final name = asset['name']?.toString() ?? '';
          if (name.toLowerCase().endsWith('.apk')) {
            apkUrl = asset['browser_download_url'];
            apkFileName = name; // Store the actual filename from GitHub
            break;
          }
        }

        final hasUpdate = _isNewerVersion(tagName, currentVersion);

        return {
          'success': true,
          'hasUpdate': hasUpdate,
          'currentVersion': currentVersion,
          'latestVersion': tagName,
          'downloadUrl': apkUrl,
          'apkFileName': apkFileName, // Include the filename
          'releaseNotes': data['body'] ?? 'No release notes available.',
          'releaseName': data['name'] ?? 'New Update',
          'error': null,
        };
      } else {
        return {
          'success': false,
          'hasUpdate': false,
          'error': 'Failed to check for updates: ${response.statusCode}',
        };
      }
    } on DioException catch (e) {
      debugPrint('DioException checking for update: $e');
      String errorMessage = 'Network error while checking for updates.';
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Connection timed out. Please check your internet.';
      } else if (e.response?.statusCode == 404) {
        errorMessage = 'No releases found. The app is up to date.';
        return {
          'success': true,
          'hasUpdate': false,
          'error': null,
        };
      }
      return {
        'success': false,
        'hasUpdate': false,
        'error': errorMessage,
      };
    } catch (e) {
      debugPrint('Error checking for update: $e');
      return {
        'success': false,
        'hasUpdate': false,
        'error': 'Error checking for updates: $e',
      };
    }
  }

  /// Compare version strings to determine if latestVersion is newer
  /// Supports versions like '1.0.0', '1.0.1', '2.0.0'
  bool _isNewerVersion(String latestVersion, String currentVersion) {
    try {
      final latest = latestVersion.split('.').map(int.parse).toList();
      final current = currentVersion.split('.').map(int.parse).toList();

      // Pad shorter version with zeros
      while (latest.length < 3) latest.add(0);
      while (current.length < 3) current.add(0);

      for (int i = 0; i < 3; i++) {
        if (latest[i] > current[i]) return true;
        if (latest[i] < current[i]) return false;
      }
      return false; // versions are equal
    } catch (e) {
      debugPrint('Error comparing versions: $e');
      return false;
    }
  }

  /// Download APK from URL with progress callback
  /// Returns the local file path on success, null on failure
  Future<String?> downloadApk(
    String url, {
    required Function(double progress) onProgress,
    String? fileName,
    CancelToken? cancelToken,
  }) async {
    try {
      // Get external files directory for download
      final dir = await getExternalStorageDirectory();
      if (dir == null) {
        debugPrint('Could not get external storage directory');
        return null;
      }

      // Use provided filename or extract from URL, fallback to default
      final apkFileName = fileName ?? 
          Uri.parse(url).pathSegments.lastOrNull ?? 
          'campus_sync_update.apk';
      final filePath = '${dir.path}/$apkFileName';

      // Delete existing APK if present
      final existingFile = File(filePath);
      if (await existingFile.exists()) {
        await existingFile.delete();
      }

      // Download with progress
      await _dio.download(
        url,
        filePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            onProgress(progress);
          }
        },
        options: Options(
          headers: {
            'Accept': 'application/octet-stream',
          },
        ),
      );

      // Verify file exists
      final downloadedFile = File(filePath);
      if (await downloadedFile.exists()) {
        debugPrint('APK downloaded successfully to: $filePath');
        return filePath;
      } else {
        debugPrint('APK file not found after download');
        return null;
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        debugPrint('Download cancelled by user');
      } else {
        debugPrint('DioException downloading APK: $e');
      }
      return null;
    } catch (e) {
      debugPrint('Error downloading APK: $e');
      return null;
    }
  }

  /// Check if the app has permission to install unknown apps
  Future<bool> canInstallApk() async {
    if (!Platform.isAndroid) return false;

    final status = await Permission.requestInstallPackages.status;
    return status.isGranted;
  }

  /// Request permission to install unknown apps
  /// Returns true if permission is granted
  Future<bool> requestInstallPermission() async {
    if (!Platform.isAndroid) return false;

    final status = await Permission.requestInstallPackages.request();
    return status.isGranted;
  }

  /// Open app settings to enable install from unknown sources
  Future<void> openInstallSettings() async {
    await openAppSettings();
  }

  /// Install the downloaded APK
  /// Returns true on success, false on failure
  Future<bool> installApk(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('APK file does not exist: $filePath');
        return false;
      }

      final result = await OpenFilex.open(filePath);
      debugPrint('OpenFilex result: ${result.type} - ${result.message}');

      return result.type == ResultType.done;
    } catch (e) {
      debugPrint('Error installing APK: $e');
      return false;
    }
  }

  /// Show permission guidance dialog
  static Future<bool> showPermissionDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.security, color: Colors.orange),
                SizedBox(width: 8),
                Text('Permission Required'),
              ],
            ),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'To install updates, you need to allow installing apps from this source.',
                  style: TextStyle(fontSize: 15),
                ),
                SizedBox(height: 16),
                Text(
                  'Steps:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('1. Tap "Open Settings" below'),
                Text('2. Find "Install unknown apps"'),
                Text('3. Enable the toggle'),
                Text('4. Come back and try again'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Open Settings'),
              ),
            ],
          ),
        ) ??
        false;
  }
}
