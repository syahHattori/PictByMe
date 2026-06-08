import 'package:flutter/material.dart';
import '../widgets/custom_navbar.dart';
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // theme-aware colors will be used via Theme.of(context)

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

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

            // HERO
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(60),
              child: Row(
                children: [

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [

                        const Text(
                          'Share Your Story Through Photos',
                          style: TextStyle(
                            fontSize: 50,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 20),

                        Text(
  'Discover amazing photography, connect with creators, and inspire the world.',
                        style: TextStyle(
    fontSize: 20,
    color: tt.bodySmall?.color,
  ),
),

const SizedBox(height: 30),

SizedBox(
  width: 500,
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

                        const SizedBox(height: 30),

                        Row(
                          children: [

                            ElevatedButton.icon(
                              onPressed: () {},
                              icon: const Icon(
                                Icons.cloud_upload,
                              ),
                              label: const Text(
                                'Upload Photo',
                              ),
                            ),

                            const SizedBox(width: 15),

                            OutlinedButton.icon(
                              onPressed: () {},
                              icon: const Icon(
                                Icons.explore,
                              ),
                              label: const Text(
                                'Explore Gallery',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(25),
                      child: Image.network(
                        'https://picsum.photos/900/600',
                        height: 450,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // STATS
            Container(
              width: double.infinity,
              color: cs.surfaceContainerHighest,
              padding: const EdgeInsets.all(50),
              child: Wrap(
                alignment:
                    WrapAlignment.spaceEvenly,
                spacing: 20,
                runSpacing: 20,
                children: [

                      statCard(context,
                        Icons.photo,
                        '25K+',
                        'Photos',
                      ),

                      statCard(context,
                        Icons.people,
                        '10K+',
                        'Creators',
                      ),

                      statCard(context,
                        Icons.favorite,
                        '50K+',
                        'Likes',
                      ),

                      statCard(context,
                        Icons.bookmark,
                        '5K+',
                        'Collections',
                      ),
                ],
              ),
            ),

            // CATEGORIES
            Padding(
              padding: const EdgeInsets.all(60),
              child: Column(
                children: [

                  const Text(
                    'Photography Categories',
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 40),

                  Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: [

                      statCard(context,
                        Icons.landscape,
                        'Nature',
                        '',
                      ),

                      statCard(context,
                        Icons.flight,
                        'Travel',
                        '',
                      ),

                      statCard(context,
                        Icons.restaurant,
                        'Food',
                        '',
                      ),

                      statCard(context,
                        Icons.location_city,
                        'Street',
                        '',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // FEATURED CREATORS
            Padding(
              padding: const EdgeInsets.all(60),
              child: Column(
                children: [

                  const Text(
                    'Featured Creators',
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 40),

                  Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: [

                      creatorCard(
                        context,
                        'Sarah',
                        'Landscape Photographer',
                      ),

                      creatorCard(
                        context,
                        'John',
                        'Travel Photographer',
                      ),

                      creatorCard(
                        context,
                        'Emma',
                        'Street Photographer',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // TRENDING
            Padding(
              padding: const EdgeInsets.all(60),
              child: Column(
                children: [

                  const Text(
                    'Trending Photos',
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 40),

                  Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: List.generate(
                      4,
                      (index) => ClipRRect(
                        borderRadius:
                            BorderRadius.circular(
                          20,
                        ),
                        child: Image.network(
                          'https://picsum.photos/400?random=$index',
                          width: 280,
                          height: 280,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // JOIN COMMUNITY
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(60),
              padding: const EdgeInsets.all(50),
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
                      fontSize: 36,
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
                    onPressed: () {},
                    icon: Icon(
                      Icons.person_add,
                      color: cs.onPrimary,
                    ),
                    label: Text(
                      'Join Now',
                      style: TextStyle(color: cs.onPrimary),
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

  static Widget statCard(BuildContext context,
    IconData icon,
    String number,
    String title,
  ) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      width: 220,
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
        children: [
          Icon(
            icon,
            color: cs.primary,
            size: 45,
          ),

          const SizedBox(height: 10),

          Text(
            number,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          Text(title, style: TextStyle(color: tt.bodySmall?.color)),
        ],
      ),
    );
  }

  static Widget creatorCard(BuildContext context,
    String name,
    String role,
  ) {
    final tt = Theme.of(context).textTheme;

    return Container(
      width: 320,
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

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              Text(
                role,
                style: TextStyle(
                  color: tt.bodySmall?.color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
