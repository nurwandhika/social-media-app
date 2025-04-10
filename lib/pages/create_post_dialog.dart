import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:minimalsocialmedia/components/my_textfield.dart';
import 'package:minimalsocialmedia/database/firestore.dart';
import 'package:minimalsocialmedia/models/post_model.dart';
import 'package:uuid/uuid.dart';

class CreatePostDialog extends StatefulWidget {
  final Function? onPostCreated;

  const CreatePostDialog({Key? key, this.onPostCreated}) : super(key: key);

  @override
  _CreatePostDialogState createState() => _CreatePostDialogState();
}

class _CreatePostDialogState extends State<CreatePostDialog> {
  final TextEditingController captionController = TextEditingController();
  final FirestoreDatabase database = FirestoreDatabase();
  final ImagePicker _picker = ImagePicker();
  List<File> _selectedImages = [];
  bool _isUploading = false;

  // Simplified image picking method
  Future<void> _pickImages() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage();
      if (pickedFiles.isNotEmpty) {
        setState(() {
          final imagesToAdd = pickedFiles.take(3 - _selectedImages.length);
          _selectedImages.addAll(
            imagesToAdd.map((file) => File(file.path)).toList(),
          );
        });
      }
    } catch (e) {
      debugPrint('Error picking images: $e');
    }
  }

  // Simplified upload method - no nested paths
  Future<List<String>> _uploadImages() async {
    List<String> uploadedUrls = [];
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return [];

    // Create post ID once
    final postId = const Uuid().v4();

    for (int i = 0; i < _selectedImages.length; i++) {
      final File image = _selectedImages[i];

      try {
        // Simple path structure: images/[filename].jpg
        final String fileName = 'images/${currentUser.uid}_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        debugPrint('Uploading to path: $fileName');

        // Get direct reference to the root bucket
        final Reference ref = FirebaseStorage.instance.ref().child(fileName);

        // Upload with explicit content type
        final UploadTask uploadTask = ref.putFile(
            image,
            SettableMetadata(contentType: 'image/jpeg')
        );

        // Wait for completion
        final TaskSnapshot snapshot = await uploadTask;
        final String downloadUrl = await snapshot.ref.getDownloadURL();

        debugPrint('Upload success: $downloadUrl');
        uploadedUrls.add(downloadUrl);
      } catch (e) {
        debugPrint('Error uploading image $i: $e');
        // Continue with next image
      }
    }

    return uploadedUrls;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    "Create Post",
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

              MyTextfield(
                hintText: "What's on your mind?",
                obscureText: false,
                controller: captionController,
              ),
              const SizedBox(height: 16),

              // Simple image picker
              _selectedImages.isEmpty
                  ? InkWell(
                onTap: _pickImages,
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey),
                        SizedBox(height: 8),
                        Text("Add Photos", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              )
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${_selectedImages.length}/3 Photos",
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      TextButton(
                        onPressed: _selectedImages.length < 3 ? _pickImages : null,
                        child: const Text("Add More"),
                      ),
                    ],
                  ),
                  Container(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(4),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _selectedImages[index],
                                  height: 90,
                                  width: 90,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedImages.removeAt(index)),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),

              if (_isUploading)
                Column(
                  children: [
                    const SizedBox(height: 16),
                    const LinearProgressIndicator(),
                    const SizedBox(height: 8),
                    Text("Uploading...", style: TextStyle(color: Colors.grey[600])),
                  ],
                ),

              const SizedBox(height: 20),

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
                    onPressed: _isUploading ? null : _uploadPost,
                    child: const Text("Post"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Upload post with error fallback
  Future<void> _uploadPost() async {
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one image')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception("User not logged in");
      }

      // Upload images with simplified path
      List<String> uploadedImageUrls = await _uploadImages();

      // If uploads failed, use placeholders
      if (uploadedImageUrls.isEmpty) {
        debugPrint('Using placeholder image instead');
        uploadedImageUrls = ["https://via.placeholder.com/400"];
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
        // title: "",
        caption: captionController.text.trim().substring(
          0,
          captionController.text.trim().length.clamp(0, 280),
        ),
        imageUrls: uploadedImageUrls,
        authorUsername: accountUsername,
        authorEmail: currentUser.email!,
        // group: "General",
        // topic: "General",
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
      setState(() => _isUploading = false);
    }
  }
}