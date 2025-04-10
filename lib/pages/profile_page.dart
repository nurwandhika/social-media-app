import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:minimalsocialmedia/pages/post_detail_page.dart';

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

    print("Current user email: ${currentUser.email}");

    try {
      final QuerySnapshot postSnapshot =
          await FirebaseFirestore.instance
              .collection('Posts')
              .where('authorEmail', isEqualTo: currentUser.email)
              .get();

      print("Query returned ${postSnapshot.docs.length} posts");

      if (postSnapshot.docs.isEmpty) {
        // Try to get all posts to see if any exist
        final allPosts =
            await FirebaseFirestore.instance.collection('Posts').limit(5).get();
        print("Total posts in DB: ${allPosts.docs.length}");
        if (allPosts.docs.isNotEmpty) {
          print(
            "Sample post authorEmail: ${allPosts.docs.first.get('authorEmail')}",
          );
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          "Profile",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: getUserDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (snapshot.hasData) {
            Map<String, dynamic>? user = snapshot.data!.data();
            if (user == null) {
              return const Center(child: Text("No user data found"));
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
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        // Profile picture
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: NetworkImage(
                            "https://i.pravatar.cc/300?u=$email",
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildStatColumn(postCount, "Posts"),
                                  _buildStatColumn(totalLikes, "Likes"),
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
                    padding: const EdgeInsets.only(left: 16, top: 16),
                    child: Text(
                      username,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 16, top: 4, right: 16),
                    child: Text(
                      email,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ),

                  // Edit Profile button
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 8),
                            ),
                            child: Text(
                              "Edit Profile",
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Divider before posts
                  Divider(),

                  // Post grid title
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text(
                      "Posts",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),

                  // Post grid with actual user posts
                  // Post grid with actual user posts
                  FutureBuilder<List<QueryDocumentSnapshot>>(
                    future: getUserPosts(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
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
                                Icons.camera_alt_outlined,
                                size: 40,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                "No Posts Yet",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // Create a grid of actual posts
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.all(2),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 2,
                          mainAxisSpacing: 2,
                        ),
                        itemCount: posts.length,
                        itemBuilder: (context, index) {
                          final postData =
                              posts[index].data() as Map<String, dynamic>;
                          final List<dynamic> imageUrls =
                              postData["imageUrls"] ?? [];
                          final String title = postData["title"] ?? '';
                          final String postId = postData["postId"] ?? '';

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) =>
                                          PostDetailPage(postId: postId),
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  width: 0.5,
                                ),
                              ),
                              child:
                                  imageUrls.isNotEmpty
                                      ? Image.network(
                                        imageUrls[0],
                                        fit: BoxFit.cover,
                                        errorBuilder: (
                                          context,
                                          error,
                                          stackTrace,
                                        ) {
                                          // Fallback for image loading errors
                                          return Container(
                                            color: Colors.grey[300],
                                            child: Center(
                                              child: Text(
                                                title,
                                                textAlign: TextAlign.center,
                                                style: TextStyle(fontSize: 14),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          );
                                        },
                                        loadingBuilder: (
                                          context,
                                          child,
                                          loadingProgress,
                                        ) {
                                          if (loadingProgress == null)
                                            return child;
                                          return Center(
                                            child: CircularProgressIndicator(
                                              value:
                                                  loadingProgress
                                                              .expectedTotalBytes !=
                                                          null
                                                      ? loadingProgress
                                                              .cumulativeBytesLoaded /
                                                          loadingProgress
                                                              .expectedTotalBytes!
                                                      : null,
                                              strokeWidth: 2.0,
                                            ),
                                          );
                                        },
                                      )
                                      : Center(
                                        child: Text(
                                          title,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontSize: 14),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            );
          } else {
            return const Center(child: Text("No data"));
          }
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
                  icon: Icon(Icons.emoji_events_outlined, color: Colors.grey),
                  onPressed: () {
                    Navigator.pushReplacementNamed(
                      context,
                      '/leaderboard_page',
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.person, color: Colors.black),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(int count, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count.toString(),
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
      ],
    );
  }
}
