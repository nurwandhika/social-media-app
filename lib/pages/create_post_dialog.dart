// dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:minimalsocialmedia/components/my_textfield.dart';
import 'package:minimalsocialmedia/database/firestore.dart';
import 'package:minimalsocialmedia/models/post_model.dart';
import 'package:uuid/uuid.dart';

class CreatePostDialog extends StatefulWidget {
  const CreatePostDialog({Key? key}) : super(key: key);

  @override
  _CreatePostDialogState createState() => _CreatePostDialogState();
}

class _CreatePostDialogState extends State<CreatePostDialog> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController captionController = TextEditingController();
  List<String> imageUrls = [];
  // Hardcoded topics list
  final List<String> userTopics = ['General', 'Anime', 'Comic', 'Game'];
  String? selectedTopic = 'General';
  final FirestoreDatabase database = FirestoreDatabase();

  @override
  Widget build(BuildContext context) {
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
            DropdownButton<String>(
              value: selectedTopic,
              items: userTopics.map((topic) {
                return DropdownMenuItem<String>(
                  value: topic,
                  child: Text(topic),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedTopic = value;
                });
              },
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                if (imageUrls.length < 3) {
                  imageUrls.add("https://example.com/image${imageUrls.length}.jpg");
                  setState(() {});
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
          },
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () async {
            final currentUser = FirebaseAuth.instance.currentUser;
            if (currentUser == null) return;
            DocumentSnapshot<Map<String, dynamic>> userDoc =
            await FirebaseFirestore.instance.collection("Users").doc(currentUser.email).get();
            String accountUsername = userDoc.data()?['username']?.toString().isNotEmpty == true
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
          },
          child: const Text("Post"),
        ),
      ],
    );
  }
}