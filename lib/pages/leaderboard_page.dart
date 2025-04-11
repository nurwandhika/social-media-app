import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({Key? key}) : super(key: key);

  @override
  _LeaderboardPageState createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  int _selectedIndex = 3;

  Stream<QuerySnapshot> getLeaderboardStream() {
    return firestore
        .collection('Users')
        .orderBy('totalLikes', descending: true)
        .limit(20)
        .snapshots();
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
      body: StreamBuilder<QuerySnapshot>(
        stream: getLeaderboardStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            );
          }
          if (!snapshot.hasData ||
              snapshot.data == null ||
              snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "No leaderboard data available",
                style: theme.textTheme.bodyLarge,
              ),
            );
          }

          final leaderboardDocs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: leaderboardDocs.length,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemBuilder: (context, index) {
              final doc = leaderboardDocs[index].data() as Map<String, dynamic>;
              final username = doc['username'] ?? 'Anonymous';
              final totalLikes = doc['totalLikes'] ?? 0;

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
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
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
                          Text(
                            username,
                            style: theme.textTheme.titleMedium,
                          ),
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
                          const Icon(Icons.favorite, color: Colors.red, size: 16),
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
                  icon: Icon(
                    Icons.home_outlined,
                    color: theme.iconTheme.color,
                  ),
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/');
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.explore_outlined,
                    color: theme.iconTheme.color,
                  ),
                  onPressed: () {},
                ),
                // Add button - center
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
                    color: theme.colorScheme.primary, // Selected color
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