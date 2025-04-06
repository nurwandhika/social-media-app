import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:minimalsocialmedia/components/my_drawer.dart';
import 'package:minimalsocialmedia/components/my_textfield.dart';
import 'package:minimalsocialmedia/database/firestore.dart';
import 'package:minimalsocialmedia/models/post_model.dart';
import 'package:minimalsocialmedia/pages/post_detail_page.dart';
import 'package:uuid/uuid.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirestoreDatabase database = FirestoreDatabase();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController captionController = TextEditingController();
  List<String> imageUrls = [];

  void _showCreatePostDialog(BuildContext context) {
    String selectedTopic = "General";
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
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
                  DropdownButtonFormField<String>(
                    value: selectedTopic,
                    items: <String>["General", "Anime", "Comic", "Game"]
                        .map((String topic) {
                      return DropdownMenuItem<String>(
                        value: topic,
                        child: Text(topic),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedTopic = newValue ?? "General";
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: "Select Topic",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      if (imageUrls.length < 3) {
                        imageUrls.add(
                            "https://example.com/image${imageUrls.length}.jpg");
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
              TextButton(
                onPressed: () async {
                  final currentUser = FirebaseAuth.instance.currentUser;
                  if (currentUser == null) return;
                  DocumentSnapshot<Map<String, dynamic>> userDoc =
                  await FirebaseFirestore.instance
                      .collection("Users")
                      .doc(currentUser.email)
                      .get();
                  String accountUsername =
                  userDoc.data()?['username']
                      ?.toString()
                      .isNotEmpty == true
                      ? userDoc.data()!['username']
                      : "Anonymous";
                  String postId = const Uuid().v4();
                  final post = PostModel(
                    postId: postId,
                    title: titleController.text.substring(0, titleController.text.length.clamp(0, 50)),
                    caption: captionController.text.substring(0, captionController.text.length.clamp(0, 280)),
                    imageUrls: imageUrls,
                    authorUsername: accountUsername,
                    authorEmail: currentUser!.email!, // pass current user's email
                    group: selectedTopic!, // use chosen topic as group field
                    topic: selectedTopic!,
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
        });
      },
    );
  }

  void _handleLike(String postId) {
    database.toggleLike(postId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme
          .of(context)
          .colorScheme
          .surface,
      appBar: AppBar(
        title: const Text("Timeline"),
        backgroundColor: Colors.transparent,
        foregroundColor: Theme
            .of(context)
            .colorScheme
            .inversePrimary,
        elevation: 0,
      ),
      drawer: const MyDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreatePostDialog(context),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
          stream: database.getPostsStream(),
          builder: (context, snapshot) {
            // Show a full-screen loading indicator when waiting for posts.
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
                  ));
            }
            return ListView.builder(
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
                String currentUid = database.user?.uid ?? '';
                bool isLiked = currentUid.isNotEmpty
                    ? likedBy.contains(currentUid)
                    : false;
                String shortCaption =
                caption.length > 50
                    ? "${caption.substring(0, 50)}..."
                    : caption;
                return Card(
                  margin: const EdgeInsets.symmetric(
                      vertical: 8, horizontal: 25),
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                PostDetailPage(postId: doc.id)),
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
                          icon: Icon(
                            isLiked
                                ? Icons.favorite
                                : Icons.favorite_border,
                          ),
                          onPressed: () => _handleLike(doc.id),
                        ),
                        IconButton(
                          icon: const Icon(Icons.reply),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    PostDetailPage(postId: doc.id),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }),
    );
  }
}