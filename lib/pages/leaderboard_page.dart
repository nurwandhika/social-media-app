import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({Key? key}) : super(key: key);

  @override
  _LeaderboardPageState createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  int _selectedIndex = 3; // Add this to fix the undefined variable error

  Stream<QuerySnapshot> getLeaderboardStream() {
    return firestore
        .collection('Users')
        .orderBy('totalLikes', descending: true)
        .limit(20)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          "Leaderboard",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: getLeaderboardStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData ||
              snapshot.data == null ||
              snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "No leaderboard data available",
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
            );
          }

          final leaderboardDocs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: leaderboardDocs.length,
            padding: EdgeInsets.symmetric(vertical: 8),
            itemBuilder: (context, index) {
              final doc = leaderboardDocs[index].data() as Map<String, dynamic>;
              final username = doc['username'] ?? 'Anonymous';
              final totalLikes = doc['totalLikes'] ?? 0;

              // Styling for top 3 ranks
              Color rankColor = Colors.grey.shade600;
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
                  child: Center(
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
                  child: Center(
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
                  child: Center(
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
                rankWidget = Container(
                  width: 32,
                  height: 32,
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              }

              return Container(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.08),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    SizedBox(width: 8),
                    rankWidget,
                    SizedBox(width: 16),
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: NetworkImage(
                        "https://i.pravatar.cc/150?u=$username",
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            username,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "Posts liked $totalLikes times",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.favorite, color: Colors.red, size: 16),
                          SizedBox(width: 4),
                          Text(
                            "$totalLikes",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8),
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
            top: BorderSide(color: Colors.grey.shade300, width: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: Offset(0, -1),
            ),
          ],
        ),
        child: BottomAppBar(
          elevation: 0,
          color: Colors.white,
          child: SizedBox(
            height: 56.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                IconButton(
                  icon: Icon(Icons.home_outlined, color: Colors.grey),
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/');
                  },
                ),
                IconButton(
                  icon: Icon(Icons.explore_outlined, color: Colors.grey),
                  onPressed: () {},
                ),
                // Add button - center
                Container(
                  width: 48,
                  height: 30,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue, Colors.purple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.add, color: Colors.white, size: 26),
                    onPressed: () {},
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _selectedIndex == 3
                        ? Icons.emoji_events
                        : Icons.emoji_events_outlined,
                    color: Colors.black, // Selected color
                  ),
                  onPressed: () {
                    // Already on leaderboard page
                  },
                ),
                IconButton(
                  icon: Icon(Icons.person_outline, color: Colors.grey),
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
