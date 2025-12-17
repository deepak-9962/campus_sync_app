import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../services/app_update_service.dart';

class AboutUsScreen extends StatefulWidget {
  const AboutUsScreen({super.key});

  @override
  State<AboutUsScreen> createState() => _AboutUsScreenState();
}

class _AboutUsScreenState extends State<AboutUsScreen> {
  // Update service
  final AppUpdateService _updateService = AppUpdateService();

  // Consistent theme colors from HomeScreen
  static const Color primaryLightBackground = Color(0xFFF5F5F5);
  static const Color cardLightBackground = Colors.white;
  static const Color primaryTextLight = Color(0xFF212121);
  static const Color accentColorLight = Color(0xFF1976D2);

  bool _showDeveloperName = false;

  // Update related state
  String _currentVersion = '';
  bool _isCheckingUpdate = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  Map<String, dynamic>? _updateInfo;
  String? _errorMessage;
  CancelToken? _cancelToken;
  bool _downloadCompleted = false; // Track if download is complete
  String? _downloadedApkPath; // Store downloaded APK path

  @override
  void initState() {
    super.initState();
    _loadCurrentVersion();
  }

  Future<void> _loadCurrentVersion() async {
    final version = await _updateService.getCurrentVersion();
    if (mounted) {
      setState(() {
        _currentVersion = version;
      });
    }
  }

  Future<void> _checkForUpdate() async {
    setState(() {
      _isCheckingUpdate = true;
      _errorMessage = null;
      _updateInfo = null;
    });

    final result = await _updateService.checkForUpdate();

    if (mounted) {
      setState(() {
        _isCheckingUpdate = false;
        if (result['success'] == true) {
          _updateInfo = result;
          if (result['hasUpdate'] == false) {
            _showSnackBar('You\'re on the latest version!', isSuccess: true);
          }
        } else {
          _errorMessage = result['error'] ?? 'Unknown error occurred';
          _showSnackBar(_errorMessage!, isError: true);
        }
      });
    }
  }

  Future<void> _downloadAndInstall() async {
    if (_updateInfo == null || _updateInfo!['downloadUrl'] == null) {
      _showSnackBar('No download URL available', isError: true);
      return;
    }

    // Check if it's Android
    if (!Platform.isAndroid) {
      _showSnackBar('Updates are only available on Android', isError: true);
      return;
    }

    // Check install permission
    final canInstall = await _updateService.canInstallApk();
    if (!canInstall) {
      final shouldOpenSettings =
          await AppUpdateService.showPermissionDialog(context);
      if (shouldOpenSettings) {
        await _updateService.openInstallSettings();
      }
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _cancelToken = CancelToken();
    });

    final apkPath = await _updateService.downloadApk(
      _updateInfo!['downloadUrl'],
      onProgress: (progress) {
        if (mounted) {
          setState(() {
            _downloadProgress = progress;
          });
        }
      },
      fileName: _updateInfo!['apkFileName'], // Use the actual filename from GitHub
      cancelToken: _cancelToken,
    );

    if (mounted) {
      setState(() {
        _isDownloading = false;
      });

      if (apkPath != null) {
        // Mark download as completed
        setState(() {
          _downloadCompleted = true;
          _downloadedApkPath = apkPath;
        });
        // Try to install
        final installed = await _updateService.installApk(apkPath);
        if (!installed) {
          _showSnackBar(
            'Could not open installer. Please install manually from Downloads.',
            isError: true,
          );
        }
      } else if (!(_cancelToken?.isCancelled ?? false)) {
        _showSnackBar('Download failed. Please try again.', isError: true);
      }
    }
  }

  Future<void> _installDownloadedApk() async {
    if (_downloadedApkPath != null) {
      final installed = await _updateService.installApk(_downloadedApkPath!);
      if (!installed) {
        _showSnackBar(
          'Could not open installer. Please install manually from Downloads.',
          isError: true,
        );
      }
    }
  }

  void _cancelDownload() {
    _cancelToken?.cancel();
    setState(() {
      _isDownloading = false;
      _downloadProgress = 0.0;
    });
    _showSnackBar('Download cancelled');
  }

  void _showSnackBar(String message, {bool isError = false, bool isSuccess = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Colors.red[700]
            : isSuccess
                ? Colors.green[700]
                : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    // Video player controller disposal removed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryLightBackground,
      appBar: AppBar(
        title: const Text(
          'About Us',
          style: TextStyle(
            color: primaryTextLight,
            
          ),
        ),
        backgroundColor: cardLightBackground,
        iconTheme: const IconThemeData(color: primaryTextLight),
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              // Replaced Card with Container
              width: double.infinity, // Make container fill horizontal space
              padding: const EdgeInsets.all(16.0), // Inner padding for content
              decoration: BoxDecoration(
                color: cardLightBackground,
                borderRadius: BorderRadius.circular(12),
                // We can add a subtle shadow if needed, similar to elevation:
                // boxShadow: [
                //   BoxShadow(
                //     color: Colors.grey.withOpacity(0.1),
                //     spreadRadius: 1,
                //     blurRadius: 3,
                //     offset: Offset(0, 1),
                //   ),
                // ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Campus Sync',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: accentColorLight,
                      
                    ),
                  ),
                  // const SizedBox(height: 16), // Space for video removed
                  // Video Player Widget removed
                  // const SizedBox(height: 16), // Space after video removed
                  // const SizedBox(height: 12), // Removed Version
                  // Text( // Removed Version
                  //   'Version: 1.0.0 (Placeholder)', // Removed Version
                  //   style: TextStyle( // Removed Version
                  //     fontSize: 16, // Removed Version
                  //     color: primaryTextLight.withOpacity(0.8), // Removed Version
                  //      // Removed Version
                  //   ), // Removed Version
                  // ), // Removed Version
                  const SizedBox(
                    height: 20,
                  ), // Keep this space or adjust as needed
                  // Text( // Removed Our Mission
                  //   'Our Mission:', // Removed Our Mission
                  //   style: TextStyle( // Removed Our Mission
                  //     fontSize: 18, // Removed Our Mission
                  //     fontWeight: FontWeight.w600, // Removed Our Mission
                  //     color: primaryTextLight, // Removed Our Mission
                  //      // Removed Our Mission
                  //   ), // Removed Our Mission
                  // ), // Removed Our Mission
                  // const SizedBox(height: 8), // Removed Our Mission
                  // Text( // Removed Our Mission
                  //   'To provide a seamless and integrated digital experience for students and faculty, enhancing campus life and academic management. (This is placeholder text - please replace with your actual mission statement).', // Removed Our Mission
                  //   style: TextStyle( // Removed Our Mission
                  //     fontSize: 15, // Removed Our Mission
                  //     color: primaryTextLight.withOpacity(0.7), // Removed Our Mission
                  //      // Removed Our Mission
                  //     height: 1.4, // Removed Our Mission
                  //   ), // Removed Our Mission
                  // ), // Removed Our Mission
                  // const SizedBox(height: 20), // Removed Our Mission
                  // Text( // Removed "Developed By:" heading
                  //   'Developed By:', // Removed "Developed By:" heading
                  //   style: TextStyle( // Removed "Developed By:" heading
                  //     fontSize: 18, // Removed "Developed By:" heading
                  //     fontWeight: FontWeight.w600, // Removed "Developed By:" heading
                  //     color: primaryTextLight, // Removed "Developed By:" heading
                  //      // Removed "Developed By:" heading
                  //   ), // Removed "Developed By:" heading
                  // ), // Removed "Developed By:" heading
                  // const SizedBox(height: 8), // Removed SizedBox before InkWell
                  InkWell(
                    onTap: () {
                      setState(() {
                        _showDeveloperName = !_showDeveloperName;
                      });
                    },
                    child: Text(
                      _showDeveloperName
                          ? 'A sleep-deprived student named Deepak.S'
                          : 'Who built this?',
                      style: TextStyle(
                        fontSize: 15,
                        color:
                            _showDeveloperName
                                ? primaryTextLight.withOpacity(0.9)
                                : accentColorLight,
                        
                        fontStyle:
                            _showDeveloperName
                                ? FontStyle.normal
                                : FontStyle.italic,
                        decoration:
                            _showDeveloperName
                                ? TextDecoration.none
                                : TextDecoration.underline,
                        decorationColor: accentColorLight,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ), // Added some padding at the bottom
                ],
              ),
            ),
            const SizedBox(height: 16),
            // App Update Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: cardLightBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.system_update,
                        color: accentColorLight,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'App Updates',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryTextLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Current version
                  Row(
                    children: [
                      Text(
                        'Current Version: ',
                        style: TextStyle(
                          fontSize: 15,
                          color: primaryTextLight.withOpacity(0.7),
                        ),
                      ),
                      Text(
                        _currentVersion.isEmpty ? 'Loading...' : 'v$_currentVersion',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: primaryTextLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Download completed - show ready to install message
                  if (_downloadCompleted) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.orange[700], size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Update Downloaded!',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap "Install Update" to complete the installation. The app will close during installation.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.orange[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ]
                  // Update info if available
                  else if (_updateInfo != null && _updateInfo!['hasUpdate'] == true) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.new_releases, color: Colors.green[700], size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'New Update Available!',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Version ${_updateInfo!['latestVersion']}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.green[800],
                            ),
                          ),
                          if (_updateInfo!['releaseNotes'] != null &&
                              _updateInfo!['releaseNotes'].toString().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              _updateInfo!['releaseNotes'],
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.green[700],
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Download progress
                  if (_isDownloading) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Downloading update...',
                              style: TextStyle(
                                fontSize: 14,
                                color: primaryTextLight.withOpacity(0.7),
                              ),
                            ),
                            Text(
                              '${(_downloadProgress * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: accentColorLight,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _downloadProgress,
                            minHeight: 8,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(accentColorLight),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _cancelDownload,
                            icon: const Icon(Icons.cancel, size: 18),
                            label: const Text('Cancel Download'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red[700],
                              side: BorderSide(color: Colors.red[300]!),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // Check for updates / Download button
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isCheckingUpdate ? null : _checkForUpdate,
                            icon: _isCheckingUpdate
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.refresh, size: 18),
                            label: Text(
                              _isCheckingUpdate ? 'Checking...' : 'Check for Updates',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColorLight,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        if (_downloadCompleted && _downloadedApkPath != null) ...[
                          // Download completed - show Install button
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _installDownloadedApk,
                              icon: const Icon(Icons.install_mobile, size: 18),
                              label: const Text('Install Update'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange[600],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ] else if (_updateInfo != null &&
                            _updateInfo!['hasUpdate'] == true &&
                            _updateInfo!['downloadUrl'] != null) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _downloadAndInstall,
                              icon: const Icon(Icons.download, size: 18),
                              label: const Text('Download Update'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[600],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                  // Platform notice for non-Android
                  if (!Platform.isAndroid) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange[700], size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'In-app updates are only available on Android.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.orange[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
