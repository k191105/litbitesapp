import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  final bool isDarkMode;

  const AboutPage({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkMode
          ? Colors.black
          : const Color.fromARGB(255, 240, 234, 225),
      appBar: AppBar(
        title: Text(
          'About Literature Bites',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontFamily: 'Georgia',
          ),
        ),
        backgroundColor: isDarkMode
            ? Colors.black
            : const Color.fromARGB(255, 240, 234, 225),
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "The act of reading is unreasonably profound. When we read, all we're doing is sitting still and moving our eyes around  - and yet, somehow, we can almost also feel our minds expanding. Reading is about more than information-gathering; it is about developing wisdom. \"When we read\", writes Mortimer Adler, \"we become enlightened\".",
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 16,
                height: 1.5,
                color: isDarkMode
                    ? Colors.white.withOpacity(0.9)
                    : Colors.black.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Literature is an expression of truth; it seeks to articulate that which we seek to understand. And yet, much of it can often feel abstruse and entirely unapproachable. For many of us without a degree in literature, a whole world of knowledge lies undiscovered. In a world that often values speed and efficiency over depth and complexity, it can be difficult to find the time and space to engage with literature in a meaningful way.",
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 16,
                height: 1.5,
                color: isDarkMode
                    ? Colors.white.withOpacity(0.9)
                    : Colors.black.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "And it is for this reason that Literature Bites exists.",
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                height: 1.5,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
