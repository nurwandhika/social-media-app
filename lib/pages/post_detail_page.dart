// dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:minimalsocialmedia/database/firestore.dart';

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

  @override
  void initState() {
    super.initState();
    // Auto-focus on the reply text field after build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(replyFocusNode);
    });
  }

  @override
  void dispose() {
    replyController.dispose();
    replyFocusNode.dispose();
    super.dispose();
  }

  // dart
  Future<void> _sendReply() async {
    String replyText = replyController.text.trim();
    if (replyText.isEmpty) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Retrieve the user document from Firestore using the email as ID.
    DocumentSnapshot<Map<String, dynamic>> userDoc =
    await FirebaseFirestore.instance
        .collection("Users")
        .doc(currentUser.email)
        .get();

    // Use the username from the user document; default to "Anonymous" if not found.
    String accountUsername =
    userDoc.data()?['username']?.toString().isNotEmpty == true
        ? userDoc.data()!['username']
        : "Anonymous";

    final replyData = {
      'replyMessage': replyText,
      'replyBy': accountUsername,
      'timestamp': Timestamp.now(),
    };
    await database.addReply(widget.postId, replyData);
    replyController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Post Details")),
      body: Column(
        children: [
          // Post details section.
          StreamBuilder<DocumentSnapshot>(
            stream: database.posts.doc(widget.postId).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final data = snapshot.data!.data() as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data["title"] ?? "",
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(data["caption"] ?? ""),
                    const SizedBox(height: 8),
                    Text("Likes: ${data["likes"] ?? 0}"),
                  ],
                ),
              );
            },
          ),
          const Divider(),
          // Replies list.
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: database.posts
                  .doc(widget.postId)
                  .collection("comments")
                  .orderBy("timestamp", descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final repliesDocs = snapshot.data!.docs;
                if (repliesDocs.isEmpty) {
                  return const Center(child: Text("No replies yet"));
                }
                return ListView.builder(
                  itemCount: repliesDocs.length,
                  itemBuilder: (context, index) {
                    final replyData =
                    repliesDocs[index].data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(replyData["replyBy"] ?? ""),
                      subtitle: Text(replyData["replyMessage"] ?? ""),
                    );
                  },
                );
              },
            ),
          ),
          // Reply text field with send button.
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: replyController,
                    focusNode: replyFocusNode,
                    decoration: const InputDecoration(
                      hintText: "Write your reply...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendReply,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}