import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = "release 1.0";

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() => _version = "${info.version}+${info.buildNumber}");
  }

  void _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "About",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black26,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 10),

          // ---------------------------------------------------
          // LOGO SECTION
          // ---------------------------------------------------
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.fitness_center,
                size: 80,
                color: theme.primaryColor,
              ),
            ),
          ),

          const SizedBox(height: 20),
          Center(
            child: Text(
              "Gym Management System",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),

          const SizedBox(height: 4),
          Center(
            child: Text(
              "Version $_version",
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),

          const SizedBox(height: 30),

          // ---------------------------------------------------
          // ABOUT DESCRIPTION
          // ---------------------------------------------------
          _sectionCard(
            title: "About This App",
            icon: Icons.info_outline,
            children: const [
              Text(
                "This gym management system helps streamline daily operations such as memberships, trainers, PT packages, class scheduling, "
                "inventory, payments, and attendance tracking. "
                "Designed for speed, simplicity, and efficiency — optimized for real-world gym operations.",
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ---------------------------------------------------
          // DEVELOPER INFO
          // ---------------------------------------------------
          _sectionCard(
            title: "Developer",
            icon: Icons.person_outline,
            children: [
              const Text(
                "Developed by:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                "Kurt Lynand Mier\nSoftware Developer",
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 10),

              // Email button
              _linkTile(
                icon: Icons.email_outlined,
                label: "Email Developer",
                onTap: () => _launchURL("mailto:kurtmier123@gmail.com"),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ---------------------------------------------------
          // SUPPORT
          // ---------------------------------------------------
          _sectionCard(
            title: "Support",
            icon: Icons.support_agent,
            children: [
              const Text(
                "Need help or found an issue?",
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 10),

              _linkTile(
                icon: Icons.bug_report_outlined,
                label: "Report a Bug",
                onTap: () => _launchURL("https://github.com/kurtcode19/Gym.git"),
              ),

              
            ],
          ),

          const SizedBox(height: 16),

          // ---------------------------------------------------
          // CREDITS
          // ---------------------------------------------------
          _sectionCard(
            title: "Credits",
            icon: Icons.copyright_outlined,
            children: const [
              Text("• Flutter Framework"),
              Text("• Provider State Management"),
              Text("• intl, uuid, table_calendar"),
              Text("• And all open-source contributors ❤️"),
            ],
          ),

          const SizedBox(height: 30),

          Center(
            child: Text(
              "Made with ❤️ using Flutter",
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // =====================================================================
  // REUSABLE SECTION CARD
  // =====================================================================
  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.black54),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  // =====================================================================
  // REUSABLE LINK TILE
  // =====================================================================
  Widget _linkTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.blue),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
            ),
            const Icon(Icons.chevron_right, size: 18, color: Colors.blue),
          ],
        ),
      ),
    );
  }
}
