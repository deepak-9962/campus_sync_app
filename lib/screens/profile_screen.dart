ElevatedButton(
  onPressed: () async {
    // First, sign out the user from authentication service
    await _authService.signOut(); // Assuming you have an auth service
    
    // Navigate to login screen and remove all previous routes
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/login', // Your login route name
      (route) => false, // This removes all previous routes
    );
  },
  child: Text('Logout'),
),