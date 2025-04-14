import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:minimalsocialmedia/database/firestore_database.dart';

class PostDetailPage extends StatefulWidget {
  final String postId;

  const PostDetailPage({Key? key, required this.postId}) : super(key: key);

  @override
  _PostDetailPageState createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final FirestoreDatabase database = FirestoreDatabase();
  final TextEditingController replyController = TextEditingController();
  final FocusNode replyFocusNode = FocusNode();
  bool _isSending = false;

  @override
  void dispose() {
    replyController.dispose();
    replyFocusNode.dispose();
    super.dispose();
  }

  // Simple date formatter without intl package
  String formatDate(DateTime? dateTime) {
    if (dateTime == null) return '';

    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final day = dateTime.day;
    final month = months[dateTime.month - 1];
    final year = dateTime.year;
    final hour =
        dateTime.hour > 12
            ? dateTime.hour - 12
            : dateTime.hour == 0
            ? 12
            : dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';

    return '$month $day, $year · $hour:$minute $period';
  }

  String formatCommentDate(DateTime? dateTime) {
    if (dateTime == null) return '';

    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final day = dateTime.day;
    final month = months[dateTime.month - 1];
    final hour =
        dateTime.hour > 12
            ? dateTime.hour - 12
            : dateTime.hour == 0
            ? 12
            : dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';

    return '$month $day · $hour:$minute $period';
  }

  Future<void> _sendReply() async {
    String replyText = replyController.text.trim();
    if (replyText.isEmpty) return;

    setState(() => _isSending = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception("Please sign in to comment");
      }

      // Verify user is authenticated with recent sign in
      if (currentUser.metadata.lastSignInTime == null ||
          DateTime.now().difference(currentUser.metadata.lastSignInTime!) >
              const Duration(hours: 1)) {
        await currentUser.reload();
      }

      // Retrieve the user document
      DocumentSnapshot<Map<String, dynamic>> userDoc =
          await FirebaseFirestore.instance
              .collection("Users")
              .doc(currentUser.email)
              .get();

      String accountUsername = userDoc.data()?['username'] ?? "Anonymous";
      final uid = currentUser.uid;

      final replyData = {
        'replyMessage': replyText,
        'replyBy': accountUsername,
        'timestamp': Timestamp.now(),
        'uid': uid, // Add user ID for security rules
      };

      await database.addReply(widget.postId, replyData);
      replyController.clear();
      FocusScope.of(context).unfocus();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to post comment: ${e.toString().replaceAll(RegExp(r'\[.*\]'), '')}',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'DISMISS',
            textColor: Theme.of(context).colorScheme.onError,
            onPressed: () {},
          ),
        ),
      );
      debugPrint("Error sending reply: $e");
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Text("Post Details", style: theme.textTheme.titleLarge),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        iconTheme: theme.iconTheme,
      ),
      body: Column(
        children: [
          // Post details section
          StreamBuilder<DocumentSnapshot>(
            stream: database.posts.doc(widget.postId).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                );
              }

              if (!snapshot.data!.exists) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      "This post doesn't exist anymore",
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                );
              }

              final data = snapshot.data!.data() as Map<String, dynamic>;

              // Parse timestamp - handle both Timestamp and String formats
              DateTime? createdAt;
              try {
                if (data['createdAt'] is Timestamp) {
                  createdAt = (data['createdAt'] as Timestamp).toDate();
                } else if (data['createdAt'] is String) {
                  createdAt = DateTime.parse(data['createdAt']);
                }
              } catch (e) {
                createdAt = null;
              }

              final formattedDate = formatDate(createdAt);

              return Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: theme.shadowColor.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Author row
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: theme.colorScheme.primary,
                          radius: 20,
                          child: Text(
                            data['authorUsername']?.toString().isNotEmpty ==
                                    true
                                ? data['authorUsername'][0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['authorUsername'] ?? 'Anonymous',
                              style: theme.textTheme.titleMedium,
                            ),
                            Text(
                              formattedDate,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Content
                    Text(
                      data['content'] ?? "",
                      style: theme.textTheme.bodyLarge,
                    ),

                    const SizedBox(height: 16),

                    // Likes info
                    Row(
                      children: [
                        Icon(
                          Icons.favorite,
                          color: theme.colorScheme.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "${data['likes'] ?? 0} likes",
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),

          // Comments header
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                Text("Comments", style: theme.textTheme.titleMedium),
                const SizedBox(width: 8),
                Icon(
                  Icons.chat_bubble_outline,
                  size: 18,
                  color: theme.iconTheme.color,
                ),
              ],
            ),
          ),

          Divider(color: theme.dividerColor),

          // Comments list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  database.posts
                      .doc(widget.postId)
                      .collection("comments")
                      .orderBy("timestamp", descending: false)
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                    ),
                  );
                }

                final repliesDocs = snapshot.data!.docs;

                if (repliesDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 48,
                          color: theme.colorScheme.tertiary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No comments yet",
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Be the first to comment!",
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: repliesDocs.length,
                  separatorBuilder:
                      (context, index) => Divider(
                        color: theme.dividerColor.withOpacity(0.5),
                        height: 1,
                      ),
                  itemBuilder: (context, index) {
                    final replyData =
                        repliesDocs[index].data() as Map<String, dynamic>;

                    // Format timestamp
                    String timeText = "";
                    if (replyData["timestamp"] != null) {
                      final timestamp =
                          (replyData["timestamp"] as Timestamp).toDate();
                      timeText = formatCommentDate(timestamp);
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor: theme.colorScheme.secondary,
                            radius: 16,
                            child: Text(
                              replyData["replyBy"]?.toString().isNotEmpty ==
                                      true
                                  ? replyData["replyBy"][0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: theme.colorScheme.onSecondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      replyData["replyBy"] ?? "Anonymous",
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      timeText,
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  replyData["replyMessage"] ?? "",
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Comment input field
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.background,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: TextField(
                        controller: replyController,
                        focusNode: replyFocusNode,
                        maxLines: 4,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        style: theme.textTheme.bodyMedium,
                        decoration: InputDecoration(
                          hintText: "Add a comment...",
                          hintStyle: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.tertiary,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: _isSending ? null : _sendReply,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        child:
                            _isSending
                                ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: theme.colorScheme.onPrimary,
                                    strokeWidth: 2,
                                  ),
                                )
                                : Icon(
                                  Icons.send,
                                  color: theme.colorScheme.onPrimary,
                                ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
