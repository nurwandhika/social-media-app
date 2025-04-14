import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:minimalsocialmedia/models/post_model.dart';
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
                // Avatar
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

                // Username
                Text(widget.username, style: theme.textTheme.headlineSmall),

                const SizedBox(height: 8),

                // Follow button
                ElevatedButton(
                  onPressed: _isLoading ? null : _toggleFollow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isFollowing
                            ? theme.colorScheme.secondary
                            : theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child:
                      _isLoading
                          ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.onPrimary,
                            ),
                          )
                          : Text(_isFollowing ? 'Unfollow' : 'Follow'),
                ),

                const SizedBox(height: 16),

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
                        return _buildStat('Posts', postCount, theme);
                      },
                    ),
                    StreamBuilder<DocumentSnapshot>(
                      stream:
                          FirebaseFirestore.instance
                              .collection('Users')
                              .doc(widget.userEmail)
                              .snapshots(),
                      builder: (context, snapshot) {
                        final followerCount =
                            snapshot.hasData && snapshot.data!.exists
                                ? (snapshot.data!.data()
                                        as Map<
                                          String,
                                          dynamic
                                        >)['followerCount'] ??
                                    0
                                : 0;
                        return _buildStat('Followers', followerCount, theme);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          Divider(color: theme.dividerColor),

          // User's posts
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('Posts')
                      .where('authorEmail', isEqualTo: widget.userEmail)
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
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

                final posts =
                    snapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;

                      DateTime? createdAt;
                      try {
                        if (data['createdAt'] is Timestamp) {
                          createdAt = (data['createdAt'] as Timestamp).toDate();
                        } else if (data['createdAt'] is String) {
                          createdAt = DateTime.parse(data['createdAt']);
                        }
                      } catch (_) {
                        createdAt = DateTime.now();
                      }

                      final likedBy =
                          data.containsKey("likedBy")
                              ? List<String>.from(data["likedBy"])
                              : <String>[];

                      return PostModel(
                        postId: doc.id,
                        content: data['content'] ?? '',
                        authorUsername: data['authorUsername'] ?? '',
                        authorEmail: data['authorEmail'] ?? '',
                        likes: data['likes'] ?? 0,
                        createdAt: createdAt ?? DateTime.now(),
                        likedBy: likedBy,
                      );
                    }).toList();

                return ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      PostDetailPage(postId: post.postId),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                post.content,
                                style: theme.textTheme.bodyLarge,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.favorite,
                                    color: theme.colorScheme.primary,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${post.likes}',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    _formatTimeAgo(post.createdAt),
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
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
