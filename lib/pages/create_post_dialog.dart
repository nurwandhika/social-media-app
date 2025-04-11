import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:minimalsocialmedia/database/firestore.dart';
import 'package:minimalsocialmedia/models/post_model.dart';
import 'package:uuid/uuid.dart';

class CreatePostDialog extends StatefulWidget {
  final Function()? onPostCreated;

  const CreatePostDialog({Key? key, this.onPostCreated}) : super(key: key);

  @override
  _CreatePostDialogState createState() => _CreatePostDialogState();
}

class _CreatePostDialogState extends State<CreatePostDialog> {
  final TextEditingController contentController = TextEditingController();
  bool _isPosting = false;
  final int _characterLimit = 280;
  final FirestoreDatabase database = FirestoreDatabase();

  Future<void> _createPost() async {
    if (contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter some text')),
      );
      return;
    }

    setState(() => _isPosting = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception("User not logged in");
      }

      // Get user data
      DocumentSnapshot<Map<String, dynamic>> userDoc =
      await FirebaseFirestore.instance
          .collection("Users")
          .doc(currentUser.email)
          .get();

      String accountUsername =
          userDoc.data()?['username'] ?? "Anonymous";

      // Create post
      String postId = const Uuid().v4();
      final post = PostModel(
        postId: postId,
        content: contentController.text.trim(),
        authorUsername: accountUsername,
        authorEmail: currentUser.email!,
        createdAt: DateTime.now(),
      );

      // Add to Firestore
      await database.addPost(post);

      // Notify parent
      if (widget.onPostCreated != null) {
        widget.onPostCreated!();
      }

      Navigator.pop(context);
    } catch (e) {
      debugPrint('Error creating post: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text(
                  "New Post",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),

            TextField(
              controller: contentController,
              maxLength: _characterLimit,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: "What's happening?",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                counterText: "${contentController.text.length}/$_characterLimit",
              ),
            ),

            const SizedBox(height: 20),

            if (_isPosting)
              const LinearProgressIndicator(),

            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _isPosting ? null : _createPost,
                  child: const Text("Post"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

