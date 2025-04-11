import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:minimalsocialmedia/pages/post_detail_page.dart';

import '../models/post_model.dart';
import 'home_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _selectedIndex = 4; // Profile tab selected

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserDetails() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception("User not logged in");
    }
    final docRef = FirebaseFirestore.instance
        .collection("Users")
        .doc(currentUser.email);
    final doc = await docRef.get();
    if (!doc.exists) {
      await docRef.set({
        'username': currentUser.displayName ?? 'Anonymous',
        'email': currentUser.email,
        'totalLikes': 0,
        'postCount': 0,
      });
      return await docRef.get();
    } else {
      if (doc.data()!['totalLikes'] == null) {
        await docRef.update({'totalLikes': 0});
        return await docRef.get();
      }
    }
    return doc;
  }

  Future<List<QueryDocumentSnapshot>> getUserPosts() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      print("No current user found");
      return [];
    }

    try {
      print("Querying posts for email: ${currentUser.email}");

      // First try without orderBy to test if the basic query works
      final QuerySnapshot postSnapshot = await FirebaseFirestore.instance
          .collection('Posts')
          .where('authorEmail', isEqualTo: currentUser.email)
          .get();

      print("Query returned ${postSnapshot.docs.length} posts");

      if (postSnapshot.docs.isEmpty) {
        // Debug: Check if we can find any posts by this user
        final samplePosts = await FirebaseFirestore.instance
            .collection('Posts')
            .limit(5)
            .get();

        print("Sample posts in DB: ${samplePosts.docs.length}");

        if (samplePosts.docs.isNotEmpty) {
          // Check field names in the first post
          print("Sample post fields: ${samplePosts.docs.first.data().keys.toList()}");
        }
      }

      return postSnapshot.docs;
    } catch (e) {
      print("Error fetching posts: $e");
      return [];
    }
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
          "Profile",
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.inversePrimary,
          ),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: getUserDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: theme.colorScheme.primary),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: theme.textTheme.bodyLarge,
              ),
            );
          } else if (snapshot.hasData) {
            Map<String, dynamic>? user = snapshot.data!.data();
            if (user == null) {
              return Center(
                child: Text(
                  "No user data found",
                  style: theme.textTheme.bodyLarge,
                ),
              );
            }

            String username = user['username'] ?? 'Anonymous';
            String email = user['email'] ?? '';
            int totalLikes = user['totalLikes'] ?? 0;

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Profile picture
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: theme.colorScheme.primary,
                          child: Text(
                            username.isNotEmpty ? username[0].toUpperCase() : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),

                        // Stats - only Posts and Likes
                        Expanded(
                          child: FutureBuilder<List<QueryDocumentSnapshot>>(
                            future: getUserPosts(),
                            builder: (context, postSnapshot) {
                              int postCount = postSnapshot.data?.length ?? 0;

                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildStatColumn(postCount, "Posts", theme),
                                  _buildStatColumn(totalLikes, "Likes", theme),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Username and bio
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16),
                    child: Text(
                      username,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 16, top: 4, right: 16),
                    child: Text(
                      email,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),

                  // Divider before posts
                  Divider(color: theme.dividerColor),

                  // Post title
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text(
                      "Posts",
                      style: theme.textTheme.titleMedium,
                    ),
                  ),

                  // Twitter-style post list
                  FutureBuilder<List<QueryDocumentSnapshot>>(
                    future: getUserPosts(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: theme.colorScheme.primary,
                          ),
                        );
                      }

                      final posts = snapshot.data ?? [];
                      if (posts.isEmpty) {
                        return Container(
                          height: 200,
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 40,
                                color: theme.iconTheme.color,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "No Posts Yet",
                                style: theme.textTheme.titleMedium,
                              ),
                            ],
                          ),
                        );
                      }

                      // Twitter-style post list
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        itemCount: posts.length,
                        itemBuilder: (context, index) {
                          final postData = posts[index].data() as Map<String, dynamic>;
                          final postId = posts[index].id;
                          final content = postData["content"] ?? postData["caption"] ?? '';
                          final authorUsername = postData["authorUsername"] ?? '';
                          final authorEmail = postData["authorEmail"] ?? '';
                          final likes = postData["likes"] ?? 0;
                          final likedBy = postData.containsKey("likedBy")
                              ? List<String>.from(postData["likedBy"])
                              : <String>[];
                          final createdAt = postData["createdAt"] != null
                              ? DateTime.parse(postData["createdAt"])
                              : DateTime.now();

                          final post = PostModel(
                            postId: postId,
                            content: content,
                            authorUsername: authorUsername,
                            authorEmail: authorEmail,
                            likes: likes,
                            createdAt: createdAt,
                            likedBy: likedBy,
                          );

                          return TwitterPostCard(
                            post: post,
                            onLike: () {
                              // Handle like functionality
                              FirebaseFirestore.instance.collection('Posts')
                                  .doc(postId).update({
                                'likes': FieldValue.increment(1)
                              });
                            },
                            onReply: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PostDetailPage(postId: postId),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            );
          } else {
            return Center(
              child: Text(
                "No data",
                style: theme.textTheme.bodyLarge,
              ),
            );
          }
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
                    Icons.emoji_events_outlined,
                    color: theme.iconTheme.color,
                  ),
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/leaderboard_page');
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.person,
                    color: theme.colorScheme.primary,
                  ),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(int count, String label, ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count.toString(),
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}