import 'package:flutter/material.dart';
import '../services/update_service.dart';
import '../services/theme_service.dart';
import '../main.dart'; // For themeService

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  _ProfileSettingsScreenState createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  String userName = 'User Name'; // Initial user name
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = userName; // Pre-fill name field
    themeService.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _nameController.dispose(); // Dispose controller to free memory
    themeService.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  void _saveProfile() {
    setState(() {
      userName = _nameController.text;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Profile saved successfully!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<AppThemeMode>(
              title: const Text('Light'),
              secondary: const Icon(Icons.light_mode),
              value: AppThemeMode.light,
              groupValue: themeService.themeMode,
              onChanged: (value) {
                themeService.setThemeMode(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<AppThemeMode>(
              title: const Text('Dark'),
              secondary: const Icon(Icons.dark_mode),
              value: AppThemeMode.dark,
              groupValue: themeService.themeMode,
              onChanged: (value) {
                themeService.setThemeMode(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<AppThemeMode>(
              title: const Text('System Default'),
              secondary: const Icon(Icons.settings_brightness),
              value: AppThemeMode.system,
              groupValue: themeService.themeMode,
              onChanged: (value) {
                themeService.setThemeMode(value!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundImage: AssetImage(
                      'assets/profile_icon.png',
                    ), // Placeholder image
                  ),
                  const SizedBox(height: 8),
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Enter your name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _saveProfile, child: const Text('Save')),
            const SizedBox(height: 20),
            const Divider(),
            ListTile(
              leading: Icon(themeService.themeModeIcon),
              title: const Text("Theme"),
              subtitle: Text(themeService.themeModeDisplayName),
              trailing: const Icon(Icons.chevron_right),
              onTap: _showThemeDialog,
            ),
            ListTile(
              leading: const Icon(Icons.system_update),
              title: const Text("Check for Updates"),
              subtitle: const Text("Check if a new version is available"),
              onTap: () {
                UpdateService().checkForUpdate(context, showNoUpdate: true);
              },
            ),
          ],
        ),
      ),
    );
  }
}
