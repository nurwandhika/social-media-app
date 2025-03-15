import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:minimalsocialmedia/components/my_drawer.dart';
import 'package:minimalsocialmedia/components/my_post_button.dart';
import 'package:minimalsocialmedia/components/my_textfield.dart';
import 'package:minimalsocialmedia/database/firestore.dart';
import 'package:minimalsocialmedia/models/post_model.dart';
import 'package:uuid/uuid.dart';
import '../components/my_list_tile.dart';
import 'package:minimalsocialmedia/pages/post_detail_page.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final FirestoreDatabase database = FirestoreDatabase();

  final TextEditingController titleController = TextEditingController();
  final TextEditingController captionController = TextEditingController();
  List<String> imageUrls = [];

  void _showCreatePostDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Create Post"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                MyTextfield(
                  hintText: "Title (max 50 chars)",
                  obscureText: false,
                  controller: titleController,
                ),
                const SizedBox(height: 10),
                MyTextfield(
                  hintText: "Caption (max 280 chars)",
                  obscureText: false,
                  controller: captionController,
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    if (imageUrls.length < 3) {
                      imageUrls.add("https://example.com/image${imageUrls.length}.jpg");
                    }
                  },
                  child: const Text("Add Image"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                titleController.clear();
                captionController.clear();
                imageUrls = [];
              },
              child: const Text("Cancel"),
            ),
            // dart
            // dart
            TextButton(
              onPressed: () async {
                final currentUser = FirebaseAuth.instance.currentUser;
                if (currentUser == null) return; // user not logged in

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

                String postId = const Uuid().v4();
                final post = PostModel(
                  postId: postId,
                  title: titleController.text.substring(0, titleController.text.length.clamp(0, 50)),
                  caption: captionController.text.substring(0, captionController.text.length.clamp(0, 280)),
                  imageUrls: imageUrls,
                  authorUsername: accountUsername,
                  group: "DefaultGroup",
                  createdAt: DateTime.now(),
                );
                database.addPost(post);
                Navigator.pop(context);
                titleController.clear();
                captionController.clear();
                imageUrls = [];
              },
              child: const Text("Post"),
            ),
          ],
        );
      },
    );
  }

  void _handleLike(String postId) {
    database.toggleLike(postId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text("Timeline"),
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
      ),
      drawer: MyDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreatePostDialog(context),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          StreamBuilder(
            stream: database.getPostsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
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
              return Expanded(
                child: ListView.builder(
                  itemCount: postsDocs.length,
                  itemBuilder: (context, index) {
                    final doc = postsDocs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    String title = data["title"] ?? '';
                    String caption = data["caption"] ?? '';
                    String authorUsername = data["authorUsername"] ?? '';
                    String group = data["group"] ?? '';
                    int likes = data["likes"] ?? 0;
                    List<dynamic> likedBy = data.containsKey("likedBy")
                        ? data["likedBy"] as List<dynamic>
                        : [];
                    bool isLiked = likedBy.contains(database.user!.uid);
                    String shortCaption = caption.length > 50
                        ? "${caption.substring(0, 50)}..."
                        : caption;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 25),
                      child: ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PostDetailPage(postId: doc.id),
                            ),
                          );
                        },
                        title: Text(title),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(shortCaption),
                            Text("by $authorUsername in $group"),
                            Text("Likes: $likes"),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border),
                              onPressed: () => _handleLike(doc.id),
                            ),
                            IconButton(
                              icon: const Icon(Icons.reply),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PostDetailPage(postId: doc.id),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}