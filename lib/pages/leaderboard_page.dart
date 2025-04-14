import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({Key? key}) : super(key: key);

  @override
  _LeaderboardPageState createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Get users with their email for later lookup
  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return firestore.collection('Users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'email': doc.id,
          'username': data['username'] ?? 'Anonymous',
        };
      }).toList();
    });
  }

  // Get all posts to calculate accurate like counts
  Stream<Map<String, int>> getAccurateLikesStream() {
    return firestore.collection('Posts').snapshots().map((snapshot) {
      Map<String, int> authorLikes = {};

      // Calculate likes based on existing posts
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final authorEmail = data['authorEmail'];
        final likes = (data['likes'] ?? 0) as int;

        if (authorEmail != null) {
          if (authorLikes.containsKey(authorEmail)) {
            authorLikes[authorEmail] = authorLikes[authorEmail]! + likes;
          } else {
            authorLikes[authorEmail] = likes;
          }
        }
      }

      return authorLikes;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: theme.colorScheme.background,
        title: Text(
          "Leaderboard",
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.inversePrimary,
          ),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: getUsersStream(),
        builder: (context, usersSnapshot) {
          if (usersSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!usersSnapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          return StreamBuilder<Map<String, int>>(
            stream: getAccurateLikesStream(),
            builder: (context, likesSnapshot) {
              if (!likesSnapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              // Combine user data with accurate like counts
              final users = usersSnapshot.data!;
              final likes = likesSnapshot.data!;

              List<Map<String, dynamic>> leaderboardData = [];

              for (var user in users) {
                final email = user['email'];
                final totalLikes = likes[email] ?? 0;
                leaderboardData.add({
                  'username': user['username'],
                  'totalLikes': totalLikes,
                  'email': email,
                });
              }

              // Sort by likes count descending
              leaderboardData.sort((a, b) =>
                  b['totalLikes'].compareTo(a['totalLikes']));

              // Limit to top 20
              if (leaderboardData.length > 20) {
                leaderboardData = leaderboardData.sublist(0, 20);
              }

              // If empty, show no data
              if (leaderboardData.isEmpty) {
                return Center(
                  child: Text("No leaderboard data available"),
                );
              }

              // Continue with your existing ListView.builder
              return ListView.builder(
                itemCount: leaderboardData.length,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemBuilder: (context, index) {
                  final data = leaderboardData[index];
                  final username = data['username'];
                  final totalLikes = data['totalLikes'];

                  // Styling for top 3 ranks
                  Color rankColor;
                  Widget rankWidget;

                  if (index == 0) {
                    rankColor = Colors.amber; // Gold
                    rankWidget = Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: rankColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          '1',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  } else if (index == 1) {
                    rankColor = Colors.grey.shade400; // Silver
                    rankWidget = Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: rankColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          '2',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  } else if (index == 2) {
                    rankColor = Colors.brown.shade300; // Bronze
                    rankWidget = Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: rankColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          '3',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  } else {
                    rankWidget = SizedBox(
                      width: 32,
                      height: 32,
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.inversePrimary,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  }

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.dividerColor, width: 0.5),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 8),
                        rankWidget,
                        const SizedBox(width: 16),
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: theme.colorScheme.primary,
                          child: Text(
                            username.isNotEmpty ? username[0].toUpperCase() : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(username, style: theme.textTheme.titleMedium),
                              const SizedBox(height: 2),
                              Text(
                                "Posts liked $totalLikes times",
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondary,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.favorite,
                                color: Colors.red,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "$totalLikes",
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: theme.dividerColor, width: 0.5),
          ),
          color: theme.colorScheme.background,
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: BottomAppBar(
          elevation: 0,
          color: theme.colorScheme.background,
          child: SizedBox(
            height: 56.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                IconButton(
                  icon: Icon(Icons.home_outlined, color: theme.iconTheme.color),
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/');
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.explore_outlined,
                    color: theme.iconTheme.color,
                  ),
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/explore_page');
                  },
                ),
                Container(
                  width: 48,
                  height: 30,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.add, color: Colors.white, size: 26),
                    onPressed: () {},
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.emoji_events,
                    color: theme.colorScheme.primary,
                  ),
                  onPressed: () {
                    // Already on leaderboard page
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.person_outline,
                    color: theme.iconTheme.color,
                  ),
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/profile_page');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}