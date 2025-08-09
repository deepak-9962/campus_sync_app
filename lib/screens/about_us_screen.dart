import 'package:flutter/material.dart';
// import 'package:video_player/video_player.dart'; // Removed video_player import

class AboutUsScreen extends StatefulWidget {
  const AboutUsScreen({super.key});

  @override
  State<AboutUsScreen> createState() => _AboutUsScreenState();
}

class _AboutUsScreenState extends State<AboutUsScreen> {
  // late VideoPlayerController _controller; // Removed Controller for the video

  // Consistent theme colors from HomeScreen
  static const Color primaryLightBackground = Color(0xFFF5F5F5);
  static const Color cardLightBackground = Colors.white;
  static const Color primaryTextLight = Color(0xFF212121);
  static const Color accentColorLight = Color(0xFF1976D2);

  bool _showDeveloperName = false;

  @override
  void initState() {
    super.initState();
    // Video player initialization removed
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
                  // const SizedBox(height: 20), // Removed Icon
                  // Center( // Removed Icon
                  //   child: Icon( // Removed Icon
                  //     Icons.school_outlined, // Removed Icon
                  //     color: accentColorLight.withOpacity(0.5), // Removed Icon
                  //     size: 60, // Removed Icon
                  //   ), // Removed Icon
                  // ), // Removed Icon
                  const SizedBox(
                    height: 20,
                  ), // Added some padding at the bottom
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
