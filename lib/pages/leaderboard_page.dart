// dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({Key? key}) : super(key: key);

  @override
  _LeaderboardPageState createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Query that assumes user documents have a 'totalLikes' field.
  Stream<QuerySnapshot> getLeaderboardStream() {
    return firestore
        .collection('Users')
        .orderBy('totalLikes', descending: true)
        .limit(10)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text("Leaderboard"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: getLeaderboardStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No leaderboard data available"));
          }
          final leaderboardDocs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: leaderboardDocs.length,
            itemBuilder: (context, index) {
              final doc = leaderboardDocs[index].data() as Map<String, dynamic>;
              final username = doc['username'] ?? 'Anonymous';
              final totalLikes = doc['totalLikes'] ?? 0;
              return ListTile(
                leading: CircleAvatar(
                  child: Text('${index + 1}'),
                ),
                title: Text(username),
                trailing: Text('$totalLikes Likes'),
              );
            },
          );
        },
      ),
    );
  }
}