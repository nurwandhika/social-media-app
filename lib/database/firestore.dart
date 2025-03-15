import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:minimalsocialmedia/models/post_model.dart';

class FirestoreDatabase {
  // current logged in user
  User? user = FirebaseAuth.instance.currentUser;

  // get collection of posts from firebase
  final CollectionReference posts = FirebaseFirestore.instance.collection("Posts");

  // Add a post with the new model
  Future<void> addPost(PostModel post) async {
    await posts.doc(post.postId).set(post.toMap());
  }

  // dart
  Future<void> toggleLike(String postId) async {
    final uid = user!.uid;
    DocumentReference postRef = posts.doc(postId);
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(postRef);
      if (!snapshot.exists) return;
      final data = snapshot.data() as Map<String, dynamic>;

      // Helper to safely get a value with a default.
      T getValue<T>(String key, T defaultValue) {
        if (data.toString().contains(key) && data[key] != null) {
          return data[key] as T;
        }
        return defaultValue;
      }

      List<dynamic> likedBy = getValue<List<dynamic>>('likedBy', []);
      int currentLikes = getValue<int>('likes', 0);

      if (likedBy.contains(uid)) {
        transaction.update(postRef, {
          'likedBy': FieldValue.arrayRemove([uid]),
          'likes': currentLikes - 1,
        });
      } else {
        transaction.update(postRef, {
          'likedBy': FieldValue.arrayUnion([uid]),
          'likes': currentLikes + 1,
        });
      }
    });
  }
  
  // Add a reply to a post in a sub-collection 'comments'
  Future<void> addReply(String postId, Map<String, dynamic> replyData) async {
    await posts.doc(postId).collection('comments').add(replyData);
  }

  // Read posts sorted by creation date
  Stream<QuerySnapshot> getPostsStream() {
    return posts.orderBy('createdAt', descending: true).snapshots();
  }
}