import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';

class UpdateService {
  // REPLACE WITH YOUR REPO DETAILS
  static const String _owner = "deepak-9962";
  static const String _repo = "campus_sync_app";
  
  Future<void> checkForUpdate(BuildContext context, {bool showNoUpdate = false}) async {
    try {
      // 1. Get current app version
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version;
      
      // 2. Get latest release from GitHub
      final dio = Dio();
      final response = await dio.get(
        'https://api.github.com/repos/$_owner/$_repo/releases/latest',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> releaseData = response.data;
        String latestTag = releaseData['tag_name']; // e.g., "v1.0.1"
        
        // Remove 'v' prefix if present for comparison
        String latestVersion = latestTag.startsWith('v') 
            ? latestTag.substring(1) 
            : latestTag;

        if (_isNewer(latestVersion, currentVersion)) {
          // Find the APK asset
          List assets = releaseData['assets'];
          String? apkUrl;
          for (var asset in assets) {
            if (asset['name'].toString().endsWith('.apk')) {
              apkUrl = asset['browser_download_url'];
              break;
            }
          }

          if (apkUrl != null) {
            _showUpdateDialog(context, latestTag, releaseData['body'] ?? '', apkUrl);
          } else {
            debugPrint("Update available but no APK found in release assets.");
          }
        } else {
          if (showNoUpdate) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("App is up to date!")),
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Error checking for updates: $e");
      if (showNoUpdate) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to check for updates: $e")),
        );
      }
    }
  }

  bool _isNewer(String latest, String current) {
    List<int> l = latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    List<int> c = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    for (int i = 0; i < 3; i++) {
      int lNum = i < l.length ? l[i] : 0;
      int cNum = i < c.length ? c[i] : 0;
      if (lNum > cNum) return true;
      if (lNum < cNum) return false;
    }
    return false;
  }

  Future<void> _showUpdateDialog(BuildContext context, String version, String notes, String url) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("Update Available: $version"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("A new version is available. Please update to continue."),
              const SizedBox(height: 10),
              const Text("Release Notes:", style: TextStyle(fontWeight: FontWeight.bold)),
              Text(notes),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Later"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _downloadAndInstall(context, url);
            },
            child: const Text("Update Now"),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadAndInstall(BuildContext context, String url) async {
    // Request storage permissions if needed (Android 12+ handles this differently, but good to have)
    // For installing packages, we need REQUEST_INSTALL_PACKAGES which is in manifest
    
    // Show downloading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text("Downloading update..."),
          ],
        ),
      ),
    );

    try {
      Directory? tempDir = await getExternalStorageDirectory(); 
      // Fallback to temporary directory if external is null
      tempDir ??= await getTemporaryDirectory();
      
      String savePath = "${tempDir.path}/app-release.apk";

      await Dio().download(
        url, 
        savePath,
        onReceiveProgress: (received, total) {
          // You could update a progress bar here
        },
      );

      // Close loading dialog
      if (context.mounted) Navigator.pop(context);

      // Open the file to trigger installation
      final result = await OpenFilex.open(savePath);
      if (result.type != ResultType.done) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Could not open APK: ${result.message}")),
          );
        }
      }

    } catch (e) {
      if (context.mounted) Navigator.pop(context); // Close loading
      debugPrint("Update error: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Update failed: $e")),
        );
      }
    }
  }
}
