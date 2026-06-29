import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/login_dialog.dart';
import '../widgets/register_dialog.dart';
import 'home_page.dart';
import 'explore_page.dart';
import 'features_page.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  static const Color primaryBlue = Color(0xFF0077B6);

  // URL APK yang sudah diupload di server (lihat public/download/PictByMe-App.apk).
  static const String _apkUrl =
      'https://api.pictbyme.web.id/download/PictByMe-App.apk';

  Future<void> _downloadApk() async {
    final uri = Uri.parse(_apkUrl);
    // externalApplication agar di web membuka tab baru / langsung memicu download,
    // mirip perilaku target="_blank" pada tag <a>.
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    // Menentukan apakah device saat ini berukuran mobile/tablet kecil
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 800;

    // Mengatur padding horizontal secara dinamis (70 di Desktop, 20 di HP)
    final double dynamicPadding = isMobile ? 20 : 70;

    return Scaffold(
      backgroundColor: Colors.white,
      
      // DRAWER: Otomatis aktif di mobile saat menekan tombol menu hamburger di navbar
      drawer: isMobile
          ? Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    decoration: const BoxDecoration(color: primaryBlue),
                    child: Row(
                      children: const [
                        Icon(Icons.camera_alt_rounded, color: Colors.white, size: 28),
                        SizedBox(width: 10),
                        Text(
                          'PictByMe',
                          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.home_outlined),
                    title: const Text('Home'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const HomePage()));
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.explore_outlined),
                    title: const Text('Explore'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ExplorePage()));
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.auto_awesome_outlined),
                    title: const Text('Features'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const FeaturesPage()));
                    },
                  ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 45)),
                      onPressed: () {
                        Navigator.pop(context);
                        showDialog(context: context, builder: (_) => const LoginDialog());
                      },
                      child: const Text('Login'),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 45),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        showDialog(context: context, builder: (_) => const RegisterDialog());
                      },
                      child: const Text('Sign Up'),
                    ),
                  ),
                ],
              ),
            )
          : null,

      body: SingleChildScrollView(
        child: Column(
          children: [
            
            // NAVBAR RESPONSIVE
            Builder(
              builder: (scaffoldContext) => Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: dynamicPadding,
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // LOGO BRAND
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
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    // KONDISI NAVIGASI: Tampilkan menu penuh jika Desktop, tampilkan ikon hamburger jika HP
                    if (isMobile)
                      IconButton(
                        icon: const Icon(Icons.menu, size: 28, color: primaryBlue),
                        onPressed: () {
                          Scaffold.of(scaffoldContext).openDrawer();
                        },
                      )
                    else
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const HomePage()));
                            },
                            icon: const Icon(Icons.home_outlined, size: 18),
                            label: const Text('Home'),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const ExplorePage()));
                            },
                            icon: const Icon(Icons.explore_outlined, size: 18),
                            label: const Text('Explore'),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const FeaturesPage()));
                            },
                            icon: const Icon(Icons.auto_awesome_outlined, size: 18),
                            label: const Text('Features'),
                          ),
                          const SizedBox(width: 20),
                          OutlinedButton(
                            onPressed: () {
                              showDialog(context: context, builder: (_) => const LoginDialog());
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
                              showDialog(context: context, builder: (_) => const RegisterDialog());
                            },
                            child: const Text('Sign Up'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),

            // HERO SECTION RESPONSIVE
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: dynamicPadding,
                vertical: isMobile ? 40 : 80,
              ),
              child: Wrap(
                spacing: 60,
                runSpacing: 40,
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  
                  // BLOK TEKS HERO (Ganti ukuran kaku dari SizedBox ke BoxConstraints)
                  Container(
                    constraints: const BoxConstraints(maxWidth: 450),
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Discover Beautiful Photography oke ',
                          textAlign: isMobile ? TextAlign.center : TextAlign.start,
                          style: TextStyle(
                            fontSize: isMobile ? 34 : 52, // Font mengecil jika di HP
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Share, save and inspire with millions of creators around the world.',
                          textAlign: isMobile ? TextAlign.center : TextAlign.start,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 30),
                        
                        // TOMBOL HERO ACTIONS
                        Wrap(
                          spacing: 15,
                          runSpacing: 12,
                          alignment: isMobile ? WrapAlignment.center : WrapAlignment.start,
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 22,
                                  vertical: 16,
                                ),
                              ),
                              onPressed: () {
                                showDialog(context: context, builder: (_) => const LoginDialog());
                              },
                              icon: const Icon(Icons.arrow_forward),
                              label: const Text('Get Started'),
                            ),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 22,
                                  vertical: 16,
                                ),
                              ),
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const FeaturesPage()));
                              },
                              child: const Text('Learn More'),
                            ),
                            // TOMBOL DOWNLOAD ANDROID
                            // Hanya tampil di Flutter Web (kIsWeb). Di Android/iOS/desktop
                            // tombol ini disembunyikan total, karena aplikasi sudah
                            // berjalan native di platform tersebut.
                            // Wrap akan otomatis menurunkan tombol ini ke baris baru di layar
                            // sempit (mobile web), tepat di bawah Get Started & Learn More.
                            if (kIsWeb)
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryBlue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 28,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: _downloadApk,
                                icon: const Icon(Icons.android),
                                label: const Text('Download Android'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // GAMBAR HERO (Lebar dinamis mengikuti layar agar tidak overflow)
                  Container(
                    constraints: const BoxConstraints(maxWidth: 520, maxHeight: 380),
                    width: isMobile ? screenWidth - (dynamicPadding * 2) : 520,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.network(
                        'https://picsum.photos/700/500',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // FEATURES SECTION RESPONSIVE
            Container(
              width: double.infinity,
              color: const Color(0xFFF4FAFD),
              padding: EdgeInsets.symmetric(
                horizontal: dynamicPadding,
                vertical: 70,
              ),
              child: Column(
                children: [
                  Text(
                    'Why Choose PictByMe?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isMobile ? 28 : 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 50),
                  Wrap(
                    spacing: 25,
                    runSpacing: 25,
                    alignment: WrapAlignment.center,
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
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          const SizedBox(height: 15),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
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
}