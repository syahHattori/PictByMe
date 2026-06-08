import 'package:flutter/material.dart';
import '../widgets/login_dialog.dart';

import 'home_page.dart';
import 'explore_page.dart';
import 'features_page.dart';
import '../widgets/register_dialog.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  static const Color primaryBlue =
      Color(0xFF0077B6);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SingleChildScrollView(
        child: Column(
          children: [

            // NAVBAR
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 70,
                vertical: 18,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [

                  Row(
                    children: const [

                      Icon(
                        Icons.camera_alt_rounded,
                        color: primaryBlue,
                        size: 30,
                      ),

                      SizedBox(width: 10),

                      Text(
                        'PictByMe',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  Row(
                    children: [

                     TextButton.icon(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HomePage(),
      ),
    );
  },
  icon: const Icon(
    Icons.home_outlined,
    size: 18,
  ),
  label: const Text('Home'),
),

                     TextButton.icon(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ExplorePage(),
      ),
    );
  },
  icon: const Icon(
    Icons.explore_outlined,
    size: 18,
  ),
  label: const Text('Explore'),
),

                      TextButton.icon(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FeaturesPage(),
      ),
    );
  },
  icon: const Icon(
    Icons.auto_awesome_outlined,
    size: 18,
  ),
  label: const Text('Features'),
),

                      const SizedBox(width: 20),

                      OutlinedButton(
  onPressed: () {
    showDialog(
      context: context,
      builder: (_) => const LoginDialog(),
    );
  },
  child: const Text('Login'),
),

                      const SizedBox(width: 10),

                     ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: primaryBlue,
    foregroundColor: Colors.white,
    elevation: 0,
    padding: const EdgeInsets.symmetric(
      horizontal: 20,
      vertical: 12,
    ),
  ),
  onPressed: () {
    showDialog(
      context: context,
      builder: (_) => const RegisterDialog(),
    );
  },
  child: const Text(
    'Sign Up',
  ),
),
                    ],
                  ),
                ],
              ),
            ),

           // HERO SECTION
Container(
  width: double.infinity,
  padding: const EdgeInsets.symmetric(
    horizontal: 70,
    vertical: 80,
  ),
  child: Wrap(
    spacing: 60,
    runSpacing: 40,
    alignment: WrapAlignment.center,
    crossAxisAlignment:
        WrapCrossAlignment.center,
    children: [

      SizedBox(
        width: 450,
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [

            const Text(
              'Discover Beautiful Photography',
              style: TextStyle(
                fontSize: 52,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Share, save and inspire with millions of creators around the world.',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 30),

            Row(
              children: [

                ElevatedButton.icon(
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        primaryBlue,
                    foregroundColor:
                        Colors.white,
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 16,
                    ),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) =>
                          const LoginDialog(),
                    );
                  },
                  icon: const Icon(
                    Icons.arrow_forward,
                  ),
                  label: const Text(
                    'Get Started',
                  ),
                ),

                const SizedBox(width: 15),

                OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const FeaturesPage(),
                      ),
                    );
                  },
                  child: const Text(
                    'Learn More',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

      ClipRRect(
        borderRadius:
            BorderRadius.circular(24),
        child: Image.network(
          'https://picsum.photos/700/500',
          width: 520,
          height: 380,
          fit: BoxFit.cover,
        ),
      ),
    ],
  ),
),
            // FEATURES
            Container(
              width: double.infinity,
              color: const Color(
                0xFFF4FAFD,
              ),
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 70,
                vertical: 70,
              ),
              child: Column(
                children: [

                  const Text(
                    'Why Choose PictByMe?',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 50,
                  ),

                  Wrap(
                    spacing: 25,
                    runSpacing: 25,
                    alignment:
                        WrapAlignment.center,
                    children: [

                      featureCard(
                        Icons.camera_alt,
                        'Photography',
                        'Upload and share your best work.',
                      ),

                      featureCard(
                        Icons.bookmark,
                        'Collections',
                        'Save your favorite photos.',
                      ),

                      featureCard(
                        Icons.people,
                        'Community',
                        'Connect with creators worldwide.',
                      ),
                    ],
                  ),
                ],
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
      width: 280,
      padding: const EdgeInsets.all(
        25,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        children: [

          Icon(
            icon,
            size: 50,
            color: primaryBlue,
          ),

          const SizedBox(
            height: 15,
          ),

          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          Text(
            subtitle,
            textAlign:
                TextAlign.center,
          ),
        ],
      ),
    );
  }
}