// ... existing code ...

ListTile(
  leading: Icon(Icons.logout),
  title: Text('Logout'),
  onTap: () async {
    // Close the drawer first
    Navigator.pop(context);
    
    // Sign out the user
    await _authService.signOut(); // Assuming you have an auth service
    
    // Navigate to login screen and clear navigation stack
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/login', // Your login route name
      (route) => false,
    );
  },
),

// ... existing code ...