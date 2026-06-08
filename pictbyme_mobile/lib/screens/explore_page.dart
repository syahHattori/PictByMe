import 'package:flutter/material.dart';
import '../widgets/custom_navbar.dart';
class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  // theme-aware colors via Theme.of(context)

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

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

            // HERO
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(50),
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
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

                  Text(
                    'Discover inspiration from creators around the world.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: cs.onPrimary.withAlpha((0.9 * 255).round()),
                      fontSize: 18,
                    ),
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: 600,
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

            // CATEGORY CHIPS
            Wrap(
              spacing: 10,
              runSpacing: 10,
                children: [

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

            const SizedBox(height: 50),

            // COLLECTIONS
            const Text(
              'Featured Collections',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            Wrap(
              spacing: 20,
              runSpacing: 20,
              children: [

                collectionCard(context,
                  'Nature Collection',
                  '1,245 Photos',
                  1,
                ),

                collectionCard(context,
                  'Travel Collection',
                  '986 Photos',
                  2,
                ),

                collectionCard(context,
                  'Street Collection',
                  '1,530 Photos',
                  3,
                ),
              ],
            ),

            const SizedBox(height: 60),

            // TRENDING PHOTOS
            const Text(
              'Trending Photos',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            Wrap(
              spacing: 20,
              runSpacing: 20,
              children: List.generate(
                8,
                (index) => ClipRRect(
                  borderRadius:
                      BorderRadius.circular(20),
                  child: Image.network(
                    'https://picsum.photos/400?random=${index + 20}',
                    width: 280,
                    height: index.isEven ? 320 : 220,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 60),

            // TOP CREATORS
            const Text(
              'Top Creators',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            Wrap(
              spacing: 20,
              runSpacing: 20,
              children: [

                creatorCard(
                  context,
                  'Sarah Johnson',
                  '12.4K Followers',
                ),

                creatorCard(
                  context,
                  'Alex Brown',
                  '9.8K Followers',
                ),

                creatorCard(
                  context,
                  'Emma Wilson',
                  '15.1K Followers',
                ),
              ],
            ),

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  static Widget collectionCard(BuildContext context,
    String title,
    String subtitle,
    int seed,
  ) {
    final tt = Theme.of(context).textTheme;

    return Container(
      width: 350,
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
        children: [

          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(
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
              children: [

                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  subtitle,
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

  static Widget creatorCard(BuildContext context,
    String name,
    String followers,
  ) {
    final tt = Theme.of(context).textTheme;

    return Container(
      width: 300,
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
        children: [
          CircleAvatar(
            radius: 35,
            child: Icon(Icons.person, color: Theme.of(context).colorScheme.onSurface),
          ),

          const SizedBox(height: 15),

          Text(
            name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            followers,
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