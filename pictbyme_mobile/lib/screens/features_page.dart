import 'package:flutter/material.dart';
import '../widgets/custom_navbar.dart';

class FeaturesPage extends StatelessWidget {
  const FeaturesPage({super.key});

  static const Color primaryBlue = Color(0xFF0077B6);
  static const Color accentBlue = Color(0xFF00B4D8);

  @override
  Widget build(BuildContext context) {
    // Mendeteksi ukuran lebar layar device
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 800;

    // Mengatur padding & margin dinamis (50 di desktop, 20 di mobile)
    final double dynamicPadding = isMobile ? 20 : 50;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: const CustomNavbar(
          activePage: 'Features',
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [

            // HERO SECTION RESPONSIVE
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: dynamicPadding,
                vertical: isMobile ? 50 : 80,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryBlue,
                    accentBlue,
                  ],
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: isMobile ? 60 : 80, // Ikon mengecil di HP
                    color: Colors.white,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Powerful Features For Creators',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isMobile ? 28 : 42, // Font dinamis
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'Everything you need to upload, organize, and showcase your photography.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: isMobile ? 15 : 18,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 50),

            // FEATURES GRID RESPONSIVE
            Padding(
              padding: EdgeInsets.symmetric(horizontal: dynamicPadding),
              child: Wrap(
                spacing: 25,
                runSpacing: 25,
                alignment: WrapAlignment.center,
                children: [
                  featureCard(
                    Icons.cloud_upload,
                    'Photo Upload',
                    'Upload high-quality photos instantly.',
                  ),
                  featureCard(
                    Icons.collections_bookmark,
                    'Collections',
                    'Organize photos into beautiful collections.',
                  ),
                  featureCard(
                    Icons.people,
                    'Community',
                    'Connect with photographers worldwide.',
                  ),
                  featureCard(
                    Icons.favorite,
                    'Likes & Support',
                    'Engage with your audience easily.',
                  ),
                  featureCard(
                    Icons.security,
                    'Account Security',
                    'Keep your account safe and protected.',
                  ),
                  featureCard(
                    Icons.analytics,
                    'Analytics',
                    'Track engagement and growth.',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 60),

            // HOW IT WORKS SECTION
            Text(
              'How It Works',
              style: TextStyle(
                fontSize: isMobile ? 28 : 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 35),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: dynamicPadding),
              child: Wrap(
                spacing: 20,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: [
                  stepCard(
                    '01',
                    'Create Account',
                    Icons.person_add,
                  ),
                  stepCard(
                    '02',
                    'Upload Photos',
                    Icons.cloud_upload,
                  ),
                  stepCard(
                    '03',
                    'Share & Grow',
                    Icons.trending_up,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 60),

            // CTA (CALL TO ACTION) SECTION RESPONSIVE
            Container(
              margin: EdgeInsets.all(dynamicPadding), // Mengurangi margin luar di HP
              padding: EdgeInsets.all(isMobile ? 25 : 50), // Mengurangi padding dalam di HP
              decoration: BoxDecoration(
                color: primaryBlue,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Column(
                children: [
                  Text(
                    'Ready To Start?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isMobile ? 26 : 36, // Mengecilkan judul di HP
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'Join thousands of creators sharing amazing photography.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: isMobile ? 15 : 18,
                    ),
                  ),
                  const SizedBox(height: 25),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                    onPressed: () {},
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Get Started'),
                  ),
                ],
              ),
            ),

            // FOOTER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              color: Colors.white,
              child: const Center(
                child: Text(
                  '© 2026 PictByMe • Features Overview',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget featureCard(
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Container(
      // Mengubah width kaku menjadi constraint fleksibel
      constraints: const BoxConstraints(maxWidth: 320),
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 55,
            color: primaryBlue,
          ),
          const SizedBox(height: 15),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  static Widget stepCard(
    String number,
    String title,
    IconData icon,
  ) {
    return Container(
      // Mengubah width kaku menjadi constraint fleksibel
      constraints: const BoxConstraints(maxWidth: 280),
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: primaryBlue.withAlpha(26),
            child: Icon(
              icon,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            number,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}