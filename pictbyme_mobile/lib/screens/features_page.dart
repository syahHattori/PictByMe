import 'package:flutter/material.dart';
import '../widgets/custom_navbar.dart';
class FeaturesPage extends StatelessWidget {
  const FeaturesPage({super.key});

  static const Color primaryBlue = Color(0xFF0077B6);
  static const Color accentBlue = Color(0xFF00B4D8);

  @override
  Widget build(BuildContext context) {
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

            // HERO
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 50,
                vertical: 80,
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

                  const Icon(
                    Icons.auto_awesome,
                    size: 80,
                    color: Colors.white,
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Powerful Features For Creators',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

                  const Text(
                    'Everything you need to upload, organize, and showcase your photography.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 60),

            // FEATURES GRID
            Wrap(
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

            const SizedBox(height: 80),

            // HOW IT WORKS
            const Text(
              'How It Works',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 40),

            Wrap(
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

            const SizedBox(height: 80),

            // CTA
            Container(
              margin: const EdgeInsets.all(50),
              padding: const EdgeInsets.all(50),
              decoration: BoxDecoration(
                color: primaryBlue,
                borderRadius:
                    BorderRadius.circular(25),
              ),
              child: Column(
                children: [

                  const Text(
                    'Ready To Start?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

                  const Text(
                    'Join thousands of creators sharing amazing photography.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                    ),
                  ),

                  const SizedBox(height: 25),

                  ElevatedButton.icon(
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
      width: 320,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [

          Icon(
            icon,
            size: 55,
            color: primaryBlue,
          ),

          const SizedBox(height: 15),

          Text(
            title,
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
      width: 280,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Column(
        children: [

          CircleAvatar(
            radius: 35,
            backgroundColor:
                primaryBlue.withAlpha(26),
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
            style: const TextStyle(
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}