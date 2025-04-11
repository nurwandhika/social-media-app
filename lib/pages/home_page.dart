import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:minimalsocialmedia/database/firestore.dart';
import 'package:minimalsocialmedia/models/post_model.dart';
import 'package:minimalsocialmedia/pages/create_post_dialog.dart';
import 'package:minimalsocialmedia/pages/post_detail_page.dart';
// import 'package:timeago/timeago.dart' as timeago;

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
            setState(() {});
          },
        );
      },
    );
  }

  void _handleLike(String postId) {
    database.toggleLike(postId);
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
        centerTitle: false,
        title: Text(
          "Ramblee",
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.inversePrimary,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: database.getPostsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Text(
                "No posts available",
                style: theme.textTheme.bodyLarge,
              ),
            );
          }
          final postsDocs = snapshot.data!.docs;
          if (postsDocs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(25.0),
                child: Text(
                  "No posts yet",
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            );
          }
          return ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: postsDocs.length,
            itemBuilder: (context, index) {
              // Post data extraction remains the same
              final doc = postsDocs[index];
              final data = doc.data() as Map<String, dynamic>;

              final postId = doc.id;
              final content = data["content"] ?? data["caption"] ?? '';
              final authorUsername = data["authorUsername"] ?? '';
              final authorEmail = data["authorEmail"] ?? '';
              final likes = data["likes"] ?? 0;
              final likedBy = data.containsKey("likedBy")
                  ? List<String>.from(data["likedBy"])
                  : <String>[];
              final createdAt = data["createdAt"] != null
                  ? DateTime.parse(data["createdAt"])
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

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PostDetailPage(postId: postId),
                    ),
                  );
                },
                child: TwitterPostCard(
                  post: post,
                  onLike: () => _handleLike(postId),
                  onReply: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PostDetailPage(postId: postId),
                      ),
                    );
                  },
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
                    _selectedIndex == 0 ? Icons.home : Icons.home_outlined,
                    color: _selectedIndex == 0 ? theme.colorScheme.primary : theme.iconTheme.color,
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedIndex = 0;
                    });
                  },
                ),
                IconButton(
                  icon: Icon(
                    _selectedIndex == 1 ? Icons.explore : Icons.explore_outlined,
                    color: _selectedIndex == 1 ? theme.colorScheme.primary : theme.iconTheme.color,
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
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.add, color: Colors.white, size: 26),
                    onPressed: () => _showCreatePostDialog(context),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _selectedIndex == 3 ? Icons.emoji_events : Icons.emoji_events_outlined,
                    color: _selectedIndex == 3 ? theme.colorScheme.primary : theme.iconTheme.color,
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
                    color: _selectedIndex == 4 ? theme.colorScheme.primary : theme.iconTheme.color,
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

class TwitterPostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback onLike;
  final VoidCallback onReply;

  const TwitterPostCard({
    Key? key,
    required this.post,
    required this.onLike,
    required this.onReply,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserEmail = FirebaseAuth.instance.currentUser?.email;
    final isLiked = currentUserEmail != null && post.likedBy.contains(currentUserEmail);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.dividerColor, width: 0.5),
        ),
        color: theme.colorScheme.background,
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with avatar and username
          Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primary,
                child: Text(
                  post.authorUsername.isNotEmpty ? post.authorUsername[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                post.authorUsername,
                style: theme.textTheme.titleMedium,
              ),
              const Spacer(),
              Text(
                _formatTimeAgo(post.createdAt),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),

          // Tweet content
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 12, left: 4),
            child: Text(
              post.content,
              style: theme.textTheme.bodyLarge,
            ),
          ),

          // Action buttons
          Row(
            children: [
              // Like button
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : theme.iconTheme.color,
                      size: 18,
                    ),
                    onPressed: onLike,
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                  Text(
                    post.likes.toString(),
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(width: 24),

              // Reply button
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.chat_bubble_outline,
                      color: theme.iconTheme.color,
                      size: 18,
                    ),
                    onPressed: onReply,
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                  Text(
                    "Reply",
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }
}