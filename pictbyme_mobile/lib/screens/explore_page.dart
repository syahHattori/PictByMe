import 'package:flutter/material.dart';
import '../widgets/custom_navbar.dart';

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Mendeteksi ukuran lebar layar device
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 800;

    // Margin & padding adaptif (50 di desktop, 20 di mobile)
    final double dynamicPadding = isMobile ? 20 : 50;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: const CustomNavbar(
          activePage: 'Explore',
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
                vertical: isMobile ? 40 : 50,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    cs.primary,
                    cs.secondary,
                  ],
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Explore Amazing Photography',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: cs.onPrimary,
                      fontSize: isMobile ? 28 : 42, // Ukuran teks adaptif
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'Discover inspiration from creators around the world.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: cs.onPrimary.withAlpha((0.9 * 255).round()),
                      fontSize: isMobile ? 15 : 18,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // PEMBERANTASAN WIDTH 600 KAKU
                  Container(
                    constraints: const BoxConstraints(maxWidth: 600),
                    width: double.infinity,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search photos, collections, creators...',
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
                ],
              ),
            ),

            const SizedBox(height: 40),

            // CATEGORY CHIPS WITH CENTER ALIGNMENT
            Padding(
              padding: EdgeInsets.symmetric(horizontal: dynamicPadding),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: const [
                  Chip(label: Text('Nature')),
                  Chip(label: Text('Travel')),
                  Chip(label: Text('Portrait')),
                  Chip(label: Text('Food')),
                  Chip(label: Text('Street')),
                  Chip(label: Text('Wildlife')),
                  Chip(label: Text('Architecture')),
                  Chip(label: Text('Fashion')),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // COLLECTIONS SECTION
            Text(
              'Featured Collections',
              style: TextStyle(
                fontSize: isMobile ? 26 : 34,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 25),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: dynamicPadding),
              child: Wrap(
                spacing: 20,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: [
                  collectionCard(context, 'Nature Collection', '1,245 Photos', 1),
                  collectionCard(context, 'Travel Collection', '986 Photos', 2),
                  collectionCard(context, 'Street Collection', '1,530 Photos', 3),
                ],
              ),
            ),

            const SizedBox(height: 50),

            // TRENDING PHOTOS SECTION
            Text(
              'Trending Photos',
              style: TextStyle(
                fontSize: isMobile ? 26 : 34,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 25),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: dynamicPadding),
              child: Wrap(
                spacing: 20,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: List.generate(
                  8,
                  (index) => Container(
                    constraints: const BoxConstraints(maxWidth: 280),
                    width: double.infinity,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        'https://picsum.photos/400?random=${index + 20}',
                        height: index.isEven ? 320 : 220,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 50),

            // TOP CREATORS SECTION
            Text(
              'Top Creators',
              style: TextStyle(
                fontSize: isMobile ? 26 : 34,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 25),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: dynamicPadding),
              child: Wrap(
                spacing: 20,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: [
                  creatorCard(context, 'Sarah Johnson', '12.4K Followers'),
                  creatorCard(context, 'Alex Brown', '9.8K Followers'),
                  creatorCard(context, 'Emma Wilson', '15.1K Followers'),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  static Widget collectionCard(
    BuildContext context,
    String title,
    String subtitle,
    int seed,
  ) {
    final tt = Theme.of(context).textTheme;

    return Container(
      // Mengubah width: 350 kaku menjadi constraint fleksibel
      constraints: const BoxConstraints(maxWidth: 350),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withAlpha((0.06 * 255).round()),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
            child: Image.network(
              'https://picsum.photos/500/250?random=$seed',
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: tt.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget creatorCard(
    BuildContext context,
    String name,
    String followers,
  ) {
    final tt = Theme.of(context).textTheme;

    return Container(
      // Mengubah width: 300 kaku menjadi constraint fleksibel
      constraints: const BoxConstraints(maxWidth: 300),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withAlpha((0.06 * 255).round()),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 35,
            child: Icon(Icons.person, color: Theme.of(context).colorScheme.onSurface),
          ),
          const SizedBox(height: 15),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            followers,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: tt.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 15),
          ElevatedButton(
            onPressed: () {},
            child: const Text('Follow'),
          ),
        ],
      ),
    );
  }
}