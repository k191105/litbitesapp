import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'dev_panel.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  PackageInfo _packageInfo = PackageInfo(
    appName: '',
    packageName: '',
    version: '',
    buildNumber: '',
    buildSignature: '',
  );

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'About Literature Bites',
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontFamily: 'Georgia',
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
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
                color: Theme.of(context).primaryColor.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Literature is an expression of truth; it seeks to articulate that which we seek to understand. And yet, much of it can often feel abstruse and entirely unapproachable. For many of us without a degree in literature, a whole world of knowledge lies undiscovered. In a world that often values speed and efficiency over depth and complexity, it can be difficult to find the time and space to engage with literature in a meaningful way.",
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 16,
                height: 1.5,
                color: Theme.of(context).primaryColor.withOpacity(0.9),
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
                color: Theme.of(context).primaryColor,
              ),
            ),
            if (kDebugMode)
              ListTile(
                leading: const Icon(Icons.developer_mode),
                title: const Text('Developer Panel'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DevPanelPage(),
                    ),
                  );
                },
              ),
            const SizedBox(height: 24),
            Text(
              'Version: ${_packageInfo.version}+${_packageInfo.buildNumber}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
