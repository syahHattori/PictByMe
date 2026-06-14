import 'package:flutter/material.dart';
import '../widgets/custom_navbar.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // Menentukan kecocokan ukuran layar device
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 800;

    // Menghitung padding adaptif (60 di desktop, 20 di mobile)
    final double dynamicPadding = isMobile ? 20 : 60;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: const CustomNavbar(
          activePage: 'Home',
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            
            // HERO SECTION RESPONSIVE
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(dynamicPadding),
              child: isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildHeroContent(context, isMobile, tt, cs),
                        const SizedBox(height: 40),
                        _buildHeroImage(isMobile),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: _buildHeroContent(context, isMobile, tt, cs),
                        ),
                        const SizedBox(width: 40),
                        Expanded(
                          child: _buildHeroImage(isMobile),
                        ),
                      ],
                    ),
            ),

            // STATS SECTION RESPONSIVE
            Container(
              width: double.infinity,
              color: cs.surfaceContainerHighest,
              padding: EdgeInsets.all(isMobile ? 30 : 50),
              child: Wrap(
                alignment: WrapAlignment.spaceEvenly,
                spacing: 20,
                runSpacing: 20,
                children: [
                  statCard(context, Icons.photo, '25K+', 'Photos'),
                  statCard(context, Icons.people, '10K+', 'Creators'),
                  statCard(context, Icons.favorite, '50K+', 'Likes'),
                  statCard(context, Icons.bookmark, '5K+', 'Collections'),
                ],
              ),
            ),

            // CATEGORIES SECTION RESPONSIVE
            Padding(
              padding: EdgeInsets.all(dynamicPadding),
              child: Column(
                children: [
                  Text(
                    'Photography Categories',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isMobile ? 28 : 38,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    alignment: WrapAlignment.center,
                    children: [
                      statCard(context, Icons.landscape, 'Nature', ''),
                      statCard(context, Icons.flight, 'Travel', ''),
                      statCard(context, Icons.restaurant, 'Food', ''),
                      statCard(context, Icons.location_city, 'Street', ''),
                    ],
                  ),
                ],
              ),
            ),

            // FEATURED CREATORS SECTION RESPONSIVE
            Padding(
              padding: EdgeInsets.all(dynamicPadding),
              child: Column(
                children: [
                  Text(
                    'Featured Creators',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isMobile ? 28 : 38,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    alignment: WrapAlignment.center,
                    children: [
                      creatorCard(context, 'Sarah', 'Landscape Photographer'),
                      creatorCard(context, 'John', 'Travel Photographer'),
                      creatorCard(context, 'Emma', 'Street Photographer'),
                    ],
                  ),
                ],
              ),
            ),

            // TRENDING SECTION RESPONSIVE
            Padding(
              padding: EdgeInsets.all(dynamicPadding),
              child: Column(
                children: [
                  Text(
                    'Trending Photos',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isMobile ? 28 : 38,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    alignment: WrapAlignment.center,
                    children: List.generate(
                      4,
                      (index) => Container(
                        constraints: const BoxConstraints(maxWidth: 280),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                            'https://picsum.photos/400?random=$index',
                            width: double.infinity,
                            height: 280,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // JOIN COMMUNITY RESPONSIVE
            Container(
              width: double.infinity,
              margin: EdgeInsets.all(dynamicPadding),
              padding: EdgeInsets.all(isMobile ? 25 : 50),
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Column(
                children: [
                  Text(
                    'Join Our Photography Community',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: cs.onPrimary,
                      fontSize: isMobile ? 24 : 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'Connect with thousands of photographers and share your creativity.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: cs.onPrimary.withAlpha((0.9 * 255).round()),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 25),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                    onPressed: () {},
                    icon: Icon(Icons.person_add, color: cs.primary),
                    label: Text(
                      'Join Now',
                      style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            // FOOTER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              color: cs.surfaceContainerHighest,
              child: Center(
                child: Text(
                  '© 2026 PictByMe • Photography Platform',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: tt.bodySmall?.color,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Widget: Konten Teks Hero + Search Bar + Button Actions
  Widget _buildHeroContent(BuildContext context, bool isMobile, TextTheme tt, ColorScheme cs) {
    return Column(
      crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          'Share Your Story Through Photos',
          textAlign: isMobile ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            fontSize: isMobile ? 32 : 50,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Discover amazing photography, connect with creators, and inspire the world.',
          textAlign: isMobile ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            fontSize: isMobile ? 16 : 20,
            color: tt.bodySmall?.color,
          ),
        ),
        const SizedBox(height: 30),
        
        // PEMBERANTASAN WIDTH 500 KAKU: Menggunakan constraints dinamis
        Container(
          constraints: const BoxConstraints(maxWidth: 500),
          width: double.infinity,
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search photos, creators...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Theme.of(context).inputDecorationTheme.fillColor ?? cs.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(height: 30),
        
        // Mengubah Row ke Wrap agar tombol otomatis turun ke bawah jika layar sangat sempit
        Wrap(
          spacing: 15,
          runSpacing: 12,
          alignment: isMobile ? WrapAlignment.center : WrapAlignment.start,
          children: [
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.cloud_upload),
              label: const Text('Upload Photo'),
            ),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.explore),
              label: const Text('Explore Gallery'),
            ),
          ],
        ),
      ],
    );
  }

  // Helper Widget: Gambar Hero Adaptif
  Widget _buildHeroImage(bool isMobile) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: Image.network(
        'https://picsum.photos/900/600',
        height: isMobile ? 260 : 450,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }

  static Widget statCard(
    BuildContext context,
    IconData icon,
    String number,
    String title,
  ) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withAlpha((0.06 * 255).round()),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: cs.primary, size: 45),
          const SizedBox(height: 10),
          Text(
            number,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          if (title.isNotEmpty) Text(title, style: TextStyle(color: tt.bodySmall?.color)),
        ],
      ),
    );
  }

  static Widget creatorCard(
    BuildContext context,
    String name,
    String role,
  ) {
    final tt = Theme.of(context).textTheme;

    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            color: Theme.of(context).shadowColor.withAlpha((0.06 * 255).round()),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            child: Icon(Icons.person, color: Theme.of(context).colorScheme.onSurface),
          ),
          const SizedBox(width: 15),
          
          // Menggunakan Expanded agar text memotong dengan aman jika ruang menyempit
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  role,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: tt.bodySmall?.color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}