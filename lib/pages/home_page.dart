import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:minimalsocialmedia/database/firestore.dart';
import 'package:minimalsocialmedia/pages/create_post_dialog.dart';
import 'package:minimalsocialmedia/pages/post_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirestoreDatabase database = FirestoreDatabase();
  int _selectedIndex = 0;

  void _showCreatePostDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return CreatePostDialog(
          onPostCreated: () {
            // Refresh the feed when a post is created
            setState(() {});
          },
        );
      },
    );
  }

  void _handleLike(String postId) {
    database.toggleLike(postId);
  }

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
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
          "Ramblee",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: database.getPostsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("No posts available"));
          }
          final postsDocs = snapshot.data!.docs;
          if (postsDocs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(25.0),
                child: Text("No posts yet"),
              ),
            );
          }
          return ListView.builder(
            itemCount: postsDocs.length,
            itemBuilder: (context, index) {
              final doc = postsDocs[index];
              final data = doc.data() as Map<String, dynamic>;

              String caption = data["caption"] ?? '';
              String authorUsername = data["authorUsername"] ?? '';
              String group = data["group"] ?? '';
              List<dynamic> imageUrlsList = data["imageUrls"] ?? [];
              int likes = data["likes"] ?? 0;
              List<dynamic> likedBy =
                  data.containsKey("likedBy")
                      ? data["likedBy"] as List<dynamic>
                      : [];
              String currentUid = database.user?.uid ?? '';
              bool isLiked =
                  currentUid.isNotEmpty ? likedBy.contains(currentUid) : false;
              DateTime createdAt =
                  data["createdAt"] != null
                      ? DateTime.parse(data["createdAt"])
                      : DateTime.now();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Post header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundImage: NetworkImage(
                            "https://i.pravatar.cc/150?u=${authorUsername}",
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          authorUsername,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "• $group",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.more_vert),
                          onPressed: () {},
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),

                  // Post image content
                  GestureDetector(
                    onDoubleTap: () => _handleLike(doc.id),
                    child:
                        imageUrlsList.isNotEmpty
                            ? Image.network(
                              imageUrlsList[0],
                              width: double.infinity,
                              height: 300,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: double.infinity,
                                  height: 300,
                                  color: Colors.grey[300],
                                  child: const Center(
                                    child: Icon(
                                      Icons.image_not_supported,
                                      size: 50,
                                    ),
                                  ),
                                );
                              },
                            )
                            : Container(
                              width: double.infinity,
                              height: 300,
                              color: Colors.grey[300],
                              child: const Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 50,
                                ),
                              ),
                            ),
                  ),

                  // Action buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? Colors.red : Colors.black,
                            size: 28,
                          ),
                          onPressed: () => _handleLike(doc.id),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.chat_bubble_outline,
                            size: 24,
                            color: Colors.black,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => PostDetailPage(postId: doc.id),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.send_outlined, size: 24),
                          onPressed: () {},
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.bookmark_border, size: 24),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),

                  // Post details
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "$likes likes",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Colors.black),
                        children: [
                          TextSpan(
                            text: "$authorUsername ",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(text: caption),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 2,
                    ),
                    child: Text(
                      "View all comments",
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Text(
                      _formatTimeAgo(createdAt),
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ),
                  const Divider(height: 30),
                ],
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
                  icon: Icon(
                    _selectedIndex == 0 ? Icons.home : Icons.home_outlined,
                    color: _selectedIndex == 0 ? Colors.black : Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedIndex = 0;
                    });
                  },
                ),
                IconButton(
                  icon: Icon(
                    _selectedIndex == 1
                        ? Icons.explore
                        : Icons.explore_outlined,
                    color: _selectedIndex == 1 ? Colors.black : Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedIndex = 1;
                    });
                  },
                ),
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
                    onPressed: () => _showCreatePostDialog(context),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _selectedIndex == 3
                        ? Icons.emoji_events
                        : Icons.emoji_events_outlined,
                    color: _selectedIndex == 3 ? Colors.black : Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedIndex = 3;
                    });
                    Navigator.pushNamed(context, '/leaderboard_page');
                  },
                ),
                IconButton(
                  icon: Icon(
                    _selectedIndex == 4 ? Icons.person : Icons.person_outline,
                    color: _selectedIndex == 4 ? Colors.black : Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedIndex = 4;
                    });
                    Navigator.pushNamed(context, '/profile_page');
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
