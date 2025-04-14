import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:minimalsocialmedia/models/post_model.dart';
import 'package:minimalsocialmedia/pages/home_page.dart';
import 'package:minimalsocialmedia/pages/post_detail_page.dart';

class UserProfilePage extends StatefulWidget {
  final String userEmail;
  final String username;

  const UserProfilePage({
    Key? key,
    required this.userEmail,
    required this.username,
  }) : super(key: key);

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  bool _isFollowing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkFollowStatus();
  }

  Future<void> _checkFollowStatus() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('Users')
              .doc(currentUser.email)
              .collection('following')
              .doc(widget.userEmail)
              .get();

      setState(() {
        _isFollowing = snapshot.exists;
      });
    } catch (e) {
      debugPrint('Error checking follow status: $e');
    }
  }

  Future<void> _toggleFollow() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final batch = FirebaseFirestore.instance.batch();
      final followRef = FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUser.email)
          .collection('following')
          .doc(widget.userEmail);

      final followerRef = FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.userEmail)
          .collection('followers')
          .doc(currentUser.email);

      final userDoc = FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.userEmail);

      if (_isFollowing) {
        // Unfollow
        batch.delete(followRef);
        batch.delete(followerRef);
        batch.update(userDoc, {'followerCount': FieldValue.increment(-1)});
      } else {
        // Follow
        batch.set(followRef, {
          'timestamp': FieldValue.serverTimestamp(),
          'username': widget.username,
        });
        batch.set(followerRef, {
          'timestamp': FieldValue.serverTimestamp(),
          'username': currentUser.displayName ?? 'Anonymous',
        });
        batch.update(userDoc, {'followerCount': FieldValue.increment(1)});
      }

      await batch.commit();

      setState(() {
        _isFollowing = !_isFollowing;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Text(widget.username, style: theme.textTheme.titleLarge),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: Column(
        children: [
          // User profile header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Avatar and username sections remain unchanged
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primary,
                  radius: 40,
                  child: Text(
                    widget.username.isNotEmpty
                        ? widget.username[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(widget.username, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 16),

                // Stats row
                // Stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    StreamBuilder<QuerySnapshot>(
                      stream:
                          FirebaseFirestore.instance
                              .collection('Posts')
                              .where('authorEmail', isEqualTo: widget.userEmail)
                              .snapshots(),
                      builder: (context, snapshot) {
                        final postCount =
                            snapshot.hasData ? snapshot.data!.docs.length : 0;

                        // Calculate total likes from existing posts
                        int totalLikes = 0;
                        if (snapshot.hasData) {
                          for (var doc in snapshot.data!.docs) {
                            final data = doc.data() as Map<String, dynamic>;
                            totalLikes += (data['likes'] ?? 0) as int;
                          }
                        }

                        return Row(
                          children: [
                            _buildStat('Posts', postCount, theme),
                            const SizedBox(width: 32),
                            _buildStat('Likes', totalLikes, theme),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          Divider(color: theme.dividerColor),

          // User's posts - using StreamBuilder with TwitterPostCard like in ProfilePage
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('Posts')
                      .where('authorEmail', isEqualTo: widget.userEmail)
                      .snapshots(),
              builder: (context, snapshot) {
                // Only show loading on initial fetch
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.post_add,
                          size: 48,
                          color: theme.colorScheme.tertiary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text('No posts yet', style: theme.textTheme.bodyLarge),
                      ],
                    ),
                  );
                }

                // Sort posts manually instead of using orderBy (which can cause flickering)
                final posts =
                    snapshot.data!.docs.map((doc) {
                        final postData = doc.data() as Map<String, dynamic>;
                        final postId = doc.id;

                        final content =
                            postData["content"] ?? postData["caption"] ?? '';
                        final authorUsername =
                            postData["authorUsername"] ?? widget.username;
                        final authorEmail =
                            postData["authorEmail"] ?? widget.userEmail;
                        final likes = postData["likes"] ?? 0;

                        // More robust date parsing
                        DateTime createdAt = DateTime.now();
                        try {
                          if (postData['createdAt'] is Timestamp) {
                            createdAt =
                                (postData['createdAt'] as Timestamp).toDate();
                          } else if (postData['createdAt'] is String) {
                            createdAt = DateTime.parse(postData['createdAt']);
                          }
                        } catch (e) {
                          // Fallback silently
                        }

                        final likedBy =
                            postData.containsKey("likedBy") &&
                                    postData["likedBy"] is List
                                ? List<String>.from(postData["likedBy"])
                                : <String>[];

                        return PostModel(
                          postId: postId,
                          content: content,
                          authorUsername: authorUsername,
                          authorEmail: authorEmail,
                          likes: likes,
                          createdAt: createdAt,
                          likedBy: likedBy,
                        );
                      }).toList()
                      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                return ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return TwitterPostCard(
                      post: post,
                      onLike: () {
                        FirebaseFirestore.instance
                            .collection('Posts')
                            .doc(post.postId)
                            .update({'likes': FieldValue.increment(1)});
                      },
                      onReply: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    PostDetailPage(postId: post.postId),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, int count, ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(count.toString(), style: theme.textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(label, style: theme.textTheme.bodyMedium),
      ],
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
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
